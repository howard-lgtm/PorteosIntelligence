import SwiftUI

// MARK: - ServerConfigSheet

struct ServerConfigSheet: View {

    @Environment(\.dismiss) private var dismiss
    private let srv = DealIngestionServer.shared

    @State private var portString = "9000"
    @State private var portError:  String?

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textPrimary   = Color(hex: "#E2E8F0")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentRust    = Color(hex: "#C25E30")
    private let accentGreen   = Color(hex: "#10B981")
    private let accentRed     = Color(hex: "#EF4444")
    private let accentAmber   = Color(hex: "#F59E0B")
    private let accentBlue    = Color(hex: "#3B82F6")

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 8) {
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
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 600, height: 700)
        .onAppear { portString = String(srv.port) }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("DEAL_INGESTION_SERVER")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundColor(textTertiary)
            Spacer()
            // Live status pill
            HStack(spacing: 5) {
                Circle()
                    .fill(srv.isRunning ? accentGreen : textTertiary)
                    .frame(width: 5, height: 5)
                Text(srv.isRunning ? "RUNNING" : "STOPPED")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundColor(srv.isRunning ? accentGreen : textTertiary)
            }
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background((srv.isRunning ? accentGreen : textTertiary).opacity(0.10))
            .clipShape(Rectangle())
            Button { dismiss() } label: {
                Text("[ CLOSE ]")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundColor(textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(shellSurface)
        .overlay(alignment: .bottom) { Rectangle().fill(shellBorder).frame(height: 1) }
    }

    // MARK: - Status block

    private var statusBlock: some View {
        TerminalBlock(command: "01 // STATUS", accentColor: srv.isRunning ? accentGreen : textTertiary) {
            VStack(spacing: 0) {
                metricRow("BIND_ADDRESS",  "127.0.0.1 (localhost only)")
                divider
                metricRow("PORT",          String(srv.port))
                divider
                metricRow("REQUESTS",      "\(srv.requestCount)")
                divider
                metricRow("LAST_REQUEST",  srv.lastRequest.map { relativeTime($0) } ?? "—")
                if let err = srv.errorMessage {
                    divider
                    HStack {
                        Text("ERROR")
                            .font(.custom("JetBrains Mono", size: 10))
                            .foregroundColor(textTertiary)
                            .frame(width: 100, alignment: .leading)
                        Text(err)
                            .font(.custom("JetBrains Mono", size: 10))
                            .foregroundColor(accentRed)
                            .lineLimit(3)
                    }
                    .frame(minHeight: 28).padding(.horizontal, 0)
                }
            }
        }
    }

    // MARK: - Config block

    private var configBlock: some View {
        TerminalBlock(command: "02 // CONFIGURATION", accentColor: accentRust) {
            VStack(spacing: 0) {
                HStack {
                    Text("PORT")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundColor(textTertiary)
                        .frame(width: 100, alignment: .leading)
                    TextField("9000", text: $portString)
                        .textFieldStyle(.plain)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textPrimary)
                        .frame(width: 80)
                    if let err = portError {
                        Text(err)
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundColor(accentRed)
                    }
                    Spacer()
                    Text("1024–65535")
                        .font(.custom("JetBrains Mono", size: 9))
                        .foregroundColor(textTertiary)
                }
                .frame(height: 28)
            }
        }
    }

    // MARK: - Endpoints block

    private var endpointsBlock: some View {
        TerminalBlock(command: "03 // ENDPOINTS", accentColor: accentBlue) {
            VStack(spacing: 0) {
                endpointRow(method: "POST", path: "/api/deals",   note: "Ingest a deal from JSON payload")
                divider
                endpointRow(method: "GET",  path: "/api/health",  note: "Health-check; returns server info")
                divider
                endpointRow(method: "OPT",  path: "/api/deals",   note: "CORS pre-flight (browser XHR)")
            }
        }
    }

    private func endpointRow(method: String, path: String, note: String) -> some View {
        HStack(spacing: 8) {
            Text(method)
                .font(.custom("JetBrains Mono", size: 9).weight(.bold))
                .foregroundColor(method == "POST" ? accentAmber : (method == "GET" ? accentGreen : textTertiary))
                .frame(width: 32, alignment: .leading)
            Text("localhost:\(srv.port)\(path)")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(textPrimary)
            Spacer()
            Text(note)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textTertiary)
        }
        .frame(height: 28)
    }

    // MARK: - Browser extension block

    private var extensionBlock: some View {
        TerminalBlock(command: "04 // BROWSER_EXTENSION", accentColor: accentBlue) {
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

    // MARK: - Request log block

    private var logBlock: some View {
        TerminalBlock(command: "05 // REQUEST_LOG", accentColor: textTertiary) {
            VStack(spacing: 0) {
                ForEach(Array(srv.recentLogs.prefix(15).enumerated()), id: \.element.id) { i, log in
                    if i > 0 { divider }
                    logRow(log)
                }
            }
        }
    }

    private func logRow(_ log: IngestLog) -> some View {
        HStack(spacing: 6) {
            // Timestamp
            Text(shortTime(log.timestamp))
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textTertiary)
                .frame(width: 44, alignment: .leading)
            // Method
            Text(log.method)
                .font(.custom("JetBrains Mono", size: 9).weight(.bold))
                .foregroundColor(log.method == "POST" ? accentAmber : textTertiary)
                .frame(width: 32, alignment: .leading)
            // Status code
            Text(String(log.statusCode))
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(log.statusCode < 300 ? accentGreen : accentRed)
                .frame(width: 28, alignment: .leading)
            // Source
            Text(log.source)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(accentBlue)
                .frame(width: 72, alignment: .leading)
            // Deal name
            Text(log.dealName)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .frame(height: 22)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            Spacer()

            if srv.isRunning {
                Button {
                    srv.stop()
                } label: {
                    Text("[ STOP_SERVER ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(accentRed)
                        .frame(height: 32).padding(.horizontal, 12)
                        .background(shellSurface)
                        .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    applyPortAndStart()
                } label: {
                    Text("[ START_SERVER ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textPrimary)
                        .frame(height: 32).padding(.horizontal, 14)
                        .background(accentGreen)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if srv.isRunning {
                Button {
                    applyPortAndStart()   // restart on new port
                } label: {
                    Text("[ RESTART ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textSecondary)
                        .frame(height: 32).padding(.horizontal, 12)
                        .background(shellSurface)
                        .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(shellSurface)
        .overlay(alignment: .top) { Rectangle().fill(shellBorder).frame(height: 1) }
    }

    // MARK: - Small helpers

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    private func metricRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(textTertiary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundColor(textPrimary)
            Spacer()
        }
        .frame(height: 28)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 9))
            .foregroundColor(textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 1)
    }

    private func codeBlock(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 9))
            .foregroundColor(Color(hex: "#A8B5C8"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color(hex: "#0A0D11"))
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
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

// MARK: - Preview

#Preview {
    ServerConfigSheet()
}
