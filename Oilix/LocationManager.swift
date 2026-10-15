//
//  LocationManager.swift
//  Oilix
//
//  Created by Guo, Congyu on 7/4/22.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    private var requested = false
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published private(set) var errorMessage: String?

    init(startImmediately: Bool = true, manager: CLLocationManager = CLLocationManager()) {
        locationManager = manager
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationStatus = locationManager.authorizationStatus
        if startImmediately { start() }
    }

    func start() {
        requested = true
        errorMessage = nil
        let status = locationManager.authorizationStatus
        locationStatus = status
        switch status {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locationManager.startUpdatingLocation()
        case .denied, .restricted:
            lastLocation = nil
            locationManager.stopUpdatingLocation()
        @unknown default: break
        }
    }

    func stop() {
        requested = false
        locationManager.stopUpdatingLocation()
    }

    var hasAccess: Bool {
        locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse
    }

    var statusString: String {
        switch locationStatus {
        case .denied: return "Location access is off. Enable it for Oilix in Settings."
        case .restricted: return "Location access is restricted on this device."
        case .authorizedAlways, .authorizedWhenInUse: return errorMessage ?? "Waiting for your current location."
        default: return "Allow location access to use your current location."
        }
    }

    static func isUsable(_ location: CLLocation, now: Date = Date()) -> Bool {
        CLLocationCoordinate2DIsValid(location.coordinate) && location.horizontalAccuracy >= 0 &&
            abs(location.timestamp.timeIntervalSince(now)) <= 120
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationStatus = status
        if status == .denied || status == .restricted {
            lastLocation = nil
            manager.stopUpdatingLocation()
        } else if requested && (status == .authorizedWhenInUse || status == .authorizedAlways) {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, Self.isUsable(location) else { return }
        errorMessage = nil
        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .locationUnknown { return }
        errorMessage = "Your location could not be determined. Try again or enter coordinates manually."
    }

    deinit { locationManager.stopUpdatingLocation() }
}
