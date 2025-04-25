import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    var events: [Event]
    var onEventSelected: (Event) -> Void
    var radiusFilter: Double
    
    // Create the MapKit view
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // Configure for best user location visibility
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow // Changed from followWithHeading for better stability
        
        // Additional user location settings
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        
        mapView.delegate = context.coordinator
        
        print("MapView created - showing user location")
        
        // Set a default campus region in case location isn't available yet
        let defaultCenter = CLLocationCoordinate2D(latitude: 39.168804, longitude: -86.523819) // IU Bloomington
        let defaultRegion = MKCoordinateRegion(
            center: defaultCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // Much more zoomed in
        )
        mapView.setRegion(defaultRegion, animated: false)
        
        // If we already have user location, use it
        if let userLocation = locationManager.location?.coordinate {
            print("Initial user location available: \(userLocation.latitude), \(userLocation.longitude)")
            let initialRegion = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(initialRegion, animated: false)
        } else {
            print("No initial user location available")
        }
        
        return mapView
    }
    
    // Update the view when data changes
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the map with events
        updateAnnotations(mapView: mapView)
        
        // Add simulated user location marker if needed
        if locationManager.useSimulatedLocation, let simulatedLocation = locationManager.location {
            // Check if we already have a simulated user annotation
            let existingSimulatedMarkers = mapView.annotations.filter { $0.title == "You Are Here (Simulated)" }
            
            // If we don't have one yet or its position has changed, update it
            if existingSimulatedMarkers.isEmpty {
                let userAnnotation = MKPointAnnotation()
                userAnnotation.coordinate = simulatedLocation.coordinate
                userAnnotation.title = "You Are Here (Simulated)"
                mapView.addAnnotation(userAnnotation)
                print("🔵 Added simulated user location marker")
            }
        }
        
        // Check for user location visibility
        if mapView.showsUserLocation {
            if let userLocation = mapView.userLocation.location {
                print("📍 MapView shows user at: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            } else if locationManager.useSimulatedLocation, let simulatedLoc = locationManager.location {
                print("🔵 Using simulated location: \(simulatedLoc.coordinate.latitude), \(simulatedLoc.coordinate.longitude)")
            } else {
                print("⚠️ MapView's user location is nil despite showsUserLocation = true")
            }
        } else {
            print("❌ MapView is not configured to show user location")
        }
        
        // If centerOnUserLocation is triggered, focus the map on user (real or simulated)
        if locationManager.centerOnUserLocation, let userLocation = locationManager.location?.coordinate {
            print("🎯 Centering map on location: \(userLocation.latitude), \(userLocation.longitude)")
            let region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005) // Very zoomed in
            )
            mapView.setRegion(region, animated: true)
            return
        }
        
        // Set the visible region to include the user and nearby events
        if let userLocation = locationManager.location?.coordinate {
            // Use a smaller radius for a more zoomed in view
            let visibleRadius = min(radiusFilter, 1000.0) // Limit maximum zoom-out
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: visibleRadius * 2,
                longitudinalMeters: visibleRadius * 2
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Create the coordinator for delegate methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Update map annotations without removing/re-adding unchanged ones
    private func updateAnnotations(mapView: MKMapView) {
        // Get all current annotations except user location
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        
        // Filter events based on radius if user location is available
        let filteredEvents: [Event]
        if let userLocation = locationManager.location?.coordinate {
            filteredEvents = events.filter { event in
                let eventLocation = CLLocation(latitude: event.coordinates.latitude, longitude: event.coordinates.longitude)
                let userLocationObj = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                return eventLocation.distance(from: userLocationObj) <= radiusFilter
            }
        } else {
            filteredEvents = events
        }
        
        // Find annotations to remove (not in filtered events)
        let annotationsToRemove = currentAnnotations.filter { annotation in
            guard let eventAnnotation = annotation as? Event else { return true }
            return !filteredEvents.contains(where: { $0.id == eventAnnotation.id })
        }
        
        // Find events to add (not already in map annotations)
        let eventsToAdd = filteredEvents.filter { event in
            !currentAnnotations.contains(where: { annotation in
                guard let eventAnnotation = annotation as? Event else { return false }
                return eventAnnotation.id == event.id
            })
        }
        
        // Remove and add annotations as needed
        if !annotationsToRemove.isEmpty {
            mapView.removeAnnotations(annotationsToRemove)
        }
        
        if !eventsToAdd.isEmpty {
            mapView.addAnnotations(eventsToAdd)
        }
    }
    
    // Coordinator class for delegate callbacks
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            
            // Add observer for event selection notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(eventSelected),
                name: Notification.Name("DidSelectEventAnnotation"),
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        // Handle event selection from notification
        @objc func eventSelected(_ notification: Notification) {
            guard let event = notification.userInfo?["event"] as? Event else { return }
            parent.onEventSelected(event)
        }
        
        // Provide custom annotation views for events
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // For user location, return nil to use the default blue dot
            if annotation is MKUserLocation {
                return nil
            }
            
            // For simulated user location
            if annotation.title == "You Are Here (Simulated)" {
                let identifier = "SimulatedUserLocation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Style the simulated user marker differently
                annotationView?.markerTintColor = UIColor.systemBlue
                annotationView?.glyphImage = UIImage(systemName: "location.fill")
                annotationView?.displayPriority = .required
                
                return annotationView
            }
            
            // Cast to Event if possible
            guard let event = annotation as? Event else {
                return nil
            }
            
            // Try to reuse an existing annotation view
            let identifier = "EventAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Add a button to show event details
                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            
            // Configure the marker annotation
            if let markerAnnotationView = annotationView as? MKMarkerAnnotationView {
                let eventType = event.eventType
                
                // Set the marker color based on event type
                switch eventType {
                case .academic:
                    markerAnnotationView.markerTintColor = UIColor.systemBlue
                    markerAnnotationView.glyphImage = UIImage(systemName: "book.fill")
                case .sports:
                    markerAnnotationView.markerTintColor = UIColor.systemGreen
                    markerAnnotationView.glyphImage = UIImage(systemName: "sportscourt.fill")
                case .cultural:
                    markerAnnotationView.markerTintColor = UIColor.systemPurple
                    markerAnnotationView.glyphImage = UIImage(systemName: "theatermasks.fill")
                case .social:
                    markerAnnotationView.markerTintColor = UIColor.systemOrange
                    markerAnnotationView.glyphImage = UIImage(systemName: "person.3.fill")
                case .other:
                    markerAnnotationView.markerTintColor = UIColor.systemGray
                    markerAnnotationView.glyphImage = UIImage(systemName: "star.fill")
                }
            }
            
            return annotationView
        }
        
        // Handle taps on the callout button
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let event = view.annotation as? Event else { return }
            parent.onEventSelected(event)
        }
    }
}

#Preview {
    // Create a sample event for testing
    let sampleEvent = Event(
        eventId: 0,
        title: "Sample Event",
        description: "This is a sample event for preview",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        location: "Sample Hall",
        latitude: 39.168804,
        longitude: -86.523819,
        eventType: .academic
    )
    
    return MapView(
        locationManager: LocationManager(),
        events: [sampleEvent],
        onEventSelected: { _ in },
        radiusFilter: 2000
    )
} 