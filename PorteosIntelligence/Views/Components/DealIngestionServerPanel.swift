import SwiftUI

// MARK: - DealIngestionServerPanel
//
// Terminal-block control panel for the local HTTP ingestion server.
// Observes DealIngestionServer.shared directly — no bindings needed.

struct DealIngestionServerPanel: View {

    // MARK: Tokens

    private let shellBg      = Color(hex: "#0F1115")
    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let tp1          = Color(hex: "#F8F9FA")
    private let tp2          = Color(hex: "#94A3B8")
    private let tp3          = Color(hex: "#64748B")
    private let accentRust   = Color(hex: "#C25E30")
    private let green        = Color(hex: "#10B981")
    private let red          = Color(hex: "#EF4444")
    private let amber        = Color(hex: "#F59E0B")

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
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(server.isRunning ? green : red)

            Spacer()

            Text("localhost:\(server.port)")
                .font(.custom("JetBrains Mono", size: 11))
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
                .font(.custom("JetBrains Mono", size: 9).weight(.bold))
                .foregroundStyle(method == "POST" ? amber : green)
                .frame(width: 30, alignment: .leading)
            Text(path)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundStyle(tp1)
            Text("// \(desc)")
                .font(.custom("JetBrains Mono", size: 9))
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
                .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                .foregroundStyle(tp1)
                .monospacedDigit()
            Text(label)
                .font(.custom("JetBrains Mono", size: 9))
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
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(red)
            Text(msg)
                .font(.custom("JetBrains Mono", size: 10))
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
