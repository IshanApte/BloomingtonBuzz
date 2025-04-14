import Foundation
import CoreLocation
import Combine
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var centerOnUserLocation: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var useSimulatedLocation: Bool = false
    
    // Campus coordinates for simulated locations
    // Default to IU Bloomington
    private let simulatedLocations: [String: CLLocation] = [
        "IU Bloomington": CLLocation(latitude: 39.168804, longitude: -86.523819),
        "Sample Hall": CLLocation(latitude: 39.172231, longitude: -86.523005),
        "Wells Library": CLLocation(latitude: 39.171822, longitude: -86.517893),
        "Assembly Hall": CLLocation(latitude: 39.171234, longitude: -86.526318)
    ]
    
    private var selectedSimulationLocation = "IU Bloomington"
    private var locationErrorCount = 0
    private let maxErrorsBeforeSimulation = 2
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        // Configure for maximum accuracy
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // Highest accuracy
        locationManager.distanceFilter = 5 // Update with smaller movements
        locationManager.pausesLocationUpdatesAutomatically = false // Don't pause updates
        locationManager.allowsBackgroundLocationUpdates = false // No background updates needed
        
        // Set the location timeout to a shorter value to detect failures faster
        locationManager.activityType = .fitness // More continuous tracking
        
        // Check if we're running in a simulator
        #if targetEnvironment(simulator)
        print("📱 Running in simulator - will use simulated location")
        useSimulatedLocation = true
        activateSimulatedLocation()
        #else
        // Check current authorization status
        checkLocationAuthorization()
        #endif
    }
    
    private func activateSimulatedLocation() {
        print("🔄 Using simulated location: \(selectedSimulationLocation)")
        if let simulatedLocation = simulatedLocations[selectedSimulationLocation] {
            self.location = simulatedLocation
        } else {
            // Fallback to IU Bloomington if selection not found
            self.location = simulatedLocations["IU Bloomington"]
        }
    }
    
    // Change the simulated location (useful for testing)
    func changeSimulationLocation(to locationName: String) {
        if simulatedLocations.keys.contains(locationName) {
            selectedSimulationLocation = locationName
            if useSimulatedLocation {
                activateSimulatedLocation()
            }
        }
    }
    
    // Toggle between real and simulated location (for debugging)
    func toggleSimulatedLocation() {
        useSimulatedLocation.toggle()
        if useSimulatedLocation {
            activateSimulatedLocation()
        } else {
            startUpdatingLocation()
        }
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission already granted")
            permissionDenied = false
            locationManager.startUpdatingLocation()
            
        case .denied, .restricted:
            print("❌ Location permission denied or restricted")
            permissionDenied = true
            // Fall back to simulated location
            useSimulatedLocation = true
            activateSimulatedLocation()
            
        case .notDetermined:
            print("⏳ Location permission not determined yet, requesting...")
            permissionDenied = false
            locationManager.requestWhenInUseAuthorization()
            
        @unknown default:
            print("⚠️ Unknown location authorization status")
            permissionDenied = true
            // Fall back to simulated location
            useSimulatedLocation = true
            activateSimulatedLocation()
        }
    }
    
    func requestAuthorization() {
        print("🔍 Requesting location authorization...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        if useSimulatedLocation {
            print("🔄 Using simulated location instead of real updates")
            activateSimulatedLocation()
            return
        }
        
        print("🔄 Starting location updates with high accuracy")
        // Force a reset of the location manager to ensure fresh starts
        locationManager.stopUpdatingLocation()
        // Set high accuracy options again
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        if !useSimulatedLocation {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func centerMapOnUser() {
        print("🎯 Centering map on user...")
        
        if useSimulatedLocation {
            centerOnUserLocation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.centerOnUserLocation = false
            }
            return
        }
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
            centerOnUserLocation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.centerOnUserLocation = false
            }
        } else {
            print("⚠️ Cannot center on user: no location permission")
            requestAuthorization()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        print("🔔 Location authorization status changed: \(authorizationStatusString(manager.authorizationStatus))")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location access granted, starting updates")
            permissionDenied = false
            useSimulatedLocation = false
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ Location access denied or restricted")
            permissionDenied = true
            useSimulatedLocation = true
            activateSimulatedLocation()
        case .notDetermined:
            print("⏳ Location access not determined")
            permissionDenied = false
        @unknown default:
            print("⚠️ Unknown authorization status")
            permissionDenied = true
            useSimulatedLocation = true
            activateSimulatedLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Check accuracy to ensure we have a good location fix
        let accuracy = location.horizontalAccuracy
        
        if accuracy < 0 || accuracy > 100 {
            // If accuracy is negative or too high (over 100 meters), the location is invalid
            print("⚠️ Poor location accuracy: \(accuracy)m - rejecting update")
            locationErrorCount += 1
            
            if locationErrorCount >= maxErrorsBeforeSimulation {
                print("⚠️ Too many poor accuracy updates, switching to simulated location")
                useSimulatedLocation = true
                activateSimulatedLocation()
            }
            return
        }
        
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude) (accuracy: \(accuracy)m)")
        locationErrorCount = 0 // Reset error count on successful location update
        
        // Update location only if it's a significant change or first update
        if self.location == nil || 
           self.location!.distance(from: location) > 5 || // Smaller threshold
           abs(location.timestamp.timeIntervalSince(self.location!.timestamp)) > 30 || // More frequent updates
           location.horizontalAccuracy < self.location!.horizontalAccuracy // Better accuracy
        {
            self.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed with error: \(error.localizedDescription)")
        
        // Increment error count
        locationErrorCount += 1
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("⛔ Location services denied by user")
                permissionDenied = true
                useSimulatedLocation = true
                activateSimulatedLocation()
                
            case .locationUnknown:
                print("❓ Location unknown (error 1) - count: \(locationErrorCount)")
                // After multiple location unknown errors, switch to simulated location
                if locationErrorCount >= maxErrorsBeforeSimulation {
                    print("⚠️ Too many location errors, switching to simulated location")
                    useSimulatedLocation = true
                    activateSimulatedLocation()
                } else {
                    // Try to recover by restarting location updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startUpdatingLocation()
                    }
                }
                
            default:
                print("⚠️ Other location error: \(clError.code.rawValue)")
                if locationErrorCount >= maxErrorsBeforeSimulation {
                    useSimulatedLocation = true
                    activateSimulatedLocation()
                } else {
                    // Try to recover by restarting location updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startUpdatingLocation()
                    }
                }
            }
        }
    }
    
    private func authorizationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        case .authorizedAlways:
            return "Authorized Always"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Determined"
        @unknown default:
            return "Unknown"
        }
    }
} 