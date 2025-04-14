import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical) {
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
                VStack(alignment: .leading, spacing: 5) {
                    Label {
                        HStack {
                            Text(formattedDate(event.startTime))
                            Text("–")
                            Text(formattedTime(event.endTime))
                        }
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .foregroundColor(.primary)
                }
                .padding(.vertical, 5)
                
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
                
                Text(event.eventDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Map preview
                Text("Location")
                    .font(.headline)
                    .padding(.top, 10)
                
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
                    openInMaps()
                }) {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(event.eventType.color)
                .controlSize(.large)
                .padding(.top, 10)
                
                // Link to website if available
                if let url = event.url {
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        Label("View on Website", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
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
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Format time only
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Open the location in Apple Maps
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: event.coordinates)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.eventTitle
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

#Preview {
    // Create a sample event for testing
    let sampleEvent = Event(
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