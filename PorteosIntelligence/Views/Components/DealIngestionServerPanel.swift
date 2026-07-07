import SwiftUI

// MARK: - DealIngestionServerPanel
//
// Terminal-block control panel for the local HTTP ingestion server.
// Observes DealIngestionServer.shared directly — no bindings needed.

struct DealIngestionServerPanel: View {

    // MARK: Tokens

    private let shellBg      = DesignTokens.canvasBase
    private let shellSurface = DesignTokens.surfacePanel
    private let shellBorder  = DesignTokens.dividerStructural
    private let tp1          = DesignTokens.textPrimary
    private let tp2          = DesignTokens.textSecondary
    private let tp3          = DesignTokens.textDim
    private let accentRust   = DesignTokens.accentRust
    private let green        = DesignTokens.statusGo
    private let red          = DesignTokens.statusCritical
    private let amber        = DesignTokens.statusReview

    private var server: DealIngestionServer { DealIngestionServer.shared }

    // MARK: Body

    var body: some View {
        TerminalBlock(command: "INGESTION_SERVER // CONTROL_PANEL", accentColor: accentRust) {
            VStack(alignment: .leading, spacing: 0) {
                statusRow
                divider
                endpointRow
                divider
                statsRow
                divider
                buttonRow
                if let err = server.errorMessage {
                    divider
                    errorRow(err)
                }
            }
        }
    }

    // MARK: – Rows

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(server.isRunning ? green : red)
                .frame(width: 8, height: 8)

            Text(server.isRunning ? "RUNNING" : "STOPPED")
                .porteosButtonPrimary()
                .foregroundStyle(server.isRunning ? green : red)

            Spacer()

            Text("localhost:\(server.port)")
                .porteosRowLabel()
                .foregroundStyle(tp2)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var endpointRow: some View {
        VStack(alignment: .leading, spacing: 3) {
            endpointLine("POST", "/api/deals",  "ingest deal JSON")
            endpointLine("GET",  "/api/health", "liveness check")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func endpointLine(_ method: String, _ path: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(method)
                .porteosMeta()
                .foregroundStyle(method == "POST" ? amber : green)
                .frame(width: 30, alignment: .leading)
            Text(path)
                .porteosMeta()
                .foregroundStyle(tp1)
            Text("// \(desc)")
                .porteosMeta()
                .foregroundStyle(tp3)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCell("REQUESTS", "\(server.requestCount)")
            statCell("PORT",     "\(server.port)")
            if let last = server.lastRequest {
                statCell("LAST_REQ", timeAgo(last))
            } else {
                statCell("LAST_REQ", "—")
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .porteosRowValue()
                .foregroundStyle(tp1)
                .monospacedDigit()
            Text(label)
                .porteosMeta()
                .foregroundStyle(tp3)
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 12) {
            if server.isRunning {
                Button("[ STOP_SERVER ]") { server.stop() }
                    .buttonStyle(TerminalButtonStyle(color: .red))

                Button("[ RESTART ]") { server.restart() }
                    .buttonStyle(TerminalButtonStyle(color: .amber))
            } else {
                Button("[ START_SERVER ]") { server.start() }
                    .buttonStyle(TerminalButtonStyle(color: .green))
            }
            Spacer()
        }
        .frame(height: 32)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func errorRow(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Text("!")
                .porteosMeta()
                .foregroundStyle(red)
            Text(msg)
                .porteosMeta()
                .foregroundStyle(red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    // MARK: – Helpers

    private func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60  { return "\(s)s ago" }
        if s < 3600 { return "\(s / 60)m ago" }
        return "\(s / 3600)h ago"
    }
}
