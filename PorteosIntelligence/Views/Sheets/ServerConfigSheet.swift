import SwiftUI

// MARK: - ServerConfigSheet

struct ServerConfigSheet: View {

    @Environment(\.dismiss) private var dismiss
    private let srv = DealIngestionServer.shared

    @State private var portString = "9000"
    @State private var portError:  String?

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: DesignTokens.blockSpacing) {
                    statusBlock
                    configBlock
                    endpointsBlock
                    extensionBlock
                    if !srv.recentLogs.isEmpty { logBlock }
                }
                .padding(12)
            }
            actionBar
        }
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
        .frame(width: 600, height: 700)
        .onAppear { portString = String(srv.port) }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
            Text("deal_ingestion_server --config")
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.accentRust)
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(srv.isRunning ? DesignTokens.statusGo : DesignTokens.textDim)
                    .frame(width: 5, height: 5)
                Text(srv.isRunning ? "RUNNING" : "STOPPED")
                    .porteosMeta()
                    .foregroundStyle(srv.isRunning ? DesignTokens.statusGo : DesignTokens.textDim)
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background((srv.isRunning ? DesignTokens.statusGo : DesignTokens.textDim).opacity(0.10))
            .clipShape(Rectangle())
            Button { dismiss() } label: {
                Text("[ CLOSE ]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
        .overlay(alignment: .bottom) { TerminalStructuralDivider() }
    }

    // MARK: Status block

    private var statusBlock: some View {
        TerminalBlock(command: "01 // STATUS",
                      accentColor: srv.isRunning ? DesignTokens.statusGo : DesignTokens.textDim,
                      contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalKeyValueRow(label: "BIND_ADDRESS", value: "127.0.0.1 (localhost only)")
                TerminalStructuralDivider()
                TerminalKeyValueRow(label: "PORT", value: String(srv.port))
                TerminalStructuralDivider()
                TerminalKeyValueRow(label: "REQUESTS", value: "\(srv.requestCount)")
                TerminalStructuralDivider()
                TerminalKeyValueRow(label: "LAST_REQUEST",
                                    value: srv.lastRequest.map { relativeTime($0) } ?? "—")
                if let err = srv.errorMessage {
                    TerminalStructuralDivider()
                    HStack {
                        Text("ERROR")
                            .porteosModuleCmd()
                            .foregroundStyle(DesignTokens.textDim)
                            .frame(width: 100, alignment: .leading)
                        Text(err)
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.statusCritical)
                            .lineLimit(3)
                        Spacer()
                    }
                    .frame(minHeight: DesignTokens.rowHeightData)
                    .padding(.horizontal, DesignTokens.cellInternalPadding)
                }
            }
        }
    }

    // MARK: Config block

    private var configBlock: some View {
        TerminalBlock(command: "02 // CONFIGURATION", accentColor: DesignTokens.accentRust, contentPadding: 12) {
            HStack {
                Text("PORT")
                    .porteosModuleCmd()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: 100, alignment: .leading)
                TextField("9000", text: $portString)
                    .textFieldStyle(.plain)
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .frame(width: 80)
                if let err = portError {
                    Text(err)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusCritical)
                }
                Spacer()
                Text("1024–65535")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .frame(height: DesignTokens.rowHeightData)
        }
    }

    // MARK: Endpoints block

    private var endpointsBlock: some View {
        TerminalBlock(command: "03 // ENDPOINTS",
                      accentColor: ProfileType.circular.accentColor,
                      contentPadding: 12) {
            VStack(spacing: 0) {
                endpointRow(method: "POST", path: "/api/deals",   note: "Ingest a deal from JSON payload")
                TerminalStructuralDivider()
                endpointRow(method: "GET",  path: "/api/health",  note: "Health-check; returns server info")
                TerminalStructuralDivider()
                endpointRow(method: "OPT",  path: "/api/deals",   note: "CORS pre-flight (browser XHR)")
            }
        }
    }

    private func endpointRow(method: String, path: String, note: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(method)
                .porteosMeta()
                .foregroundStyle(methodColor(method))
                .frame(width: 32, alignment: .leading)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text("localhost:\(srv.port)\(path)")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                Text(note)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .frame(minHeight: DesignTokens.rowHeightData)
    }

    private func methodColor(_ method: String) -> Color {
        switch method {
        case "POST": return DesignTokens.statusWarn
        case "GET":  return DesignTokens.statusGo
        default:     return DesignTokens.textDim
        }
    }

    // MARK: Browser extension block

    private var extensionBlock: some View {
        TerminalBlock(command: "04 // BROWSER_EXTENSION",
                      accentColor: ProfileType.circular.accentColor,
                      contentPadding: 12) {
            VStack(alignment: .leading, spacing: 4) {
                note("Send from your browser extension or any HTTP client:")
                codeBlock("""
POST http://localhost:\(srv.port)/api/deals
Content-Type: application/json

{
  "source": "idealista",
  "url": "https://...",
  "propertyName": "Casa Breiner",
  "locationCity": "Lisbon",
  "purchasePrice": 350000,
  "totalArea": 90,
  "bedrooms": 2
}
""")
                note("Response:  { \"success\": true, \"dealID\": \"<uuid>\" }")
                note("All deals are saved with STATUS = PIPELINE and tagged [browser_import].")
            }
        }
    }

    // MARK: Request log block

    private var logBlock: some View {
        TerminalBlock(command: "05 // REQUEST_LOG", accentColor: DesignTokens.textDim, contentPadding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(srv.recentLogs.prefix(15).enumerated()), id: \.element.id) { i, log in
                    if i > 0 { TerminalStructuralDivider() }
                    logRow(log)
                }
            }
        }
    }

    private func logRow(_ log: IngestLog) -> some View {
        HStack(spacing: 6) {
            Text(shortTime(log.timestamp))
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 44, alignment: .leading)
            Text(log.method)
                .porteosMeta()
                .foregroundStyle(methodColor(log.method))
                .frame(width: 32, alignment: .leading)
            Text(String(log.statusCode))
                .porteosMeta()
                .foregroundStyle(log.statusCode < 300 ? DesignTokens.statusGo : DesignTokens.statusCritical)
                .frame(width: 28, alignment: .leading)
            Text(log.source)
                .porteosMeta()
                .foregroundStyle(ProfileType.circular.accentColor)
                .frame(width: 72, alignment: .leading)
            Text(log.dealName)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .frame(height: 22)
        .padding(.horizontal, DesignTokens.cellInternalPadding)
    }

    // MARK: Action bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            Spacer()
            if srv.isRunning {
                Button("[ STOP_SERVER ]") { srv.stop() }
                    .buttonStyle(TerminalButtonStyle(outlined: .red))
                Button("[ RESTART ]") { applyPortAndStart() }
                    .buttonStyle(TerminalButtonStyle(outlined: .muted))
            } else {
                Button("[ START_SERVER ]") { applyPortAndStart() }
                    .buttonStyle(TerminalButtonStyle(color: .green))
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 8)
        .background(DesignTokens.surfacePanel)
        .overlay(alignment: .top) { TerminalStructuralDivider() }
    }

    // MARK: Helpers

    private func note(_ text: String) -> some View {
        Text(text)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 1)
    }

    private func codeBlock(_ text: String) -> some View {
        Text(text)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(DesignTokens.canvasBase)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(DesignTokens.dividerStructural, lineWidth: 1))
    }

    private func applyPortAndStart() {
        portError = nil
        guard let p = UInt16(portString), p >= 1024 else {
            portError = "Port must be 1024–65535"
            return
        }
        srv.start(on: p)
    }

    private func relativeTime(_ date: Date) -> String {
        let secs = Int(-date.timeIntervalSinceNow)
        if secs < 60  { return "\(secs)s ago" }
        if secs < 3600 { return "\(secs / 60)m ago" }
        return "\(secs / 3600)h ago"
    }

    private func shortTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }
}

#Preview {
    ServerConfigSheet()
}
