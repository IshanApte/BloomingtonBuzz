import SwiftUI
import MapKit

// MapKit annotation view provider for SwiftUI integration
class EventAnnotationViewProvider: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't provide a custom view for the user location
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Check if this is an event annotation
        guard let eventAnnotation = annotation as? Event else {
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
            let eventType = eventAnnotation.eventType
            
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
        
        // Post a notification that will be picked up by SwiftUI
        NotificationCenter.default.post(
            name: Notification.Name("DidSelectEventAnnotation"),
            object: nil,
            userInfo: ["event": event]
        )
    }
} 