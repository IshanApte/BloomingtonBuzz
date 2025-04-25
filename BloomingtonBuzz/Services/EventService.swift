import Foundation
import SwiftUI
import CoreLocation
import SwiftSoup

class EventService: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Define available tags
    static let availableTags = [
        "Free Food",
        "Indoor",
        "Outdoor",
        "Community Engagement",
        "Welcome Week",
        "Admissions"
    ]
    
    private let bloomingtonCampusLocation = CLLocationCoordinate2D(
        latitude: 39.168804, 
        longitude: -86.523819
    )
    
    // Fetch events for a specific date from the RSS feed
    func fetchEvents(for date: Date, tags: [String] = []) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // Build the base URL
        var urlString = "https://events.iu.edu/live/rss/events/category_id/12/audience/Students/tag/In%20Person"
        
        // Add selected tags
        for tag in tags {
            // Ensure proper URL encoding for tags with spaces
            let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
            urlString += "/tags/\(encodedTag)"
        }
        
        // Add date filter
        urlString += "/start_date/-24%20hours/"
        
        print("[DEBUG] API URL with tags: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.error = NSError(domain: "EventService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                self.isLoading = false
            }
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parsedEvents = await parseEventsFromRSS(data: data, date: date)
            
            print("[DEBUG] Filtered events for tags: \(tags)")
            
            // Geocode all event locations
            let geocodedEvents = await geocodeEvents(parsedEvents)
            print("[DEBUG] Total events fetched: \(geocodedEvents.count)")
            
            await MainActor.run {
                // Removed active event filtering
                self.events = geocodedEvents
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }

    // Parse events from RSS XML data
    private func parseEventsFromRSS(data: Data, date: Date) async -> [Event] {
        let parser = XMLParser(data: data)
        let delegate = IUEventsRSSParserDelegate()
        parser.delegate = delegate
        parser.parse()
        
        // Create a dictionary to store unique events by GUID
        var uniqueEvents: [String: Event] = [:]
        
        // Filter events for the selected date
            for event in delegate.events {
            if Calendar.current.isDate(event.startTime, inSameDayAs: date) {
                // Use the GUID URL as the unique key
                if let guidURL = event.url?.absoluteString {
                    // Only keep the first occurrence of each GUID
                    if uniqueEvents[guidURL] == nil {
                        uniqueEvents[guidURL] = event
                    }
                }
            }
        }
        
        // Convert back to array and sort by start time
        let filteredEvents = Array(uniqueEvents.values).sorted { $0.startTime < $1.startTime }
        
        // Limit to 20 events per day
        return Array(filteredEvents)
    }
    
    // Geocode event locations asynchronously
    private func geocodeEvents(_ events: [Event]) async -> [Event] {
        var geocodedEvents: [Event] = []
        for event in events {
            if !event.location.isEmpty {
                if let coords = await geocodeAddress(event.location) {
                    let updatedEvent = Event(
                        id: event.id,
                        eventId: event.eventId,
                        title: event.eventTitle,
                        description: event.eventDescription,
                        startTime: event.startTime,
                        endTime: event.endTime,
                        location: event.location,
                        latitude: coords.latitude,
                        longitude: coords.longitude,
                        eventType: event.eventType,
                        url: event.url
                    )
                    geocodedEvents.append(updatedEvent)
                    continue
                }
            }
            // Fallback to default coordinates
            geocodedEvents.append(event)
        }
        return geocodedEvents
    }

    // Geocode an address string to coordinates
    private func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        // Skip geocoding if address is empty
        guard !address.isEmpty else { return nil }
        
        // Define known locations dictionary
        let knownLocations: [String: (name: String, lat: Double, lon: Double)] = [
            // IMU variations
            "IMU": ("Indiana Memorial Union", 39.167980, -86.523055),
            "Indiana Memorial Union": ("Indiana Memorial Union", 39.167980, -86.523055),
            "Memorial Union": ("Indiana Memorial Union", 39.167980, -86.523055),
            "Union": ("Indiana Memorial Union", 39.167980, -86.523055),
            
            // Ballantine Hall variations
            "Ballantine": ("Ballantine Hall", 39.168375, -86.522841),
            "Ballantine Hall": ("Ballantine Hall", 39.168375, -86.522841),
            "BH": ("Ballantine Hall", 39.168375, -86.522841)
        ]
        
        // Check if the location matches any known location
        for (keyword, locationInfo) in knownLocations {
            if address.contains(keyword) {
                return CLLocationCoordinate2D(
                    latitude: locationInfo.lat,
                    longitude: locationInfo.lon
                )
            }
        }
        
        // If no match found, proceed with regular geocoding
        let fullAddress = "\(address), Bloomington, Indiana"
        
        return await withCheckedContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(fullAddress) { placemarks, error in
                if let location = placemarks?.first?.location {
                    // Verify the coordinates are within Bloomington area
                    let bloomingtonBounds = (
                        minLat: 39.1,  // Southern boundary
                        maxLat: 39.2,  // Northern boundary
                        minLon: -86.6, // Western boundary
                        maxLon: -86.4  // Eastern boundary
                    )
                    
                    let coords = location.coordinate
                    if coords.latitude >= bloomingtonBounds.minLat &&
                       coords.latitude <= bloomingtonBounds.maxLat &&
                       coords.longitude >= bloomingtonBounds.minLon &&
                       coords.longitude <= bloomingtonBounds.maxLon {
                        continuation.resume(returning: coords)
                    } else {
                        // If outside Bloomington bounds, fall back to campus center
                        continuation.resume(returning: CLLocationCoordinate2D(
                            latitude: 39.168804,
                            longitude: -86.523819
                        ))
                    }
                } else {
                    // If geocoding fails, try without "Indiana"
                    geocoder.geocodeAddressString("\(address), Bloomington") { placemarks, error in
                        if let location = placemarks?.first?.location {
                            continuation.resume(returning: location.coordinate)
                        } else {
                            // If all geocoding attempts fail, use campus center
                            continuation.resume(returning: CLLocationCoordinate2D(
                                latitude: 39.168804,
                                longitude: -86.523819
                            ))
                        }
                    }
                }
            }
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

    // Add this struct for JSON event details
    private struct JSONEventDetail: Codable {
        let date_time: String?
        let date2_time: String?
    }

    // Add this async function to fetch event times by id
    // private func fetchEventTimes(for id: Int) async -> (String?, String?) {
    //     let urlString = "https://events.iu.edu/live/events/\(id)@JSON"
    //     guard let url = URL(string: urlString) else { return (nil, nil) }
    //     do {
    //         let (data, _) = try await URLSession.shared.data(from: url)
    //         let decoded = try JSONDecoder().decode(JSONEventDetail.self, from: data)
    //         return (decoded.date_time, decoded.date2_time)
    //     } catch {
    //         print("Error fetching event times: \(error)")
    //         return (nil, nil)
    //     }
    // }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(EventService())
            .environmentObject(LocationManager())
    }
}

