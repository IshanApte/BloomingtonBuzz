import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTags: Set<String>
    
    private let iuRed = Color(red: 152/255, green: 0/255, blue: 0/255)
    private let iuRedLight = Color(red: 179/255, green: 27/255, blue: 27/255)
    private let iuWhite = Color.white
    
    // Define available tags
    private let availableTags = [
        "Free Food",
        "Indoor",
        "Outdoor",
        "Community Engagement",
        "Welcome Week",
        "Admissions"
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Event Tags")) {
                    ForEach(availableTags, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                    .foregroundColor(iuRed)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                        }
                    }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedTags.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FilterView(selectedTags: .constant(Set<String>()))
} 