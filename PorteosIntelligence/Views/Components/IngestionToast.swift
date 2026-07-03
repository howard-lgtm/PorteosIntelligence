import SwiftUI

// MARK: - IngestionToastData

struct IngestionToastData: Identifiable {
    let id           = UUID()
    let dealID:       UUID
    let propertyName: String
    let location:     String
    let price:        Double
    let source:       String
    let isDuplicate:  Bool
}

// MARK: - ToastManager

@Observable @MainActor
final class ToastManager {
    static let shared = ToastManager()
    private init() {}

    var current: IngestionToastData?

    func show(_ toast: IngestionToastData) {
        current = toast
        Task {
            try? await Task.sleep(for: .seconds(4))
            if current?.id == toast.id { current = nil }
        }
    }

    func dismiss() { current = nil }
}

// MARK: - IngestionToastView

struct IngestionToastView: View {

    let toast: IngestionToastData
    var onSelectDeal: () -> Void = {}

    @State private var progress: Double = 1.0
    @State private var hovered           = false

    // MARK: Tokens

    private let shellBg      = DesignTokens.canvasBase
    private let shellSurface = DesignTokens.surfacePanel
    private let shellBorder  = DesignTokens.dividerStructural
    private let textPrimary  = Color(hex: "#E2E8F0")
    private let textSecondary = DesignTokens.textSecondary
    private let textTertiary = DesignTokens.textDim
    private let accentGreen  = DesignTokens.statusGo
    private let accentAmber  = Color(hex: "#F59E0B")
    private let accentRust   = DesignTokens.accentRust
    private let accentBlue   = Color(hex: "#3B82F6")

    private var stateColor: Color {
        toast.isDuplicate ? accentAmber : accentGreen
    }

    private var stateLabel: String {
        toast.isDuplicate ? "DUPLICATE" : "IMPORTED"
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            // ── Header line ──────────────────────────────────────────────────
            HStack(spacing: 0) {
                Text("porteos@system ~ % ingestion --notify")
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundColor(textTertiary)
                Spacer()
                Button {
                    ToastManager.shared.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(shellBg)

            Rectangle().fill(shellBorder).frame(height: 1)

            // ── Body ─────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("[ \(stateLabel) ]")
                        .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                        .foregroundColor(stateColor)
                    Text(toast.propertyName)
                        .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if !toast.location.isEmpty {
                        Text(toast.location)
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundColor(textSecondary)
                    }
                    if toast.price > 0 {
                        Text("·")
                            .foregroundColor(textTertiary)
                        Text(formatPrice(toast.price))
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundColor(textSecondary)
                    }
                }

                Text("source:\(toast.source)")
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundColor(textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(shellSurface)

            Rectangle().fill(shellBorder).frame(height: 1)

            // ── Footer: action + progress drain ──────────────────────────────
            HStack(spacing: 0) {
                Button {
                    ToastManager.shared.dismiss()
                    onSelectDeal()
                } label: {
                    Text("[ OPEN_DEAL ]")
                        .font(.custom("JetBrains Mono", size: 9).weight(.bold))
                        .foregroundColor(accentBlue)
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(accentBlue.opacity(0.10))
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                // Draining progress bar (3 s)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(shellBorder)
                            .frame(height: 2)
                        Rectangle()
                            .fill(stateColor.opacity(0.6))
                            .frame(width: geo.size.width * progress, height: 2)
                            .animation(.linear(duration: 3.0), value: progress)
                    }
                    .frame(height: 2)
                    .frame(maxHeight: .infinity)
                }
                .frame(width: 60, height: 20)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(shellBg)
        }
        .frame(width: 280)
        .overlay(
            Rectangle()
                .stroke(stateColor.opacity(hovered ? 0.5 : 0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .onHover { hovered = $0 }
        .onAppear {
            // Kick the drain animation
            Task {
                try? await Task.sleep(for: .milliseconds(50))
                progress = 0.0
            }
        }
    }

    private func formatPrice(_ value: Double) -> String {
        if value >= 1_000_000 { return "€\(String(format: "%.2f", value / 1_000_000))M" }
        return "€\(Int(value).formatted())"
    }
}

// MARK: - Preview

#Preview {
    IngestionToastView(
        toast: IngestionToastData(
            dealID: UUID(),
            propertyName: "Casa Breiner",
            location: "Lisbon",
            price: 350_000,
            source: "idealista",
            isDuplicate: false
        )
    )
    .padding(20)
    .background(DesignTokens.canvasBase)
}
