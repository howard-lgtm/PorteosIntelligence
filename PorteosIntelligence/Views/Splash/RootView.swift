import SwiftUI
import SwiftData

// MARK: - RootView
// Coordinates startup splash overlay → main AppShell.
// PorteosIntelligenceApp mounts this instead of AppShell directly.

struct RootView: View {

    @State private var showSplash = true

    var body: some View {
        ZStack {
            AppShell()

            if showSplash {
                SplashView {
                    showSplash = false
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
