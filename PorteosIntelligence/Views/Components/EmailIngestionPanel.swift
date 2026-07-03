import SwiftUI

// MARK: - EmailIngestionPanel
//
// Compact embeddable panel for monitoring status and quick controls.
// Full credential configuration is in EmailSetupSheet (opened via [ CONFIGURE ]).

struct EmailIngestionPanel: View {

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
    private let amber        = Color(hex: "#F59E0B")

    @State private var showSetupSheet = false
    @State private var isCheckingNow  = false

    private var ems: EmailMonitorService { EmailMonitorService.shared }

    // MARK: Body

    var body: some View {
        TerminalBlock(command: "EMAIL_INGESTION // PASSIVE_IMPORT", accentColor: accentRust) {
            VStack(alignment: .leading, spacing: 0) {
                statusRow
                divider
                statsRow
                divider
                if let err = ems.errorMessage {
                    errorRow(err)
                    divider
                }
                controlRow
            }
        }
        .sheet(isPresented: $showSetupSheet) {
            EmailSetupSheet()
        }
    }

    // MARK: – Status row

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ems.isMonitoring ? green : tp3)
                .frame(width: 8, height: 8)

            Text(ems.isMonitoring ? "MONITORING: ACTIVE" : "MONITORING: INACTIVE")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(ems.isMonitoring ? green : tp3)

            Spacer()

            if let last = ems.lastCheckDate {
                Text("LAST_CHECK: \(timeAgo(last))")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(tp3)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: – Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell("EMAILS_PROCESSED", "\(ems.totalEmailsScanned)")
            vertDiv
            statCell("DEALS_IMPORTED",   "\(ems.totalDealsImported)")
            vertDiv
            statCell("DUPLICATES_SKIPPED", "\(ems.duplicatesSkipped)")
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(tp1)
                .monospacedDigit()
            Text(label)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundStyle(tp3)
        }
        .padding(.horizontal, 12)
    }

    // MARK: – Error row

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

    // MARK: – Control row

    private var controlRow: some View {
        HStack(spacing: 8) {
            if ems.isMonitoring {
                Button("[ STOP_MONITORING ]") {
                    ems.stopMonitoring()
                }
                .buttonStyle(TerminalButtonStyle(color: .red))
            } else {
                Button("[ START_MONITORING ]") {
                    guard ems.isConfigured else { showSetupSheet = true; return }
                    ems.startMonitoring()
                }
                .buttonStyle(TerminalButtonStyle(color: .green))
                .opacity(ems.isConfigured ? 1 : 0.5)
            }

            Button("[ CHECK_NOW ]") {
                isCheckingNow = true
                Task {
                    await ems.checkNow()
                    isCheckingNow = false
                }
            }
            .buttonStyle(TerminalButtonStyle(color: .amber))
            .disabled(isCheckingNow || !ems.isConfigured)
            .opacity(ems.isConfigured ? 1 : 0.4)

            Spacer()

            Button("[ CONFIGURE ]") {
                showSetupSheet = true
            }
            .buttonStyle(TerminalButtonStyle(color: .muted))
        }
        .frame(height: 32)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: – Helpers

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    private var vertDiv: some View {
        Rectangle().fill(shellBorder).frame(width: 1, height: 32)
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60    { return "\(s)s ago" }
        if s < 3600  { return "\(s / 60)m ago" }
        return "\(s / 3600)h ago"
    }
}
