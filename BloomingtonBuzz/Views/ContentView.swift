import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var eventService: EventService
    
    @State private var selectedEvent: Event?
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var radiusFilter: Double = 2000 // Default to 2km
    @State private var selectedDate = Date()
    @State private var showPermissionDeniedAlert = false
    @State private var selectedTags: Set<String> = []
    
    // IU Colors
    private let iuRed = Color(red: 152/255, green: 0/255, blue: 0/255) // #980000
    private let iuRedLight = Color(red: 179/255, green: 27/255, blue: 27/255)
    private let iuWhite = Color.white
    private let iuGray = Color(red: 240/255, green: 240/255, blue: 240/255)
    
    var body: some View {
        NavigationStack {
            mainContent
        }
        .preferredColorScheme(.light)
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            iuRed.ignoresSafeArea()
            mapSection
            eventsListView
        }
        .navigationTitle("Campus Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(iuRed, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search events")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilters = true }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        if selectedTags.count > 0 {
                            Text("\(selectedTags.count)")
                        }
                    }
                    .foregroundColor(selectedTags.isEmpty ? iuWhite : iuWhite)
                }
            }
        }
        .onAppear {
            print("ContentView appeared")
            locationManager.checkLocationAuthorization()
            locationManager.startUpdatingLocation()
            Task {
                await eventService.fetchEvents(for: Date())
            }
        }
        .onReceive(locationManager.$permissionDenied) { denied in
            showPermissionDeniedAlert = denied
        }
        .alert("Location Access Required", isPresented: $showPermissionDeniedAlert, actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("Please grant location access in Settings to see your position on the map and find events near you.")
        })
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(selectedTags: $selectedTags)
        }
        .onChange(of: searchText) { _ in
            Task {
                await eventService.fetchEvents(for: Date(), tags: Array(selectedTags))
            }
        }
    }
    
    private var mapSection: some View {
        ZStack(alignment: .bottomTrailing) {
            MapView(
                locationManager: locationManager,
                events: filteredEvents,
                onEventSelected: { event in
                    selectedEvent = event
                },
                radiusFilter: radiusFilter
            )
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) {
                locationStatusOverlay
            }
            Button(action: {
                locationManager.centerMapOnUser()
            }) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .padding(12)
                    .background(iuWhite)
                    .foregroundColor(iuRed)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 270)
        }
    }
    
    #if DEBUG
    private var locationStatusOverlay: some View {
        VStack {
            if locationManager.location == nil {
                Text("Location: Unknown")
                    .font(.caption)
                    .padding(6)
                    .background(iuRedLight)
                    .foregroundColor(iuWhite)
                    .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location: \(locationManager.location!.coordinate.latitude), \(locationManager.location!.coordinate.longitude)")
                        .font(.caption)
                        .foregroundColor(iuWhite)
                    if locationManager.useSimulatedLocation {
                        Text("SIMULATED LOCATION")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
                .padding(6)
                .background(iuRedLight)
                .foregroundColor(iuWhite)
                .cornerRadius(8)
            }
        }
        .padding(.top, 60)
    }
    #else
    private var locationStatusOverlay: some View { EmptyView() }
    #endif
    
    private var eventsListView: some View {
        VStack(spacing: 0) {
            Group {
                if eventService.isLoading {
                    ProgressView("Loading events...")
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(iuWhite)
                        .foregroundColor(iuRed)
                } else if filteredEvents.isEmpty {
                    Text("No events found nearby")
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(iuWhite)
                        .foregroundColor(iuRed)
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            EventRow(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 250)
                    .background(iuWhite)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal)
            .shadow(radius: 3)
        }
    }
    
    private var filteredEvents: [Event] {
        var events = eventService.events
        
        // Create a dictionary to track unique events by title and date
        var uniqueEvents: [String: Event] = [:]
        for event in events {
            // Create a unique key combining title and date
            let key = "\(event.eventTitle)_\(event.startTime)"
            // Keep the first occurrence of each event
            if uniqueEvents[key] == nil {
                uniqueEvents[key] = event
            }
        }
        
        // Debug print only unique events
        print("\n=== DEBUG: Unique Events (\(uniqueEvents.count) total) ===")
        for (key, event) in uniqueEvents.sorted(by: { $0.value.startTime < $1.value.startTime }) {
            print("📅 Title: \(event.eventTitle)")
            print("⏰ Start Time: \(event.startTime)")
            if let url = event.url?.absoluteString {
                print("🔗 URL: \(url)")
            }
            print("---")
        }
        print("=== End Unique Events ===\n")
        
        if !searchText.isEmpty {
            events = events.filter { (event: Event) in
                event.eventTitle.localizedCaseInsensitiveContains(searchText) ||
                event.eventDescription.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
            
            // Debug print for filtered unique events
            if events.count != eventService.events.count {
                var uniqueFilteredEvents: [String: Event] = [:]
                for event in events {
                    let key = "\(event.eventTitle)_\(event.startTime)"
                    if uniqueFilteredEvents[key] == nil {
                        uniqueFilteredEvents[key] = event
                    }
                }
                
                print("\n=== DEBUG: Filtered Unique Events ===")
                print("Search text: '\(searchText)'")
                print("Found \(uniqueFilteredEvents.count) unique matches:")
                for (key, event) in uniqueFilteredEvents.sorted(by: { $0.value.startTime < $1.value.startTime }) {
                    print("📅 Title: \(event.eventTitle)")
                    print("⏰ Start Time: \(event.startTime)")
                    if let url = event.url?.absoluteString {
                        print("🔗 URL: \(url)")
                    }
                    print("---")
                }
                print("=== End Filtered Unique Events ===\n")
            }
        }
        
        // Convert unique events back to array
        events = Array(uniqueEvents.values)
        events.sort { $0.startTime < $1.startTime }
        return events
    }
}

struct EventRow: View {
    let event: Event
    private let iuRed = Color(red: 152/255, green: 0/255, blue: 0/255)
    private let iuWhite = Color.white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.eventTitle)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(2)
            Text("Location: \(event.location)")
                .font(.footnote)
                .foregroundColor(.black)
        }
        .padding(.vertical, 8)
        .background(iuWhite)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(EventService())
} 