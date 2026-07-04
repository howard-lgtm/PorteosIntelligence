import SwiftUI

// MARK: - ServerStatusIndicator
// Compact LED badge for TopHeaderBar — HTTP:PORT · request count · tap → config.

struct ServerStatusIndicator: View {

    private let srv = DealIngestionServer.shared
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Circle()
                    .fill(srv.isRunning ? DesignTokens.statusGo : DesignTokens.textDim)
                    .frame(width: 5, height: 5)

                Text(srv.isRunning ? "HTTP:\(srv.port)" : "HTTP:OFF")
                    .porteosMeta()
                    .monospacedDigit()
                    .foregroundStyle(srv.isRunning ? DesignTokens.statusGo : DesignTokens.textDim)

                if srv.isRunning && srv.requestCount > 0 {
                    Text("\(srv.requestCount)")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusWarn)
                        .padding(.horizontal, 4)
                        .background(DesignTokens.statusWarn.opacity(0.12))
                        .clipShape(Rectangle())
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                srv.isRunning
                    ? DesignTokens.statusGo.opacity(0.10)
                    : Color.clear
            )
            .overlay(
                Rectangle()
                    .stroke(
                        srv.isRunning
                            ? DesignTokens.statusGo.opacity(0.25)
                            : Color.clear,
                        lineWidth: 1
                    )
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
    ServerStatusIndicator()
        .padding(12)
        .background(DesignTokens.canvasBase)
}