// MARK: - API Response Models

private struct EventsAPIResponse: Codable {
    let data: [APIEvent]
}

private struct APIEvent: Codable {
    let id: Int
    let title: String
    let url: String?
    let date_iso: String?
    let description: String?
    let location: String?
    let is_all_day: Int? // 1 for all day, 0 or nil otherwise
    // Add more fields as needed
    // For now, we will use only these for mapping
    
    func toEvent(withLocation location: String?) -> Event? {
        // Parse date
        let formatter = ISO8601DateFormatter()
        let startTime = date_iso.flatMap { formatter.date(from: $0) } ?? Date()
        // No end time in API, so use +1 hour
        let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
        // No lat/lon in API, so use campus center
        let latitude = 39.168804
        let longitude = -86.523819
        // Try to infer event type from title or location
        let eventType: EventType = .other
        let isAllDay = (is_all_day ?? 0) == 1
        return Event(
            eventId: id,
            title: title,
            description: description ?? "",
            startTime: startTime,
            endTime: endTime,
            location: location ?? "IU Bloomington",
            latitude: latitude,
            longitude: longitude,
            eventType: eventType,
            url: url.flatMap { URL(string: $0) },
            isAllDay: isAllDay
        )
    }
}

// XMLParserDelegate for IU Events RSS
class IUEventsRSSParserDelegate: NSObject, XMLParserDelegate {
    var events: [Event] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentEndDate = ""
    private var currentLocation = ""
    private var currentEventType: EventType = .other
    private var currentGuidBuffer: String = ""
    private var currentTags: [String] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentEndDate = ""
            currentLocation = ""
            currentEventType = .other
            currentGuidBuffer = ""
            currentTags = []
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "description":
            currentDescription += string
        case "pubDate":
            currentPubDate += string
        case "livewhale:ends":
            currentEndDate += string
        case "georss:featurename":
            currentLocation += string
        case "guid":
            currentGuidBuffer += string
        case "category":
            let tag = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tag.isEmpty {
                currentTags.append(tag)
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // Parse the dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z" // RSS date format
            
            let startTime = dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date()
            var endTime = startTime
            
            // If we have an end date, parse it
            if !currentEndDate.isEmpty {
                if let parsedEndTime = dateFormatter.date(from: currentEndDate.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    endTime = parsedEndTime
                } else {
                    // Default to 1 hour duration if end time parsing fails
                    endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
                }
            } else {
                // Default to 1 hour duration if no end time
                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
            }
            
            // Clean up the GUID URL
            let guidURL = currentGuidBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only create the event if we have a valid GUID URL
            if !guidURL.isEmpty, let url = URL(string: guidURL) {
            let event = Event(
                    eventId: 0, // We're not using eventId anymore
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: extractFirstParagraph(from: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines)),
                startTime: startTime,
                endTime: endTime,
                location: currentLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                    latitude: 39.168804, // Will be updated by geocoding
                    longitude: -86.523819, // Will be updated by geocoding
                eventType: currentEventType,
                    url: url,
                    tags: currentTags
            )
            events.append(event)
            }
        }
    }
    
    // Helper to extract the first <p>...</p> content from HTML
    private func extractFirstParagraph(from html: String) -> String {
        guard let startRange = html.range(of: "<p>") else { return "" }
        guard let endRange = html.range(of: "</p>", range: startRange.upperBound..<html.endIndex) else { return "" }
        let paragraph = html[startRange.upperBound..<endRange.lowerBound]
        return String(paragraph).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
