import SwiftUI

// MARK: - SettingsView
//
// Application-wide preferences sheet.
// Opened via ⌘, or Actions → Settings.
// Tabs: Email Ingestion | Ingestion Server | General

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: Tokens

    private let shellBg      = DesignTokens.canvasBase
    private let shellSurface = DesignTokens.surfacePanel
    private let shellBorder  = DesignTokens.dividerStructural
    private let tp1          = DesignTokens.textPrimary
    private let tp2          = DesignTokens.textSecondary
    private let tp3          = DesignTokens.textDim
    private let accentRust   = DesignTokens.accentRust
    private let accentGreen  = DesignTokens.statusGo

    // MARK: State

    enum Tab: String, CaseIterable {
        case email  = "EMAIL_INGESTION"
        case server = "INGESTION_SERVER"
        case general = "GENERAL"
    }

    @State private var activeTab: Tab = .email
    @State private var showEmailSetup = false

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            tabBar
            Divider().background(shellBorder)
            tabContent
                .frame(minHeight: 480)
        }
        .frame(width: 660)
        .background(shellBg)
        .sheet(isPresented: $showEmailSetup) {
            EmailSetupSheet()
        }
    }

    // MARK: – Title bar

    private var titleBar: some View {
        HStack(spacing: 0) {
            Text("PORTEOS")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(tp3)
            Text(" // SETTINGS")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(tp3)
            Spacer()
            Button("[ CLOSE ]") { dismiss() }
                .buttonStyle(TerminalButtonStyle(color: .muted, fontSize: 10, height: 24))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(shellSurface)
    }

    // MARK: – Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.custom("JetBrains Mono", size: 10).weight(activeTab == tab ? .bold : .regular))
                        .foregroundStyle(activeTab == tab ? tp1 : tp3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(activeTab == tab ? shellSurface : Color.clear)
                        .overlay(alignment: .bottom) {
                            if activeTab == tab {
                                Rectangle().fill(accentRust).frame(height: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .background(shellBg)
    }

    // MARK: – Tab content

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            switch activeTab {
            case .email:   emailTab
            case .server:  serverTab
            case .general: generalTab
            }
        }
        .background(shellBg)
    }

    // MARK: – Email Ingestion tab

    private var emailTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "01 // EMAIL_INGESTION",
                subtitle: "Passive deal import from saved search alert emails."
            )

            EmailIngestionPanel()
                .padding(.horizontal, 16)
                .padding(.top, 12)

            divider.padding(.top, 16)

            // Full configuration CTA
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FULL_CONFIGURATION")
                        .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                        .foregroundStyle(tp2)
                    Text("Credentials, IMAP server, polling interval, import rules.")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundStyle(tp3)
                }
                Spacer()
                Button("[ OPEN_EMAIL_SETUP ]") {
                    showEmailSetup = true
                }
                .buttonStyle(TerminalButtonStyle(color: .rust))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            divider

            // Supported sources
            sectionHeader("02 // SUPPORTED_SOURCES", subtitle: "Emails from these senders are auto-parsed.")
            sourceRow("Idealista",  domain: "idealista.pt / idealista.com", icon: "IE")
            sourceRow("Zillow",     domain: "zillow.com",                   icon: "ZW")
            sourceRow("Hemnet",     domain: "hemnet.se",                    icon: "HN")
            sourceRow("Generic",    domain: "Any listing email",             icon: "──")

            Spacer(minLength: 20)
        }
    }

    // MARK: – Ingestion Server tab

    private var serverTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "01 // LOCAL_HTTP_SERVER",
                subtitle: "Receives deals pushed from the Porteos browser extension."
            )

            DealIngestionServerPanel()
                .padding(.horizontal, 16)
                .padding(.top, 12)

            divider.padding(.top, 16)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ADVANCED_CONFIGURATION")
                        .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                        .foregroundStyle(tp2)
                    Text("Port, allowed origins, request log, browser extension setup.")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundStyle(tp3)
                }
                Spacer()
                Button("[ OPEN_SERVER_CONFIG ]") {
                    NotificationCenter.default.post(name: .showServerConfig, object: nil)
                    dismiss()
                }
                .buttonStyle(TerminalButtonStyle(color: .rust))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Spacer(minLength: 20)
        }
    }

    // MARK: – General tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "01 // APPLICATION",
                subtitle: "Global application preferences."
            )

            generalRow(
                label:   "KEYBOARD_SHORTCUTS",
                value:   "⌘/",
                action:  {
                    NotificationCenter.default.post(name: .showShortcutsLegend, object: nil)
                    dismiss()
                },
                btnLabel: "[ VIEW ]"
            )

            divider

            generalRow(
                label:    "COMMAND_PALETTE",
                value:    "⌘K",
                action:   {
                    NotificationCenter.default.post(name: .showCommandPalette, object: nil)
                    dismiss()
                },
                btnLabel: "[ OPEN ]"
            )

            divider

            sectionHeader("02 // BUILD_INFO", subtitle: "")

            infoRow("ARCHITECTURE",  "Email Monitor (curl/IMAP) + HTTP Ingestion Server + Browser Extension")
            infoRow("PERSISTENCE",   "SwiftData (on-device, encrypted)")
            infoRow("CREDENTIALS",   "macOS Keychain — never UserDefaults")
            infoRow("NOTIFICATIONS", "In-app toast via ToastManager")

            Spacer(minLength: 20)
        }
    }

    // MARK: – Reusable sub-views

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(tp2)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(tp3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private func sourceRow(_ name: String, domain: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(tp3)
                .frame(width: 24)
            Text(name)
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(tp1)
                .frame(width: 100, alignment: .leading)
            Text(domain)
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(tp3)
            Spacer()
            Circle()
                .fill(accentGreen)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(shellSurface)
        .overlay(alignment: .bottom) { divider }
    }

    private func generalRow(
        label: String,
        value: String,
        action: @escaping () -> Void,
        btnLabel: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(tp2)
            Spacer()
            Text(value)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(tp3)
            Button(btnLabel, action: action)
                .buttonStyle(TerminalButtonStyle(color: .muted, fontSize: 10, height: 26))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(tp3)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(tp2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }
}
