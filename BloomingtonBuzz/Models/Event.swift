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
    let eventTitle: String
    let eventDescription: String
    let startTime: Date
    let endTime: Date
    let location: String
    let coordinates: CLLocationCoordinate2D
    let eventType: EventType
    let url: URL?
    
    init(id: UUID = UUID(), title: String, description: String, startTime: Date, endTime: Date, 
         location: String, latitude: Double, longitude: Double, eventType: EventType, url: URL? = nil) {
        self.id = id
        self.eventTitle = title
        self.eventDescription = description
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.eventType = eventType
        self.url = url
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
    
    // Optional subtitle for annotation callout
    var subtitle: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(eventType.rawValue)"
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