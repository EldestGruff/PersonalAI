# iOS 26 MapKit Migration Notes

## CLGeocoder Deprecation Investigation

### Issue
iOS 26 deprecates `CLGeocoder` and `reverseGeocodeLocation()` with warnings:
```
warning: 'CLGeocoder' was deprecated in iOS 26.0: Use MapKit
warning: 'reverseGeocodeLocation' was deprecated in iOS 26.0: Use MKReverseGeocodingRequest
```

### Investigation Results

We attempted to migrate to the recommended MapKit APIs but encountered significant API instability:

#### Attempt 1: MKReverseGeocodingRequest
```swift
let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
let request = MKReverseGeocodingRequest(coordinate: coordinate)
let response = try await request.execute()
```

**Result**: API not available
- `MKReverseGeocodingRequest(coordinate:)` initializer doesn't exist
- `MKReverseGeocodingRequest()` init is unavailable
- `.execute()` method doesn't exist
- `.start()` method doesn't exist
- `.result` property doesn't exist

#### Attempt 2: MKReverseGeocodingRequest with CLLocation
```swift
let location = CLLocation(latitude: latitude, longitude: longitude)
let request = MKReverseGeocodingRequest(location: location)
```

**Result**: Partial API
- `MKReverseGeocodingRequest(location:)` returns optional `MKReverseGeocodingRequest?`
- No documented async method to execute the request
- API appears incomplete in iOS 26.0/26.1

#### Attempt 3: MKLocalSearch
```swift
let searchRequest = MKLocalSearch.Request()
searchRequest.region = MKCoordinateRegion(center: coordinate, ...)
searchRequest.resultTypes = .pointOfInterest
let search = MKLocalSearch(request: searchRequest)
let response = try await search.start()
```

**Result**: Different purpose
- MKLocalSearch works but is designed for POI search, not reverse geocoding
- Returns points of interest near coordinates, not address information
- `MKMapItem.placemark` is deprecated in iOS 26
- `MKMapItem.address` exists but `MKAddress` properties are undocumented:
  - No `.locality`, `.subLocality`, `.thoroughfare`, `.administrativeArea`
  - No `.formattedAddress` property
  - API structure unclear

### Current Status: Using CLGeocoder

**Decision**: Continue using `CLGeocoder` despite deprecation warnings

**Rationale**:
1. **Stability**: CLGeocoder still works correctly in iOS 26
2. **Complete API**: Provides all needed placemark properties
3. **MapKit Incomplete**: Replacement APIs are not fully documented/available
4. **Risk Management**: Better to use deprecated-but-working code than broken migrations
5. **Future Migration**: Can migrate when MapKit APIs stabilize

**Code Location**: `Sources/Services/Framework/LocationService.swift:158-188`

```swift
private func performGeocode(latitude: Double, longitude: Double) async -> String? {
    // Note: CLGeocoder is deprecated in iOS 26 but remains functional and stable.
    // The recommended MapKit alternatives (MKReverseGeocodingRequest, MKLocalSearch, MKAddress)
    // have incomplete or undocumented APIs in iOS 26.0/26.1.
    // Will migrate when MapKit reverse geocoding API stabilizes in future iOS releases.
    let geocoder = CLGeocoder()
    let location = CLLocation(latitude: latitude, longitude: longitude)

    do {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        if let placemark = placemarks.first {
            let name = placemark.name
                ?? placemark.locality
                ?? placemark.subLocality
                ?? placemark.thoroughfare
                ?? placemark.administrativeArea
            return name
        }
        return nil
    } catch {
        return nil
    }
}
```

### Warnings Present
- LocationService.swift:164 - `CLGeocoder` deprecated
- LocationService.swift:169 - `reverseGeocodeLocation` deprecated

These warnings are acknowledged and acceptable given the alternative APIs are not ready.

## When to Revisit

Monitor these conditions for future migration:

1. **Apple Documentation**: Complete docs for MKReverseGeocodingRequest API
2. **WWDC Sessions**: Apple demonstrates reverse geocoding with MapKit
3. **iOS Updates**: Future iOS 26.x or iOS 27 releases with stable APIs
4. **Community Adoption**: Confirmed working implementations in production apps

## Alternative Approaches Considered

### Option A: Suppress Warnings Programmatically
Not possible - Swift doesn't support `@available` or `#pragma` for deprecation warnings within function bodies.

### Option B: Wrapper Function with @available
```swift
@available(iOS, deprecated: 26.0, message: "Using CLGeocoder until MapKit alternative is stable")
private func performGeocode(...) async -> String? { ... }
```
Doesn't suppress warnings from calling deprecated APIs inside the function.

### Option C: Accept Warnings
**CHOSEN**: Keep code functional, document decision, accept build warnings as technical debt.

## Impact Assessment

**Build Impact**:
- 2 deprecation warnings in LocationService.swift (lines 164, 169)
- No errors, app builds and runs successfully
- All functionality works as expected

**Runtime Impact**:
- None - CLGeocoder continues to work in iOS 26
- No performance degradation
- No crashes or errors

**Future Risk**:
- Low immediate risk - deprecated APIs typically supported for 2-3 iOS versions
- Expected removal timeline: iOS 27 or iOS 28 (2026-2027)
- Sufficient time to migrate when MapKit APIs stabilize

## Monitoring Strategy

1. **iOS 26.2+**: Check release notes for MKReverseGeocodingRequest updates
2. **WWDC 2026**: Watch for MapKit sessions on reverse geocoding
3. **Quarterly Review**: Test if new MapKit APIs are available
4. **Community**: Monitor Swift forums and StackOverflow for working implementations

## References

- **Apple Docs**: [MapKit Documentation](https://developer.apple.com/documentation/mapkit)
- **Deprecated API**: [CLGeocoder.reverseGeocodeLocation](https://developer.apple.com/documentation/corelocation/clgeocoder/1423621-reversegeocodelocation)
- **Issue**: #16 - Swift 6 Concurrency Audit (this work item)
- **File**: Sources/Services/Framework/LocationService.swift

---

**Last Updated**: 2026-01-27
**iOS Version Tested**: 26.0, 26.1
**Xcode Version**: 16.x
**Status**: Documented technical debt - acceptable for production
