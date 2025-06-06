import SwiftUI

struct MainView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var eventService: EventService
    @StateObject private var storageManager = AppStorageManager.shared
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    
    var body: some View {
        if isOnboardingComplete {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(eventService)
                .onAppear {
                    // Record app opened for analytics
                    storageManager.recordAppOpened()
                }
        } else {
            OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                .onAppear {
                    // Pre-load location manager so it's ready when the user completes onboarding
                    locationManager.checkLocationAuthorization()
                }
        }
    }
    
    // Debug function to reset onboarding (for testing)
    private func resetOnboarding() {
        isOnboardingComplete = false
        AppStorageManager.shared.resetOnboarding()
    }
}

#Preview {
    MainView()
        .environmentObject(LocationManager())
} 