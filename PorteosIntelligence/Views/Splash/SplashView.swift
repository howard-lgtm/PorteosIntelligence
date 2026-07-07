import SwiftUI
import AppKit

// MARK: - SplashView
// Programmatic startup sequence per Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md

struct SplashView: View {

    var onFinished: () -> Void

    // MARK: Handoff timing

    private static let totalDuration: TimeInterval = 4.4
    private static let heroFadeEnd: TimeInterval = 0.7
    private static let typingStart: TimeInterval = 0.8
    private static let typingEnd: TimeInterval = 2.4
    private static let versionFadeStart: TimeInterval = 2.4
    private static let versionFadeDuration: TimeInterval = 0.4
    private static let progressFillEnd: TimeInterval = 2.9
    private static let charInterval: TimeInterval = 0.08
    private static let cursorBlinkPeriod: TimeInterval = 0.5

    private static let panelWidth: CGFloat = 720
    private static let panelHeight: CGFloat = 460
    private static let cornerRadius: CGFloat = 10
    private static let progressWidth: CGFloat = 640
    private static let progressHeight: CGFloat = 2
    private static let progressLeading: CGFloat = 40

    private static let titleText = "PORTEOS INTELLIGENCE"
    private static let versionText = "v2.06"

    private let rust       = Color(hex: "#C25E30")
    private let canvasBase = Color(hex: "#0A0A0A")
    private let textDim    = Color(hex: "#666666")
    private let trackColor = Color(hex: "#262626")

    @State private var startDate = Date()
    @State private var didFinish = false

    var body: some View {
        ZStack {
            canvasBase.ignoresSafeArea()

            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSince(startDate)
                let t = min(max(elapsed, 0), Self.totalDuration)

                splashContent(at: t)
                    .frame(width: Self.panelWidth, height: Self.panelHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            }
        }
        .onAppear {
            startDate = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.totalDuration) {
                finish()
            }
        }
    }

    // MARK: Panel content

    @ViewBuilder
    private func splashContent(at t: TimeInterval) -> some View {
        ZStack {
            canvasBase

            heroLayer(opacity: heroOpacity(at: t))

            // Title + version — centered in panel (Figma motion frame)
            VStack(spacing: 8) {
                typewriterRow(at: t)
                    .padding(.horizontal, 40)

                Text(Self.versionText)
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textDim)
                    .opacity(versionOpacity(at: t))
            }
            .frame(width: Self.panelWidth, height: Self.panelHeight)

            // Progress — pinned to handoff position y:428
            VStack {
                Spacer()
                progressBar(fraction: progressFraction(at: t))
                    .padding(.horizontal, Self.progressLeading)
                    .padding(.bottom, Self.panelHeight - 428 - Self.progressHeight)
            }
            .frame(width: Self.panelWidth, height: Self.panelHeight)
        }
    }

    // MARK: Hero

    @ViewBuilder
    private func heroLayer(opacity: Double) -> some View {
        if let image = Self.loadHeroImage(), opacity > 0.001 {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Self.panelWidth, height: Self.panelHeight)
                .clipped()
                .opacity(opacity)
        }
    }

    private func heroOpacity(at t: TimeInterval) -> Double {
        guard t < Self.heroFadeEnd else { return 0 }
        let x = t / Self.heroFadeEnd
        return 1 - easeIn(x)
    }

    // MARK: Typewriter + cursor

    private func typewriterRow(at t: TimeInterval) -> some View {
        let visible = visibleTitle(at: t)
        let showCursor = shouldShowCursor(at: t)
        let cursorAlpha = cursorOpacity(at: t, showCursor: showCursor)

        return HStack(spacing: 0) {
            Text(visible)
                .font(.custom("JetBrains Mono", size: 18))
                .tracking(3)
                .foregroundStyle(rust)

            Rectangle()
                .fill(rust)
                .frame(width: 10, height: 24)
                .opacity(cursorAlpha)
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity)
        .opacity(t >= 0.7 ? 1 : 0)
    }

    private func visibleTitle(at t: TimeInterval) -> String {
        guard t >= Self.typingStart else { return "" }
        let count = min(Self.titleText.count, Int((t - Self.typingStart) / Self.charInterval) + 1)
        return String(Self.titleText.prefix(max(count, 0)))
    }

    private func shouldShowCursor(at t: TimeInterval) -> Bool {
        if t >= 0.7 && t < Self.typingEnd {
            return true
        }
        if t >= Self.typingEnd {
            return true
        }
        return false
    }

    private func cursorOpacity(at t: TimeInterval, showCursor: Bool) -> Double {
        guard showCursor else { return 0 }

        if t >= Self.typingStart && t < Self.typingEnd {
            let typed = visibleTitle(at: t).count
            if typed < Self.titleText.count {
                return 1
            }
        }

        let phase = t.truncatingRemainder(dividingBy: Self.cursorBlinkPeriod)
        let half = Self.cursorBlinkPeriod / 2
        if phase < half {
            return 1 - (phase / half)
        }
        return (phase - half) / half
    }

    // MARK: Version + progress

    private func versionOpacity(at t: TimeInterval) -> Double {
        guard t >= Self.versionFadeStart else { return 0 }
        let x = min(1, (t - Self.versionFadeStart) / Self.versionFadeDuration)
        return easeOut(x)
    }

    private func progressBar(fraction: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(trackColor)
                .frame(height: Self.progressHeight)

            Rectangle()
                .fill(rust.opacity(0.6))
                .frame(width: Self.progressWidth * min(max(fraction, 0), 1), height: Self.progressHeight)
        }
        .frame(width: Self.progressWidth, height: Self.progressHeight, alignment: .leading)
    }

    private func progressFraction(at t: TimeInterval) -> CGFloat {
        if t <= 0 { return 0 }
        if t < Self.typingStart {
            let x = t / Self.typingStart
            return CGFloat(easeOut(x) * 0.10)
        }
        if t < Self.typingEnd {
            let x = (t - Self.typingStart) / (Self.typingEnd - Self.typingStart)
            return CGFloat(0.10 + x * (0.92 - 0.10))
        }
        if t < Self.progressFillEnd {
            let x = (t - Self.typingEnd) / (Self.progressFillEnd - Self.typingEnd)
            return CGFloat(0.92 + easeOut(x) * (1.0 - 0.92))
        }
        return 1
    }

    // MARK: Easing

    private func easeIn(_ x: Double) -> Double { x * x }
    private func easeOut(_ x: Double) -> Double { 1 - (1 - x) * (1 - x) }

    // MARK: Finish

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }

    // MARK: Asset loading

    private static let heroResourceNames = ["porteos_splash_000", "splash-hero@2x", "splash-hero"]

    private static func loadHeroImage() -> NSImage? {
        for name in heroResourceNames {
            if let url = heroImageURL(named: name),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }
        return nil
    }

    /// Xcode file-system sync copies `PorteosIntelligence/Resources/Splash/` into the
    /// bundle as `Resources/Splash/` — not top-level `Splash/`. Try several layouts.
    private static func heroImageURL(named name: String) -> URL? {
        let subdirectories = ["Resources/Splash", "Splash", nil as String?]
        for subdir in subdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdir) {
                return url
            }
        }

        guard let base = Bundle.main.resourceURL else { return nil }
        let relativePaths = [
            "Resources/Splash/\(name).png",
            "Splash/\(name).png",
            "\(name).png",
        ]
        for path in relativePaths {
            let url = base.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }
}

#Preview {
    SplashView(onFinished: {})
        .frame(width: 900, height: 700)
}
