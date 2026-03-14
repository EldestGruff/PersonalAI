//
//  LocationService.swift
//  STASH
//
//  Phase 3A Spec 2: Location Framework Integration
//  Wrapper around CoreLocation for getting current location
//

import Foundation
import CoreLocation
import OSLog
@preconcurrency import MapKit

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
        AppLogger.location.debug("LocationService - Starting location fetch")
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
            AppLogger.location.debug("LocationService - No location returned from CLLocationManager")
            return nil
        }

        AppLogger.location.debug("LocationService - Got coordinates: lat=\(clLocation.coordinate.latitude, format: .fixed(precision: 4)), lon=\(clLocation.coordinate.longitude, format: .fixed(precision: 4))")

        // Get location name via reverse geocoding
        let name = await getLocationName(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude
        )

        AppLogger.location.debug("LocationService - Location name: \(name ?? "nil")")

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
        AppLogger.location.debug("LocationService - Starting geocode for lat=\(latitude, format: .fixed(precision: 4)), lon=\(longitude, format: .fixed(precision: 4))")

        let location = CLLocation(latitude: latitude, longitude: longitude)

        // Use MapKit's reverse geocoding (iOS 26+)
        if #available(iOS 26.0, *) {
            AppLogger.location.debug("LocationService - Using MKReverseGeocodingRequest")

            guard let request = MKReverseGeocodingRequest(location: location) else {
                AppLogger.location.debug("LocationService - Failed to create MKReverseGeocodingRequest")
                return nil
            }

            let mapItems = try? await request.mapItems

            if let mapItem = mapItems?.first {
                // Use iOS 26 address API (shortAddress for brief location name, or fullAddress if that's nil)
                let name = mapItem.name
                    ?? mapItem.address?.shortAddress
                    ?? mapItem.address?.fullAddress
                AppLogger.location.debug("LocationService - MapKit result: \(name ?? "nil")")
                return name
            }
            AppLogger.location.debug("LocationService - No MapKit results")
            return nil
        } else {
            // Fallback to CLGeocoder for older iOS versions
            let geocoder = CLGeocoder()

            do {
                AppLogger.location.debug("LocationService - Using CLGeocoder (iOS <26)")
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                AppLogger.location.debug("LocationService - Got \(placemarks.count) placemarks")

                if let placemark = placemarks.first {
                    let name = placemark.name
                        ?? placemark.locality
                        ?? placemark.subLocality
                        ?? placemark.thoroughfare
                        ?? placemark.administrativeArea
                    AppLogger.location.debug("LocationService - Geocode result: \(name ?? "nil")")
                    return name
                }
                AppLogger.location.debug("LocationService - No placemarks returned")
                return nil
            } catch {
                AppLogger.location.error("LocationService - Geocode error: \(error.localizedDescription)")
                return nil
            }
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
