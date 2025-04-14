//
//  ContentView.swift
//  BloomingtonBuzz
//
//  Created by Ishan Apte on 4/11/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @StateObject private var eventService = EventService()
    
    @State private var selectedEvent: Event?
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedEventTypes: Set<EventType> = Set<EventType>(EventType.allCases)
    @State private var radiusFilter: Double = 2000 // Default to 2km
    @State private var selectedDate = Date()
    @State private var showPermissionDeniedAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map View
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
                        // Location status indicator for debugging
                        #if DEBUG
                        VStack {
                            if locationManager.location == nil {
                                Text("Location: Unknown")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            } else {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Location: \(locationManager.location!.coordinate.latitude), \(locationManager.location!.coordinate.longitude)")
                                        .font(.caption)
                                    
                                    if locationManager.useSimulatedLocation {
                                        Text("SIMULATED LOCATION")
                                            .font(.caption.bold())
                                            .foregroundColor(.orange)
                                    }
                                    
                                    // Debug controls
                                    HStack {
                                        Button("Toggle Sim") {
                                            locationManager.toggleSimulatedLocation()
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        
                                        if locationManager.useSimulatedLocation {
                                            Picker("Location", selection: Binding<String>(
                                                get: { "" },
                                                set: { locationManager.changeSimulationLocation(to: $0) }
                                            )) {
                                                Text("IU Bloomington").tag("IU Bloomington")
                                                Text("Wells Library").tag("Wells Library")
                                                Text("Assembly Hall").tag("Assembly Hall")
                                                Text("Sample Hall").tag("Sample Hall")
                                            }
                                            .pickerStyle(.menu)
                                            .scaleEffect(0.8)
                                        }
                                    }
                                }
                                .padding(6)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 60)
                        #endif
                    }
                    
                    // Center on me button
                    Button(action: {
                        // Use the new method to center map on user
                        locationManager.centerMapOnUser()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 270) // Position above the events list
                }
                
                // Bottom events list
                eventsListView
            }
            .navigationTitle("Campus Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: selectedDate) { oldValue, newValue in
                            Task {
                                await eventService.fetchEvents(for: newValue)
                            }
                        }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search events")
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
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedTypes: $selectedEventTypes, radiusFilter: $radiusFilter)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    // Events list at the bottom of the screen
    private var eventsListView: some View {
        VStack(spacing: 0) {
            // Handle state
            Group {
                if eventService.isLoading {
                    ProgressView("Loading events...")
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(.regularMaterial)
                } else if filteredEvents.isEmpty {
                    Text("No events found nearby")
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(.regularMaterial)
                } else {
                    // Events list
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
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal)
            .shadow(radius: 3)
        }
    }
    
    // Filter events based on search text, selected types, and radius
    private var filteredEvents: [Event] {
        var events = eventService.events
        
        // Filter by event type
        events = events.filter { selectedEventTypes.contains($0.eventType) }
        
        // Filter by search text
        if !searchText.isEmpty {
            events = events.filter { (event: Event) in
                event.eventTitle.localizedCaseInsensitiveContains(searchText) ||
                event.eventDescription.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by distance if we have user location
        if let userLocation = locationManager.location?.coordinate {
            events = events.filter { event in
                let eventLocation = CLLocation(latitude: event.coordinates.latitude, longitude: event.coordinates.longitude)
                let userLocationObj = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                return eventLocation.distance(from: userLocationObj) <= radiusFilter
            }
            
            // Sort by distance
            events.sort { event1, event2 in
                let location1 = CLLocation(latitude: event1.coordinates.latitude, longitude: event1.coordinates.longitude)
                let location2 = CLLocation(latitude: event2.coordinates.latitude, longitude: event2.coordinates.longitude)
                let userLocationObj = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                
                return location1.distance(from: userLocationObj) < location2.distance(from: userLocationObj)
            }
        } else {
            // Sort by start time if location not available
            events.sort { $0.startTime < $1.startTime }
        }
        
        return events
    }
}

// Row view for each event in the list
struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: event.eventType.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(event.eventType.color)
                .clipShape(Circle())
            
            // Event details
            VStack(alignment: .leading, spacing: 3) {
                Text(event.eventTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    // Start time
                    Text(formatTime(event.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Event type
                    Text(event.eventType.rawValue)
                        .font(.caption)
                        .foregroundColor(event.eventType.color)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
}
