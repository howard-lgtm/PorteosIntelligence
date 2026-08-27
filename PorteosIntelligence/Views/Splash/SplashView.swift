import SwiftUI
import AppKit

// MARK: - SplashView
// Plays a PNG frame sequence from Resources/Splash/ on app launch.
// Update frameCount and fps when Figma handoff is final — see
// Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md

struct SplashView: View {

    var onFinished: () -> Void

    // MARK: Config — update from STARTUP_ANIMATION_HANDOFF.md
    private static let frameCount: Int = 1
    private static let fps: Double = 24
    private static let minimumDuration: TimeInterval = 1.0
    private static let fadeOutDuration: TimeInterval = 0.35
    private static let subdirectory = "Splash"
    private static let namePrefix = "porteos_splash_"

    @State private var frameIndex = 0
    @State private var opacity: Double = 1
    @State private var timer: Timer?
    @State private var loadedFrameCount = 0

    private let shellBg = Color(hex: "#0F1115")

    var body: some View {
        ZStack {
            shellBg.ignoresSafeArea()

            if let image = frameImage(at: frameIndex) {
                Image(nsImage: image)
                    .interpolation(.high)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                fallbackContent
            }
        }
        .opacity(opacity)
        .onAppear(perform: begin)
        .onDisappear { timer?.invalidate() }
    }

    // MARK: Fallback when frames are not yet in bundle

    private var fallbackContent: some View {
        VStack(spacing: 8) {
            Text("PORTEOS@SYSTEM")
                .font(.custom("JetBrains Mono", size: 24).weight(.bold))
                .foregroundStyle(Color(hex: "#F8F9FA"))
            Text("INITIALISING…")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(Color(hex: "#64748B"))
        }
    }

    // MARK: Playback

    private func begin() {
        loadedFrameCount = countAvailableFrames()
        guard loadedFrameCount > 1 else {
            // Single frame or none — hold briefly then dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.minimumDuration) {
                dismiss()
            }
            return
        }

        let interval = 1.0 / Self.fps
        let start = Date()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            let next = frameIndex + 1
            if next >= loadedFrameCount {
                t.invalidate()
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, Self.minimumDuration - elapsed)
                DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                    dismiss()
                }
            } else {
                frameIndex = next
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: Self.fadeOutDuration)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeOutDuration) {
            onFinished()
        }
    }

    // MARK: Bundle loading

    private func frameImage(at index: Int) -> NSImage? {
        let name = String(format: "%@%03d", Self.namePrefix, index)
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "png",
            subdirectory: Self.subdirectory
        ) else { return nil }
        return NSImage(contentsOf: url)
    }

    private func countAvailableFrames() -> Int {
        var count = 0
        while frameImage(at: count) != nil {
            count += 1
        }
        return count
    }
}

#Preview {
    SplashView(onFinished: {})
        .frame(width: 800, height: 600)
}
