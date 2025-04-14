import Foundation
import SwiftUI

// MARK: - AppStorageManager
// This class is used to manage app-wide storage using @AppStorage
class AppStorageManager: ObservableObject {
    static let shared = AppStorageManager()
    
    // Keys used for storage
    enum StorageKeys: String {
        case isOnboardingComplete = "isOnboardingComplete"
        case lastOpenedDate = "lastOpenedDate"
        case locationPermissionRequested = "locationPermissionRequested"
        case userPreferredEventTypes = "userPreferredEventTypes"
    }
    
    // Reset all onboarding flags (used for testing)
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: StorageKeys.isOnboardingComplete.rawValue)
    }
    
    // Reset everything (for troubleshooting)
    func resetAllSettings() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    // Record that the app has been opened
    func recordAppOpened() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        UserDefaults.standard.set(dateString, forKey: StorageKeys.lastOpenedDate.rawValue)
    }
    
    // Check if onboarding has been completed
    var isOnboardingComplete: Bool {
        get {
            return UserDefaults.standard.bool(forKey: StorageKeys.isOnboardingComplete.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: StorageKeys.isOnboardingComplete.rawValue)
        }
    }
    
    // Check if location permission has been requested
    var locationPermissionRequested: Bool {
        get {
            return UserDefaults.standard.bool(forKey: StorageKeys.locationPermissionRequested.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: StorageKeys.locationPermissionRequested.rawValue)
        }
    }
}

// MARK: - AppStorage Property Wrapper Extensions
// These extensions provide easy access to common app storage values
extension View {
    // Helper to quickly access onboarding status
    func onboardingCompleted(_ isComplete: Bool) {
        UserDefaults.standard.set(isComplete, forKey: AppStorageManager.StorageKeys.isOnboardingComplete.rawValue)
    }
} 