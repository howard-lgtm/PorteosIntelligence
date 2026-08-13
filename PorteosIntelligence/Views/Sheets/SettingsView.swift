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
    @State private var unitOverride: String = UnitSystemService.shared.manualOverride
    @State private var aiProvider: AIProvider = AIProvider(rawValue: UserDefaults.standard.string(forKey: LLMAnalysisService.Keys.aiProvider) ?? "ollama") ?? .ollama
    @State private var openAIKey: String = UserDefaults.standard.string(forKey: LLMAnalysisService.Keys.openAIKey) ?? ""
    @State private var geminiKey: String = UserDefaults.standard.string(forKey: LLMAnalysisService.Keys.geminiKey) ?? ""
    @State private var showOpenAIKey: Bool = false
    @State private var showGeminiKey: Bool = false

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
            sourceRow("RE/MAX PT",  domain: "remax.pt",                     icon: "RM")
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
                "01 // AI_PROVIDER",
                subtitle: "Select the AI engine used for Vibe analysis and market briefs."
            )

            // Provider chip selector
            HStack(spacing: 0) {
                ForEach(AIProvider.allCases, id: \.self) { provider in
                    let isActive = aiProvider == provider
                    Button {
                        aiProvider = provider
                        saveProviderConfig()
                    } label: {
                        Text(provider == .ollama ? "LOCAL" : provider == .openai ? "OPENAI" : "GEMINI")
                            .porteosMeta()
                            .foregroundStyle(isActive ? accentRust : tp3)
                            .padding(.horizontal, 14)
                            .frame(height: 28)
                            .background(isActive ? accentRust.opacity(0.1) : Color.clear)
                            .overlay(
                                Rectangle().strokeBorder(
                                    isActive ? accentRust.opacity(0.5) : shellBorder,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            divider

            // Per-provider config
            switch aiProvider {
            case .ollama:
                ollamaConfig
            case .openai:
                openAIConfig
            case .gemini:
                geminiConfig
            }

            divider.padding(.top, 8)

            sectionHeader("02 // PRIVACY", subtitle: "")

            switch aiProvider {
            case .ollama:
                infoRow("DATA POLICY", "// LOCAL LLM · NO DATA LEAVES DEVICE")
                infoRow("STORAGE",     "Signals cached in UserDefaults; deal data stays in SwiftData on-device")
                infoRow("NETWORK",     "Ollama runs on this machine at the configured endpoint only")
            case .openai:
                infoRow("DATA POLICY", "Prompts sent to OpenAI API servers. Subject to OpenAI privacy policy.")
                infoRow("KEY STORAGE", "API key stored in UserDefaults (Keychain migration planned)")
                infoRow("NETWORK",     "api.openai.com — your key, your cost, your data")
            case .gemini:
                infoRow("DATA POLICY", "Prompts sent to Google Generative Language API servers.")
                infoRow("KEY STORAGE", "API key stored in UserDefaults (Keychain migration planned)")
                infoRow("NETWORK",     "generativelanguage.googleapis.com — free tier available")
            }

            Spacer(minLength: 20)
        }
    }

    @ViewBuilder
    private var ollamaConfig: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("LLM SERVER URL")
                    .porteosMeta()
                    .foregroundStyle(tp3)
                    .frame(width: 130, alignment: .leading)
                TextField("http://localhost:11434", text: $llmEndpoint)
                    .textFieldStyle(.plain)
                    .porteosMeta()
                    .foregroundStyle(tp1)
                    .onSubmit { saveLLMConfig() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            divider

            HStack(spacing: 12) {
                Text("LLM MODEL NAME")
                    .porteosMeta()
                    .foregroundStyle(tp3)
                    .frame(width: 130, alignment: .leading)
                TextField("qwen2.5:0.5b", text: $llmModel)
                    .textFieldStyle(.plain)
                    .porteosMeta()
                    .foregroundStyle(tp1)
                    .onSubmit { saveLLMConfig() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            divider

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

            divider

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
        }
        .background(shellSurface)
    }

    @ViewBuilder
    private var openAIConfig: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("OPENAI API KEY")
                    .porteosMeta()
                    .foregroundStyle(tp3)
                    .frame(width: 130, alignment: .leading)
                
                if showOpenAIKey {
                    TextField("sk-...", text: $openAIKey)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(tp1)
                        .onSubmit { saveProviderConfig() }
                        .onChange(of: openAIKey) { _, _ in saveProviderConfig() }
                } else {
                    SecureField("sk-...", text: $openAIKey)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(tp1)
                        .onSubmit { saveProviderConfig() }
                        .onChange(of: openAIKey) { _, _ in saveProviderConfig() }
                }
                
                Button {
                    showOpenAIKey.toggle()
                } label: {
                    Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                        .foregroundStyle(tp3)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(showOpenAIKey ? "Hide key" : "Show key")
                
                if !openAIKey.isEmpty {
                    Text("KEY SET ✓")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusGo)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            divider

            HStack {
                Text("// gpt-4o-mini — ~$0.01 per analysis. Your key, your cost.")
                    .porteosMeta()
                    .foregroundStyle(tp3)
                Spacer()
                Button {
                    Task { await testCloudConnection() }
                } label: {
                    Text(llmPinging ? "[ TESTING… ]" : "[ TEST CONNECTION ]")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.accentRust)
                }
                .buttonStyle(.plain)
                .disabled(openAIKey.isEmpty || llmPinging)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let result = llmPingResult {
                Text(result)
                    .porteosMeta()
                    .foregroundStyle(result.hasPrefix("✓") ? DesignTokens.statusGo : DesignTokens.statusCritical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            divider

            infoRow("MODEL",   "gpt-4o-mini (auto)")
            infoRow("GET KEY", "platform.openai.com/api-keys")
        }
        .background(shellSurface)
    }

    @ViewBuilder
    private var geminiConfig: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("GEMINI API KEY")
                    .porteosMeta()
                    .foregroundStyle(tp3)
                    .frame(width: 130, alignment: .leading)
                
                if showGeminiKey {
                    TextField("AIza...", text: $geminiKey)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(tp1)
                        .onSubmit { saveProviderConfig() }
                        .onChange(of: geminiKey) { _, _ in saveProviderConfig() }
                } else {
                    SecureField("AIza...", text: $geminiKey)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(tp1)
                        .onSubmit { saveProviderConfig() }
                        .onChange(of: geminiKey) { _, _ in saveProviderConfig() }
                }
                
                Button {
                    showGeminiKey.toggle()
                } label: {
                    Image(systemName: showGeminiKey ? "eye.slash" : "eye")
                        .foregroundStyle(tp3)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(showGeminiKey ? "Hide key" : "Show key")
                
                if !geminiKey.isEmpty {
                    Text("KEY SET ✓")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusGo)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            divider

            HStack {
                Text("// gemini-3.5-flash — free tier: 15 req/min, 1M tokens/day")
                    .porteosMeta()
                    .foregroundStyle(tp3)
                Spacer()
                Button {
                    Task { await testCloudConnection() }
                } label: {
                    Text(llmPinging ? "[ TESTING… ]" : "[ TEST CONNECTION ]")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.accentRust)
                }
                .buttonStyle(.plain)
                .disabled(geminiKey.isEmpty || llmPinging)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if let result = llmPingResult {
                Text(result)
                    .porteosMeta()
                    .foregroundStyle(result.hasPrefix("✓") ? DesignTokens.statusGo : DesignTokens.statusCritical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            divider

            divider

            infoRow("MODEL",   "gemini-3.5-flash (auto, free tier available)")
            infoRow("GET KEY", "aistudio.google.com/app/apikey")
        }
        .background(shellSurface)
    }

    private func saveLLMConfig() {
        UserDefaults.standard.set(llmEndpoint, forKey: LLMAnalysisService.Keys.baseURL)
        UserDefaults.standard.set(llmModel,    forKey: LLMAnalysisService.Keys.modelName)
    }

    private func saveProviderConfig() {
        UserDefaults.standard.set(aiProvider.rawValue, forKey: LLMAnalysisService.Keys.aiProvider)
        UserDefaults.standard.set(openAIKey,           forKey: LLMAnalysisService.Keys.openAIKey)
        UserDefaults.standard.set(geminiKey,           forKey: LLMAnalysisService.Keys.geminiKey)
        llmPingResult = nil   // clear stale test result when key changes
    }

    /// Test cloud API key by sending a minimal prompt and checking for a valid response.
    private func testCloudConnection() async {
        llmPinging = true
        llmPingResult = nil
        saveProviderConfig()
        do {
            let response = try await LLMAnalysisService.shared.generateSWOT(
                dealName: "Connection Test",
                grade: "B",
                score: 70,
                signals: ["Test signal"]
            )
            llmPingResult = response.isEmpty ? "✗ No response received" : "✓ Connected — API key is valid"
        } catch {
            llmPingResult = "✗ \(error.localizedDescription)"
        }
        llmPinging = false
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

            sectionHeader("02 // UNITS", subtitle: "Display unit system for area and height fields.")

            unitsRow

            divider

            sectionHeader("03 // BUILD_INFO", subtitle: "")

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

    // MARK: – Units row

    private var unitsRow: some View {
        HStack(spacing: 0) {
            Text("UNIT_SYSTEM")
                .porteosButtonPrimary()
                .foregroundStyle(tp2)

            Spacer()

            HStack(spacing: 0) {
                ForEach([("AUTO", "auto"), ("METRIC", "metric"), ("IMPERIAL", "imperial")], id: \.1) { label, value in
                    let isActive = unitOverride == value
                    Button {
                        unitOverride = value
                        UnitSystemService.shared.manualOverride = value
                    } label: {
                        Text(label)
                            .porteosMeta()
                            .foregroundStyle(isActive ? accentRust : tp3)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(isActive ? accentRust.opacity(0.1) : Color.clear)
                            .overlay(
                                Rectangle().strokeBorder(
                                    isActive ? accentRust.opacity(0.5) : shellBorder,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(Rectangle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
