import SwiftUI

struct FilterView: View {
    @Binding var selectedTypes: Set<EventType>
    @Binding var radiusFilter: Double
    @Environment(\.dismiss) private var dismiss
    
    private let radiusOptions: [Double] = [500, 1000, 2000, 5000] // In meters
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Event Type")) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button(action: {
                            toggleEventType(type)
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                
                                Text(type.rawValue)
                                
                                Spacer()
                                
                                if selectedTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button("Select All", role: selectedTypes.count == EventType.allCases.count ? .destructive : .none) {
                        if selectedTypes.count == EventType.allCases.count {
                            selectedTypes.removeAll()
                        } else {
                            selectedTypes = Set<EventType>(EventType.allCases)
                        }
                    }
                }
                
                Section(header: Text("Radius")) {
                    Picker("Show events within", selection: $radiusFilter) {
                        ForEach(radiusOptions, id: \.self) { radius in
                            Text(formatDistance(radius)).tag(radius)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filter Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedTypes = Set<EventType>(EventType.allCases)
                        radiusFilter = 2000 // Default to 2km
                    }
                }
            }
        }
    }
    
    private func toggleEventType(_ type: EventType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            let kilometers = meters / 1000
            return "\(Int(kilometers)) km"
        } else {
            return "\(Int(meters)) m"
        }
    }
} 