import SwiftUI

// MARK: - ServerStatusIndicator
// Compact inline badge for TopHeaderBar.
// Shows: colored LED · HTTP:PORT · request count · click → open config

struct ServerStatusIndicator: View {

    private let srv = DealIngestionServer.shared

    // Callback so parent (TopHeaderBar) can present the config sheet.
    var onTap: () -> Void = {}

    // MARK: Tokens
    private let shellBorder  = Color(hex: "#2E333F")
    private let textTertiary = Color(hex: "#64748B")
    private let accentGreen  = Color(hex: "#10B981")
    private let accentRed    = Color(hex: "#EF4444")
    private let accentAmber  = Color(hex: "#F59E0B")
    private let shellSurface = Color(hex: "#1A1D24")

    // MARK: Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                // LED
                Circle()
                    .fill(srv.isRunning ? accentGreen : textTertiary)
                    .frame(width: 5, height: 5)

                // Label
                Text(srv.isRunning
                     ? "HTTP:\(srv.port)"
                     : "HTTP:OFF")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundColor(srv.isRunning ? accentGreen : textTertiary)

                // Request badge
                if srv.isRunning && srv.requestCount > 0 {
                    Text("\(srv.requestCount)")
                        .font(.custom("JetBrains Mono", size: 9))
                        .foregroundColor(accentAmber)
                        .padding(.horizontal, 4)
                        .background(accentAmber.opacity(0.12))
                        .clipShape(Rectangle())
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(shellSurface.opacity(srv.isRunning ? 1 : 0))
            .overlay(
                Rectangle()
                    .stroke(srv.isRunning ? accentGreen.opacity(0.25) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(srv.isRunning
              ? "Ingestion server running on localhost:\(srv.port) — \(srv.requestCount) requests"
              : "Ingestion server stopped — click to configure")
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        ServerStatusIndicator()
    }
    .padding(12)
    .background(Color(hex: "#0F1115"))
}
