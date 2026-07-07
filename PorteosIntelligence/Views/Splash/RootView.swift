import SwiftUI

// MARK: - RootView
// Splash overlay → AppShell. PorteosIntelligenceApp mounts this at launch.

struct RootView: View {

    @State private var showSplash = true

    var body: some View {
        ZStack {
            AppShell()

            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.35)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.35), value: showSplash)
    }
}

#Preview {
    RootView()
        .modelContainer(for: PropertyDeal.self, inMemory: true)
}
