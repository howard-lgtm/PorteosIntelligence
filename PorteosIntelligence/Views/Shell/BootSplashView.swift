import SwiftUI

// MARK: - BootSplashView
// Terminal boot animation shown on every launch. Auto-dismisses after ~2.5s.
// Tap anywhere to dismiss early. Onboarding/"don't show again" wired separately.

struct BootSplashView: View {

    var onDismiss: () -> Void

    // Sequential reveal of boot lines
    @State private var visibleLines: Int = 0
    @State private var showLogo:     Bool = false
    @State private var cursorOn:     Bool = true
    @State private var fading:       Bool = false

    private let bootLines: [String] = [
        "porteos@system ~ % ./boot --intelligence",
        "initialising deal engine...        OK",
        "loading market benchmarks...       OK",
        "starting geocoding service...      OK",
        "connecting LLM interface...        OK",
        "arming portfolio scanner...        OK",
        "porteos@system ~ % _",
    ]

    private let lineDelay: Double = 0.22   // seconds between each boot line
    private let holdDuration: Double = 0.7 // pause at end before fade

    var body: some View {
        ZStack {
            DesignTokens.canvasBase.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // ── Wordmark ─────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text("PORTEOS")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .tracking(8)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("INTELLIGENCE")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .tracking(6)
                        .foregroundStyle(DesignTokens.accentRust)
                }
                .opacity(showLogo ? 1 : 0)
                .padding(.bottom, 40)

                // ── Boot sequence ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(bootLines.prefix(visibleLines).enumerated()), id: \.offset) { idx, line in
                        let isLast = idx == bootLines.count - 1
                        HStack(spacing: 0) {
                            Text(line)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(
                                    isLast ? DesignTokens.accentRust
                                    : line.hasSuffix("OK") ? DesignTokens.statusGo
                                    : DesignTokens.textDim
                                )
                            if isLast {
                                Rectangle()
                                    .fill(DesignTokens.accentRust)
                                    .frame(width: 7, height: 13)
                                    .opacity(cursorOn ? 1 : 0)
                            }
                        }
                    }
                }

                Spacer()

                // ── Footer ────────────────────────────────────────────────────
                HStack {
                    Text("// PORTEOS INTELLIGENCE  v1.0")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(DesignTokens.textDim)
                    Spacer()
                    Text("tap to continue")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(DesignTokens.textDim)
                        .opacity(visibleLines >= bootLines.count ? 1 : 0)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 48)
        }
        .opacity(fading ? 0 : 1)
        .onTapGesture { dismiss() }
        .onAppear { startSequence() }
    }

    // MARK: - Sequence

    private func startSequence() {
        // Logo fades in first
        withAnimation(.easeIn(duration: 0.4)) { showLogo = true }

        // Blinking cursor
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { t in
            cursorOn.toggle()
            if fading { t.invalidate() }
        }

        // Reveal boot lines one by one
        for i in 0..<bootLines.count {
            let delay = 0.5 + Double(i) * lineDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: 0.1)) { visibleLines = i + 1 }
            }
        }

        // Auto-dismiss after all lines + hold
        let total = 0.5 + Double(bootLines.count) * lineDelay + holdDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + total) { dismiss() }
    }

    private func dismiss() {
        guard !fading else { return }
        withAnimation(.easeOut(duration: 0.45)) { fading = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDismiss() }
    }
}
