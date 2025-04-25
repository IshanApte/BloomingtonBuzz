import Foundation
import CoreLocation
import MapKit
import SwiftUI

enum EventType: String, Codable, CaseIterable {
    case academic = "Academic"
    case sports = "Sports"
    case cultural = "Cultural" 
    case social = "Social"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .academic: return "book.fill"
        case .sports: return "sportscourt.fill"
        case .cultural: return "theatermasks.fill"
        case .social: return "person.3.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .academic: return .blue
        case .sports: return .green
        case .cultural: return .purple
        case .social: return .orange
        case .other: return .gray
        }
    }
}

class Event: NSObject, Identifiable, Codable, MKAnnotation {
    let id: UUID
    let eventId: Int // LiveWhale event ID for matching with JSON API
    let eventTitle: String
    let eventDescription: String
    let startTime: Date
    let endTime: Date
    let location: String
    let coordinates: CLLocationCoordinate2D
    let eventType: EventType
    let url: URL?
    let isAllDay: Bool
    let hasValidTimes: Bool  // New property to track if we have valid time data
    let tags: [String]  // Add this property
    
    init(id: UUID = UUID(), eventId: Int, title: String, description: String, startTime: Date, endTime: Date, 
         location: String, latitude: Double, longitude: Double, eventType: EventType, url: URL? = nil, 
         isAllDay: Bool = false, hasValidTimes: Bool = true, tags: [String] = []) {
        self.id = id
        self.eventId = eventId
        self.eventTitle = title
        self.eventDescription = description
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.eventType = eventType
        self.url = url
        self.isAllDay = isAllDay
        self.hasValidTimes = hasValidTimes
        self.tags = tags  // Initialize tags
        super.init()
    }
    
    // MKAnnotation protocol requirements
    var coordinate: CLLocationCoordinate2D {
        return coordinates
    }
    
    // Required by MKAnnotation (must be optional String)
    var title: String? {
        return eventTitle
    }
    
    // Updated subtitle for annotation callout
    var subtitle: String? {
        if isAllDay {
            return "All Day"
        }
        
        if !hasValidTimes {
            return "Check Website"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "\(start) – \(end)"
    }
    
    // New method to get formatted time for detail view
    func formattedTimeString() -> String {
        if isAllDay {
            return "All Day"
        }
        
        if !hasValidTimes {
            return "Check Website for Times"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "\(start) – \(end)"
    }
}

// Extension to make CLLocationCoordinate2D codable
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
} 