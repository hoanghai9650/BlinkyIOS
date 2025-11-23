//
//  LocationService.swift
//  Blinky
//
//  Created by Codex.
//

import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var lastKnownLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationDescription: String?
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestAccessIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func refreshLocation() {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
    
    private func updateDescription(with location: CLLocation) {
        let fallback = coordinatesDescription(for: location)
        locationDescription = fallback
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }
            if let placemark = placemarks?.first {
                let pieces = [placemark.subLocality, placemark.locality, placemark.country].compactMap { $0 }
                let resolved = pieces.isEmpty ? fallback : pieces.joined(separator: ", ")
                DispatchQueue.main.async {
                    self.locationDescription = resolved
                }
            } else if error != nil {
                DispatchQueue.main.async {
                    self.locationDescription = fallback
                }
            }
        }
    }
    
    private func coordinatesDescription(for location: CLLocation) -> String {
        let latitude = String(format: "%.4f", location.coordinate.latitude)
        let longitude = String(format: "%.4f", location.coordinate.longitude)
        return "Lat: \(latitude), Lon: \(longitude)"
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
        updateDescription(with: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("Location error:", error.localizedDescription)
        #endif
    }
}
