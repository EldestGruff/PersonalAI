//
//  ContactsService.swift
//  STASH
//
//  Phase 3A Spec 2: Contacts Framework Integration
//  Wrapper around Contacts framework for entity linking
//

import Foundation
@preconcurrency import Contacts

// MARK: - Contacts Service Protocol

/// Protocol for contacts services.
///
/// Enables mocking in tests.
protocol ContactsServiceProtocol: FrameworkServiceProtocol {
    /// Finds a contact by name
    func findContact(byName name: String) async -> CNContact?

    /// Gets all contact names for entity matching
    func getAllContactNames() async -> [String]
}

// MARK: - Contacts Service

/// Service for accessing contacts via the Contacts framework.
///
/// Used for entity linking - when a thought mentions a person's name,
/// we can link it to their contact record. This enables features like
/// showing contact info or sending messages.
///
/// ## Privacy
///
/// Only fetches basic name information (given name, family name).
/// Does not access phone numbers, emails, or other sensitive data
/// unless specifically requested.
///
/// ## Performance
///
/// Contact queries can be slow for large address books. All operations
/// have timeouts and the service caches contact names for faster matching.
actor ContactsService: ContactsServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .contacts }

    nonisolated var isAvailable: Bool { true }

    var permissionStatus: PermissionLevel {
        mapAuthorizationStatus(CNContactStore.authorizationStatus(for: .contacts))
    }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - State

    private let contactStore: CNContactStore
    private var cachedNames: [String]?
    private var cacheTimestamp: Date?

    // MARK: - Constants

    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
        self.contactStore = CNContactStore()
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        let currentStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard currentStatus == .notDetermined else {
            return mapAuthorizationStatus(currentStatus)
        }

        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    // MARK: - Find Contact

    /// Finds a contact by name.
    ///
    /// Searches for contacts matching the given name string.
    /// Returns the first match, or nil if not found.
    func findContact(byName name: String) async -> CNContact? {
        guard permissionStatus.allowsAccess else { return nil }

        // Note: CNContact is not Sendable, so we call directly without timeout wrapper
        return searchContact(name: name)
    }

    private func searchContact(name: String) -> CNContact? {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        let predicate = CNContact.predicateForContacts(matchingName: name)

        do {
            let contacts = try contactStore.unifiedContacts(
                matching: predicate,
                keysToFetch: keysToFetch
            )
            return contacts.first
        } catch {
            return nil
        }
    }

    // MARK: - Get All Contact Names

    /// Gets all contact names for entity matching.
    ///
    /// Returns a cached list of contact names (first and last) for
    /// fast fuzzy matching against thought content. Cache expires
    /// after 5 minutes.
    func getAllContactNames() async -> [String] {
        guard permissionStatus.allowsAccess else { return [] }

        // Check cache
        if let cached = cachedNames,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheExpirationInterval {
            return cached
        }

        let timeout = configuration.timeouts.frameworkOperation * 10 // Allow more time for full fetch

        let result = await withTimeout(timeout, default: [String]()) { [self] in
            await self.fetchAllContactNames()
        }

        return result ?? []
    }

    private func fetchAllContactNames() async -> [String] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        var names: Set<String> = []
        let limit = configuration.limits.contactCacheLimit

        do {
            try contactStore.enumerateContacts(with: request) { contact, stop in
                if !contact.givenName.isEmpty {
                    names.insert(contact.givenName)
                }
                if !contact.familyName.isEmpty {
                    names.insert(contact.familyName)
                }
                let fullName = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if !fullName.isEmpty {
                    names.insert(fullName)
                }

                // Stop if we've hit the limit
                if names.count >= limit {
                    stop.pointee = true
                }
            }

            let result = Array(names)

            // Update cache
            cachedNames = result
            cacheTimestamp = Date()

            return result
        } catch {
            return []
        }
    }

    // MARK: - Helpers

    private func mapAuthorizationStatus(_ status: CNAuthorizationStatus) -> PermissionLevel {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }

    private func withTimeout<T: Sendable>(_ timeout: TimeInterval, default defaultValue: T? = nil, operation: @Sendable @escaping () async -> T?) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return defaultValue
            }

            for await result in group {
                if result != nil {
                    group.cancelAll()
                    return result
                }
            }

            return defaultValue
        }
    }

    // MARK: - Service Protocol

    func initialize() async throws {
        // Pre-populate cache if we have permission
        if permissionStatus.allowsAccess {
            _ = await getAllContactNames()
        }
    }

    func shutdown() async {
        cachedNames = nil
        cacheTimestamp = nil
    }
}

// MARK: - Mock Contacts Service

/// Mock contacts service for testing and previews.
actor MockContactsService: ContactsServiceProtocol {
    nonisolated var frameworkType: FrameworkType { .contacts }
    nonisolated var isAvailable: Bool { true }
    var permissionStatus: PermissionLevel

    var mockContacts: [String: CNContact]
    var mockContactNames: [String]

    init(
        permissionStatus: PermissionLevel = .authorized,
        contactNames: [String] = ["John Smith", "Jane Doe", "Bob Wilson"]
    ) {
        self.permissionStatus = permissionStatus
        self.mockContactNames = contactNames
        self.mockContacts = [:]
    }

    func requestPermission() async -> PermissionLevel {
        permissionStatus = .authorized
        return .authorized
    }

    func findContact(byName name: String) async -> CNContact? {
        mockContacts[name]
    }

    func getAllContactNames() async -> [String] {
        mockContactNames
    }
}
