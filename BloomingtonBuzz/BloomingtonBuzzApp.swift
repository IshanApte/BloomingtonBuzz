//
//  BloomingtonBuzzApp.swift
//  BloomingtonBuzz
//
//  Created by Ishan Apte on 4/11/25.
//

import SwiftUI
import CoreLocation

@main
struct BloomingtonBuzzApp: App {
    // Initialize managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var storageManager = AppStorageManager.shared
    
    init() {
        print("📱 App initializing...")
        
        // Register for user defaults to help with debugging
        UserDefaults.standard.register(defaults: [
            "ShowLocationDebugging": true,
            "isOnboardingComplete": false // Default to showing onboarding
        ])
        
        // For debugging - uncomment to reset onboarding on each launch
        // AppStorageManager.shared.resetOnboarding()
        
        // Note: The NSLocationWhenInUseUsageDescription should be set in the project's Info settings
        // To fix the current Info.plist conflict error:
        // 1. Delete any manually created Info.plist files
        // 2. In Xcode, select the project target, go to "Info" tab
        // 3. Add the key "Privacy - Location When In Use Usage Description" with appropriate value
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(locationManager)
                .environmentObject(storageManager)
                .onAppear {
                    // Record app launch
                    storageManager.recordAppOpened()
                    
                    // Request location permission when app appears
                    print("📱 App appeared - requesting location authorization")
                    locationManager.checkLocationAuthorization()
                    
                    // Start location updates immediately
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        locationManager.startUpdatingLocation()
                    }
                }
        }
    }
}
