//
//  LocationService.swift
//  STASH
//
//  Phase 3A Spec 2: Location Framework Integration
//  Wrapper around CoreLocation for getting current location
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Location Service Protocol

/// Protocol for location services.
///
/// Enables mocking in tests.
protocol LocationServiceProtocol: FrameworkServiceProtocol {
    /// Gets the current location
    func getCurrentLocation() async -> Location?

    /// Reverse geocodes coordinates to a location name
    func getLocationName(latitude: Double, longitude: Double) async -> String?
}

// MARK: - Location Service

/// Service for accessing device location via CoreLocation.
///
/// Implements fail-soft pattern: returns nil on errors or timeouts
/// instead of throwing. Used by ContextService to gather location context.
///
/// ## Permissions
///
/// Requires "When In Use" location permission. Check `permissionStatus`
/// and call `requestPermission()` before accessing location data.
///
/// ## Performance
///
/// Location operations have a 100ms timeout to meet context gathering
/// performance targets. If location cannot be determined quickly,
/// nil is returned.
actor LocationService: LocationServiceProtocol {
    // MARK: - Framework Service Protocol

    nonisolated var frameworkType: FrameworkType { .coreLocation }

    nonisolated var isAvailable: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    var permissionStatus: PermissionLevel {
        mapAuthorizationStatus(locationManager.authorizationStatus)
    }

    // MARK: - Dependencies

    private let configuration: ServiceConfiguration

    // MARK: - State

    private let locationManager: CLLocationManager
    private var delegate: (any CLLocationManagerDelegate)?

    // MARK: - Initialization

    init(configuration: ServiceConfiguration = .shared) {
        self.configuration = configuration
        self.locationManager = CLLocationManager()
    }

    // MARK: - Permissions

    func requestPermission() async -> PermissionLevel {
        guard isAvailable else { return .restricted }

        let currentStatus = permissionStatus
        guard currentStatus == .notDetermined else { return currentStatus }

        return await withCheckedContinuation { continuation in
            let delegate = PermissionDelegate { status in
                continuation.resume(returning: self.mapAuthorizationStatus(status))
            }
            self.delegate = delegate
            self.locationManager.delegate = delegate
            self.locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Location Operations

    /// Gets the current location.
    ///
    /// Returns nil if:
    /// - Location services are disabled
    /// - Permission is not authorized
    /// - Operation times out (100ms)
    /// - Any error occurs
    func getCurrentLocation() async -> Location? {
        guard isAvailable, permissionStatus.allowsAccess else {
            return nil
        }

        let timeout = configuration.timeouts.frameworkOperation

        return await withTimeout(timeout) {
            await self.fetchCurrentLocation()
        }
    }

    private func fetchCurrentLocation() async -> Location? {
        NSLog("📍 LocationService - Starting location fetch")
        let clLocation = await withCheckedContinuation { continuation in
            let delegate = LocationUpdateDelegate { location in
                continuation.resume(returning: location)
            }

            self.delegate = delegate
            self.locationManager.delegate = delegate
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.requestLocation()
        }

        guard let clLocation = clLocation else {
            NSLog("📍 LocationService - No location returned from CLLocationManager")
            return nil
        }

        NSLog("📍 LocationService - Got coordinates: lat=%.4f, lon=%.4f", clLocation.coordinate.latitude, clLocation.coordinate.longitude)

        // Get location name via reverse geocoding
        let name = await getLocationName(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude
        )

        NSLog("📍 LocationService - Location name: %@", name ?? "nil")

        return Location(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude,
            name: name,
            geofenceId: nil
        )
    }

    /// Reverse geocodes coordinates to a location name.
    ///
    /// Returns nil if geocoding fails or times out.
    func getLocationName(latitude: Double, longitude: Double) async -> String? {
        let timeout = configuration.timeouts.geocoding

        return await withTimeout(timeout) { [self] in
            await self.performGeocode(latitude: latitude, longitude: longitude)
        }
    }

    private func performGeocode(latitude: Double, longitude: Double) async -> String? {
        NSLog("📍 LocationService - Starting geocode for lat=%.4f, lon=%.4f", latitude, longitude)

        // Note: CLGeocoder is deprecated in iOS 26 but remains functional and stable.
        // The recommended MapKit alternatives (MKReverseGeocodingRequest, MKLocalSearch, MKAddress)
        // have incomplete APIs - MKMapItem doesn't provide CNPostalAddress (structured data).
        // See: https://developer.apple.com/forums/thread/795687
        // Will migrate when MapKit reverse geocoding API provides structured address data.
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            NSLog("📍 LocationService - Executing CLGeocoder reverseGeocodeLocation")
            #if compiler(>=6.0)
            #warning("TODO: Migrate to MKReverseGeocodingRequest when CNPostalAddress support is added")
            #endif
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            NSLog("📍 LocationService - Got %d placemarks", placemarks.count)

            if let placemark = placemarks.first {
                // Try different name components in order of specificity
                let name = placemark.name
                    ?? placemark.locality
                    ?? placemark.subLocality
                    ?? placemark.thoroughfare
                    ?? placemark.administrativeArea
                NSLog("📍 LocationService - Geocode result: %@", name ?? "nil")
                return name
            }
            NSLog("📍 LocationService - No placemarks returned")
            return nil
        } catch {
            NSLog("📍 LocationService - Geocode error: %@", error.localizedDescription)
            return nil
        }
    }

    // MARK: - Helpers

    private func mapAuthorizationStatus(_ status: CLAuthorizationStatus) -> PermissionLevel {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }

    private func withTimeout<T: Sendable>(_ timeout: TimeInterval, operation: @Sendable @escaping () async -> T?) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }

            // Return first non-nil result, or nil if timeout wins
            for await result in group {
                if result != nil {
                    group.cancelAll()
                    return result
                }
            }

            return nil
        }
    }

    // MARK: - Service Protocol

    func initialize() async throws {
        // No initialization needed
    }

    func shutdown() async {
        locationManager.stopUpdatingLocation()
        delegate = nil
    }
}

