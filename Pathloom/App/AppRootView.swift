import SwiftUI

enum RootPhase {
    case splash
    case onboarding
    case home
}

struct AppRootView: View {
    @Environment(AppServices.self) private var services
    @AppStorage("pathloom.didOnboard") private var didOnboard = false
    @State private var phase: RootPhase = .splash

    var body: some View {
        ZStack {
            PathloomPalette.background.ignoresSafeArea()
            switch phase {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = didOnboard ? .home : .onboarding
                    }
                }
            case .onboarding:
                OnboardingView {
                    didOnboard = true
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = .home
                    }
                }
            case .home:
                HomeView()
            }
        }
        .tint(PathloomPalette.primary)
    }
}
