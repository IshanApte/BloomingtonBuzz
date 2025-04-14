import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    
    // IU Colors
    private let iuRed = Color(red: 152/255, green: 0/255, blue: 0/255) // #980000
    private let iuWhite = Color.white
    
    let pages = [
        OnboardingPage(
            title: "Welcome to BloomingtonBuzz",
            description: "Your ultimate guide to discovering events around Indiana University Bloomington",
            imageName: "map.fill",
            systemImage: true
        ),
        OnboardingPage(
            title: "Find Campus Events",
            description: "Discover academic, cultural, and social events happening all around campus",
            imageName: "calendar",
            systemImage: true
        ),
        OnboardingPage(
            title: "Nearby Events",
            description: "Enable location services to find events close to you",
            imageName: "location.circle.fill",
            systemImage: true
        ),
        OnboardingPage(
            title: "Filter & Search",
            description: "Easily find events that interest you with powerful filtering options",
            imageName: "line.3.horizontal.decrease.circle.fill",
            systemImage: true
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            iuRed.ignoresSafeArea()
            
            VStack {
                // IU Logo Area
                HStack {
                    Text("IU")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                    
                    Text("BloomingtonBuzz")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], iuRed: iuRed)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Spacer()
                
                // Next Button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        isOnboardingComplete = true
                        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .foregroundColor(iuRed)
                    .frame(width: 200, height: 50)
                    .background(iuWhite)
                    .cornerRadius(25)
                    .shadow(radius: 5)
                }
                .padding(.bottom, 20)
                
                // Skip Button
                if currentPage < pages.count - 1 {
                    Button(action: {
                        isOnboardingComplete = true
                        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 40)
                } else {
                    // Spacer for the last page where skip isn't shown
                    Spacer().frame(height: 60)
                }
            }
        }
    }
}

struct OnboardingPage: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var imageName: String
    var systemImage: Bool = true
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let iuRed: Color
    
    var body: some View {
        VStack(spacing: 30) {
            if page.systemImage {
                Image(systemName: page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.white)
                    .padding(.top, 50)
            } else {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 50)
            }
            
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
} 