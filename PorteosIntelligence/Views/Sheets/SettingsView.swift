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
        case intel  = "INTELLIGENCE"
        case general = "GENERAL"
    }

    @State private var activeTab: Tab = .email
    @State private var showEmailSetup = false
    @State private var llmEndpoint: String = UserDefaults.standard.string(forKey: LLMAnalysisService.Keys.baseURL) ?? LLMAnalysisService.defaultBaseURL
    @State private var llmModel: String = UserDefaults.standard.string(forKey: LLMAnalysisService.Keys.modelName) ?? LLMAnalysisService.defaultModelName
    @State private var llmPingResult: String? = nil
    @State private var llmPinging = false

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
                .porteosButtonPrimary()
                .foregroundStyle(tp3)
            Text(" // SETTINGS")
                .porteosRowLabel()
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
                        .porteosTextStyle(activeTab == tab ? .buttonPrimary : .meta)
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
            case .intel:   intelligenceTab
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
                        .porteosMeta()
                        .foregroundStyle(tp2)
                    Text("Credentials, IMAP server, polling interval, import rules.")
                        .porteosMeta()
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
                        .porteosMeta()
                        .foregroundStyle(tp2)
                    Text("Port, allowed origins, request log, browser extension setup.")
                        .porteosMeta()
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

    // MARK: – Intelligence tab

    private var intelligenceTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                "01 // LOCAL_LLM",
                subtitle: "Ollama endpoint for AI Vibe analysis and Global Intelligence market briefs."
            )

            VStack(alignment: .leading, spacing: 0) {
                // Endpoint
                HStack(spacing: 12) {
                    Text("ENDPOINT")
                        .porteosMeta()
                        .foregroundStyle(tp3)
                        .frame(width: 100, alignment: .leading)
                    TextField("http://localhost:11434", text: $llmEndpoint)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(tp1)
                        .onSubmit { saveLLMConfig() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                divider

                // Model
                HStack(spacing: 12) {
                    Text("MODEL")
                        .porteosMeta()
                        .foregroundStyle(tp3)
                        .frame(width: 100, alignment: .leading)
                    TextField("qwen2.5:0.5b", text: $llmModel)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(tp1)
                        .onSubmit { saveLLMConfig() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                divider

                // Ping
                HStack(spacing: 12) {
                    Button {
                        saveLLMConfig()
                        llmPinging = true
                        llmPingResult = nil
                        Task {
                            let ok = await LLMAnalysisService.shared.isAvailable()
                            llmPingResult = ok ? "// ONLINE" : "// OFFLINE"
                            llmPinging = false
                        }
                    } label: {
                        Text(llmPinging ? "[ TESTING … ]" : "[ TEST CONNECTION ]")
                    }
                    .buttonStyle(TerminalButtonStyle(color: .muted, fontSize: 10, height: 26))
                    .disabled(llmPinging)

                    if let result = llmPingResult {
                        Text(result)
                            .porteosMeta()
                            .foregroundStyle(result.contains("ONLINE") ? accentGreen : DesignTokens.statusWarn)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(shellSurface)

            divider.padding(.top, 8)

            sectionHeader("02 // PRIVACY", subtitle: "")
            infoRow("DATA POLICY",  "// LOCAL LLM · NO DATA LEAVES DEVICE")
            infoRow("STORAGE",      "Signals cached in UserDefaults; deal data stays in SwiftData on-device")
            infoRow("NETWORK",      "Ollama runs on this machine at the configured endpoint only")

            divider.padding(.top, 8)

            sectionHeader("03 // DEFAULTS", subtitle: "")
            infoRow("DEFAULT ENDPOINT",  LLMAnalysisService.defaultBaseURL)
            infoRow("DEFAULT MODEL",     LLMAnalysisService.defaultModelName)

            HStack {
                Button("[ RESET TO DEFAULTS ]") {
                    llmEndpoint = LLMAnalysisService.defaultBaseURL
                    llmModel    = LLMAnalysisService.defaultModelName
                    saveLLMConfig()
                }
                .buttonStyle(TerminalButtonStyle(color: .muted, fontSize: 10, height: 26))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Spacer(minLength: 20)
        }
    }

    private func saveLLMConfig() {
        UserDefaults.standard.set(llmEndpoint, forKey: LLMAnalysisService.Keys.baseURL)
        UserDefaults.standard.set(llmModel,    forKey: LLMAnalysisService.Keys.modelName)
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

            generalRow(
                label:    "GLOSSARY",
                value:    "⌘⇧G",
                action:   {
                    NotificationCenter.default.post(name: .showGlossary, object: nil)
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
                .porteosMeta()
                .foregroundStyle(tp2)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .porteosMeta()
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
                .porteosMeta()
                .foregroundStyle(tp3)
                .frame(width: 24)
            Text(name)
                .porteosButtonPrimary()
                .foregroundStyle(tp1)
                .frame(width: 100, alignment: .leading)
            Text(domain)
                .porteosMeta()
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
                .porteosButtonPrimary()
                .foregroundStyle(tp2)
            Spacer()
            Text(value)
                .porteosRowLabel()
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
                .porteosMeta()
                .foregroundStyle(tp3)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .porteosMeta()
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
