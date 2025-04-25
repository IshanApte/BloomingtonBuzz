import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Format the event time string once
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: event.startTime)
        let end = formatter.string(from: event.endTime)
        let timeString = event.isAllDay ? "All Day" : "\(start) – \(end)"
        
        return ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                // Event header
                HStack {
                    Image(systemName: event.eventType.icon)
                        .font(.title)
                        .foregroundColor(event.eventType.color)
                    
                    Spacer()
                    
                    Text(event.eventType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(event.eventType.color.opacity(0.2))
                        )
                }
                .padding(.bottom, 5)
                
                // Event title
                Text(event.eventTitle)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Time information
                // VStack(alignment: .leading, spacing: 5) {
                //     Label {
                //         HStack {
                //             Text(formattedDate(event.startTime))
                //             Text("–")
                //             Text(formattedTime(event.endTime))
                //         }
                //     } icon: {
                //         Image(systemName: "clock")
                //     }
                //     .foregroundColor(.primary)
                // }
                // .padding(.vertical, 5)
                
                // Location information
                VStack(alignment: .leading, spacing: 5) {
                    Label {
                        Text(event.location)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // Description
                Text("About")
                    .font(.headline)
                    .padding(.top, 5)
                
                // Show event time in description
                Text(timeString)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(event.eventDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Map preview
                Text("Location")
                    .font(.headline)
                    .padding(.top, 10)
                
                // Show the address
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: event.coordinates,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )), annotationItems: [event]) { item in
                    MapMarker(coordinate: item.coordinates, tint: event.eventType.color)
                }
                .frame(height: 200)
                .cornerRadius(12)
                
                // Directions button
                Button(action: {
                    openInGoogleMapsOrAppleMaps()
                }) {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(event.eventType.color)
                .controlSize(.large)
                .padding(.top, 10)
                
                // Always show Visit Website button in green
                Button(action: {
                    if let url = event.url {
                        UIApplication.shared.open(url)
                    } else {
                        // Show a message if no URL is available
                        // In a real app, you might use an alert. For now, do nothing.
                    }
                }) {
                    Label("Visit Website", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
                .padding(.top, 4)
                .disabled(event.url == nil)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // Format date in a readable format
    // private func formattedDate(_ date: Date) -> String {
    //     let formatter = DateFormatter()
    //     formatter.dateStyle = .medium
    //     formatter.timeStyle = .short
    //     return formatter.string(from: date)
    // }
    
    // Format time only
    // private func formattedTime(_ date: Date) -> String {
    //     let formatter = DateFormatter()
    //     formatter.dateStyle = .none
    //     formatter.timeStyle = .short
    //     return formatter.string(from: date)
    // }
    
    // Open the location in Google Maps if available, otherwise Apple Maps
    private func openInGoogleMapsOrAppleMaps() {
        let destination = "\(event.coordinates.latitude),\(event.coordinates.longitude)"
        if let url = URL(string: "comgooglemaps://"), UIApplication.shared.canOpenURL(url) {
            if let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(destination)&directionsmode=driving") {
                UIApplication.shared.open(googleMapsURL)
                return
            }
        }
        // Fallback to Apple Maps
        let placemark = MKPlacemark(coordinate: event.coordinates)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.eventTitle
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

#Preview {
    // Create a sample event for testing
    let sampleEvent = Event(
        eventId: 0,
        title: "Guest Lecture: The Future of AI",
        description: "Join us for this exciting event featuring experts in the field of artificial intelligence. Learn about the latest developments and future trends.",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        location: "Luddy Hall",
        latitude: 39.172231,
        longitude: -86.523005,
        eventType: .academic
    )
    
    return EventDetailView(event: sampleEvent)
} 