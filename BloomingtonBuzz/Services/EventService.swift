import Foundation
import SwiftUI
import CoreLocation

class EventService: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let bloomingtonCampusLocation = CLLocationCoordinate2D(
        latitude: 39.168804, 
        longitude: -86.523819
    )
    
    // Fetch events for a specific date
    func fetchEvents(for date: Date) async {
        // Use MainActor for all published property updates
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // TODO: Implement real event data fetching from the IU events website
        // For now, use mock data for development and testing
        
        await MainActor.run {
            self.events = createMockEvents(date: date)
            self.isLoading = false
        }
    }
    
    // Calculate distance between user location and event
    func distance(from userLocation: CLLocationCoordinate2D, to event: Event) -> CLLocationDistance {
        let userLocationObj = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let eventLocationObj = CLLocation(latitude: event.coordinates.latitude, longitude: event.coordinates.longitude)
        return userLocationObj.distance(from: eventLocationObj)
    }
    
    // Filter events by distance
    func eventsWithinRadius(from userLocation: CLLocationCoordinate2D, radius: Double) -> [Event] {
        events.filter { event in
            distance(from: userLocation, to: event) <= radius
        }
    }
    
    // Create mock events for development and testing
    private func createMockEvents(date: Date) -> [Event] {
        // Create a calendar for date manipulation
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // IU Bloomington locations with coordinates - split into smaller definitions
        let wellsLibrary = ("Wells Library", 39.171822, -86.517893, EventType.academic)
        let assemblyHall = ("Assembly Hall", 39.171234, -86.526318, EventType.sports)
        let luddyHall = ("Luddy Hall", 39.172231, -86.523005, EventType.academic)
        let iuAuditorium = ("IU Auditorium", 39.166919, -86.525245, EventType.cultural)
        let memorialUnion = ("Memorial Union", 39.168377, -86.522243, EventType.social)
        let jacobsMusic = ("Jacobs School of Music", 39.166417, -86.518931, EventType.cultural)
        let kelleyBusiness = ("Kelley School of Business", 39.173237, -86.518835, EventType.academic)
        let memorialStadium = ("Memorial Stadium", 39.181003, -86.525131, EventType.sports)
        let collinsCenter = ("Collins Living Learning Center", 39.161716, -86.517992, EventType.social)
        let cookHall = ("Cook Hall", 39.171517, -86.524893, EventType.other)
        
        // Now combine them into the array
        let locations = [
            wellsLibrary,
            assemblyHall,
            luddyHall,
            iuAuditorium,
            memorialUnion, 
            jacobsMusic,
            kelleyBusiness,
            memorialStadium,
            collinsCenter,
            cookHall
        ]
        
        var mockEvents: [Event] = []
        
        // Generate random events throughout the day
        for i in 0..<20 {
            // Random hour between 8 AM and 10 PM
            let startHour = Int.random(in: 8...22)
            components.hour = startHour
            components.minute = [0, 15, 30, 45].randomElement()!
            
            let startTime = calendar.date(from: components)!
            
            // Event lasts 1-3 hours
            let endTime = calendar.date(byAdding: .hour, value: Int.random(in: 1...3), to: startTime)!
            
            // Pick a random location
            let (name, lat, long, type) = locations.randomElement()!
            
            let event = Event(
                title: mockEventNames[i % mockEventNames.count],
                description: mockEventDescriptions.randomElement()!,
                startTime: startTime,
                endTime: endTime,
                location: name,
                latitude: lat,
                longitude: long,
                eventType: type,
                url: URL(string: "https://events.iu.edu/details/\(UUID().uuidString)")
            )
            
            mockEvents.append(event)
        }
        
        return mockEvents
    }
    
    // Mock data
    private let mockEventNames = [
        "Guest Lecture: The Future of AI",
        "Basketball Game: IU vs. Purdue",
        "Symphony Orchestra Concert",
        "Student Career Fair",
        "Faculty Research Showcase",
        "International Food Festival",
        "Movie Night: Classic Films",
        "Coding Workshop",
        "Yoga on the Lawn",
        "Art Gallery Opening",
        "Debate Tournament",
        "Volunteer Fair",
        "Campus Tour for Prospective Students",
        "Game Night",
        "Astronomy Night: Stargazing",
        "Poetry Reading",
        "Research Symposium",
        "Student Government Meeting",
        "Health and Wellness Workshop",
        "Alumni Networking Event"
    ]
    
    private let mockEventDescriptions = [
        "Join us for this exciting event featuring experts in the field.",
        "Don't miss this opportunity to learn and connect with fellow students.",
        "This popular annual event returns with new activities and opportunities.",
        "Open to all students, faculty, and staff. Refreshments will be provided.",
        "Registration required. Visit the website for more details.",
        "This interactive session will provide valuable insights and hands-on experience.",
        "A collaborative event between multiple departments to showcase interdisciplinary work.",
        "Celebrating the diversity and talents of our university community.",
        "An informative session with Q&A opportunities afterward.",
        "Special guests will be in attendance. Arrive early to secure seating."
    ]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationManager())
    }
}