// MARK: - Location Delegates

/// Delegate for handling permission authorization changes.
private final class PermissionDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let completion: (CLAuthorizationStatus) -> Void
    private var hasCompleted = false

    init(completion: @escaping (CLAuthorizationStatus) -> Void) {
        self.completion = completion
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !hasCompleted else { return }
        let status = manager.authorizationStatus
        if status != .notDetermined {
            hasCompleted = true
            completion(status)
        }
    }
}

/// Delegate for handling location updates.
private final class LocationUpdateDelegate: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let completion: (CLLocation?) -> Void
    private var hasCompleted = false

    init(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasCompleted else { return }
        hasCompleted = true
        manager.stopUpdatingLocation()
        completion(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard !hasCompleted else { return }
        hasCompleted = true
        manager.stopUpdatingLocation()
        completion(nil)
    }
}

// MARK: - Mock Location Service

/// Mock location service for testing and previews.
actor MockLocationService: LocationServiceProtocol {
    nonisolated var frameworkType: FrameworkType { .coreLocation }
    nonisolated var isAvailable: Bool { true }
    var permissionStatus: PermissionLevel

    var mockLocation: Location?
    var mockLocationName: String?

    init(
        permissionStatus: PermissionLevel = .authorized,
        location: Location? = nil,
        locationName: String? = nil
    ) {
        self.permissionStatus = permissionStatus
        self.mockLocation = location
        self.mockLocationName = locationName
    }

    func requestPermission() async -> PermissionLevel {
        permissionStatus = .authorized
        return .authorized
    }

    func getCurrentLocation() async -> Location? {
        mockLocation
    }

    func getLocationName(latitude: Double, longitude: Double) async -> String? {
        mockLocationName
    }
}
