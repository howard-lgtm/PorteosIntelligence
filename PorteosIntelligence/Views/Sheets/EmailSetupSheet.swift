import SwiftUI

// MARK: - EmailSetupSheet

struct EmailSetupSheet: View {

    @Environment(\.dismiss) private var dismiss
    private let ems = EmailMonitorService.shared

    // MARK: Form state

    @State private var email        = ""
    @State private var password     = ""
    @State private var selectedPreset = 0   // index into IMAPCredentials.presets
    @State private var customHost   = ""
    @State private var port         = "993"
    @State private var folder       = "INBOX"
    @State private var pollMinutes  = 15

    @State private var testResult:  String?
    @State private var isTesting    = false
    @State private var saveError:   String?
    @State private var didSave      = false

    // MARK: Design tokens

    private let shellBg      = DesignTokens.canvasBase
    private let shellSurface = DesignTokens.surfacePanel
    private let shellBorder  = DesignTokens.dividerStructural
    private let textPrimary  = Color(hex: "#E2E8F0")
    private let textSecondary = DesignTokens.textSecondary
    private let textTertiary = DesignTokens.textDim
    private let accentRust   = DesignTokens.accentRust
    private let accentGreen  = DesignTokens.statusGo
    private let accentRed    = DesignTokens.statusCritical
    private let accentAmber  = Color(hex: "#F59E0B")

    private var resolvedHost: String {
        let preset = IMAPCredentials.presets[selectedPreset]
        return preset.host.isEmpty ? customHost : preset.host
    }

    private var resolvedPort: Int { Int(port) ?? 993 }

    private var currentCredentials: IMAPCredentials {
        IMAPCredentials(
            email:       email,
            password:    password,
            imapHost:    resolvedHost,
            imapPort:    resolvedPort,
            folder:      folder.isEmpty ? "INBOX" : folder,
            pollMinutes: pollMinutes
        )
    }

    private var canSave: Bool { !email.isEmpty && !password.isEmpty && !resolvedHost.isEmpty }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 8) {
                    credentialsBlock
                    serverBlock
                    pollingBlock
                    notesBlock
                    if ems.isConfigured {
                        statusBlock
                    }
                }
                .padding(12)
            }
            actionBar
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 520, height: 640)
        .onAppear { loadExisting() }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack(spacing: 0) {
            Text("EMAIL_ALERT_MONITOR")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundColor(textTertiary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("[ CLOSE ]")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundColor(textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(shellSurface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(shellBorder).frame(height: 1)
        }
    }

    private var credentialsBlock: some View {
        TerminalBlock(command: "01 // CREDENTIALS", accentColor: accentRust) {
            VStack(spacing: 4) {
                row("EMAIL") {
                    TextField("user@example.com", text: $email)
                        .textFieldStyle(.plain)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textPrimary)
                        .autocorrectionDisabled()
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                row("PASSWORD") {
                    SecureField("App password or token", text: $password)
                        .textFieldStyle(.plain)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textPrimary)
                }
                // Gmail note
                if resolvedHost.contains("gmail") {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("Gmail requires an App Password (myaccount.google.com > Security > App Passwords)")
                            .font(.custom("JetBrains Mono", size: 9))
                    }
                    .foregroundColor(accentAmber)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var serverBlock: some View {
        TerminalBlock(command: "02 // IMAP_SERVER", accentColor: accentRust) {
            VStack(spacing: 4) {
                // Provider preset
                row("PROVIDER") {
                    Picker("", selection: $selectedPreset) {
                        ForEach(Array(IMAPCredentials.presets.enumerated()), id: \.0) { idx, preset in
                            Text(preset.label)
                                .font(.custom("JetBrains Mono", size: 11))
                                .tag(idx)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.custom("JetBrains Mono", size: 11))
                }
                // Custom host field — only visible when "Custom" is selected
                if IMAPCredentials.presets[selectedPreset].host.isEmpty {
                    Rectangle().fill(shellBorder).frame(height: 1)
                    row("IMAP_HOST") {
                        TextField("imap.example.com", text: $customHost)
                            .textFieldStyle(.plain)
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundColor(textPrimary)
                            .autocorrectionDisabled()
                    }
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                row("PORT") {
                    TextField("993", text: $port)
                        .textFieldStyle(.plain)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textPrimary)
                        .frame(maxWidth: 60, alignment: .trailing)
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                row("FOLDER") {
                    TextField("INBOX", text: $folder)
                        .textFieldStyle(.plain)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textPrimary)
                        .autocorrectionDisabled()
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                // Test connection row
                HStack {
                    Button {
                        Task { await runTest() }
                    } label: {
                        Text(isTesting ? "[ TESTING… ]" : "[ TEST_CONNECTION ]")
                            .font(.custom("JetBrains Mono", size: 10))
                            .foregroundColor(isTesting ? textTertiary : accentRust)
                    }
                    .buttonStyle(.plain)
                    .disabled(isTesting || !canSave)

                    if let result = testResult {
                        Text(result)
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundColor(result.hasPrefix("CONNECTION_OK") ? accentGreen : accentRed)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(height: 28)
            }
        }
    }

    private var pollingBlock: some View {
        TerminalBlock(command: "03 // POLLING", accentColor: accentRust) {
            VStack(spacing: 4) {
                row("INTERVAL") {
                    Picker("", selection: $pollMinutes) {
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hr").tag(60)
                        Text("4 hr").tag(240)
                    }
                    .labelsHidden()
                    .font(.custom("JetBrains Mono", size: 11))
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                HStack {
                    Text("PARSERS")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundColor(textTertiary)
                        .frame(width: 96, alignment: .leading)
                    Text("Idealista  ·  Zillow  ·  Hemnet  ·  Generic")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundColor(textSecondary)
                    Spacer()
                }
                .frame(height: 24)
            }
        }
    }

    private var notesBlock: some View {
        TerminalBlock(command: "04 // IMPORT_RULES", accentColor: accentRust) {
            VStack(alignment: .leading, spacing: 4) {
                note("• New deals imported with STATUS = PIPELINE")
                note("• Tags: [ email_import ] [ source:platform ]")
                note("• Deduplication: listing URL unique constraint")
                note("• Max 50 messages processed per polling cycle")
                note("• Credentials stored in system Keychain (never plain-text)")
            }
        }
    }

    private var statusBlock: some View {
        TerminalBlock(command: "05 // STATUS", accentColor: accentGreen) {
            VStack(spacing: 4) {
                row("MONITORING") {
                    Text(ems.isMonitoring ? "ACTIVE" : "STOPPED")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(ems.isMonitoring ? accentGreen : textTertiary)
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                row("LAST_CHECK") {
                    Text(ems.lastCheckDate.map { formatDate($0) } ?? "—")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(textSecondary)
                }
                Rectangle().fill(shellBorder).frame(height: 1)
                row("IMPORTS_TODAY") {
                    Text("\(ems.newImportCount)")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(ems.newImportCount > 0 ? accentGreen : textSecondary)
                }
                if let err = ems.errorMessage {
                    Rectangle().fill(shellBorder).frame(height: 1)
                    HStack {
                        Text("LAST_ERROR")
                            .font(.custom("JetBrains Mono", size: 10))
                            .foregroundColor(textTertiary)
                            .frame(width: 96, alignment: .leading)
                        Text(err)
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundColor(accentRed)
                            .lineLimit(3)
                    }
                    .frame(minHeight: 24)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            if ems.isConfigured {
                Button {
                    if ems.isMonitoring {
                        ems.stopMonitoring()
                    } else {
                        ems.startMonitoring()
                    }
                } label: {
                    Text(ems.isMonitoring ? "[ STOP_MONITOR ]" : "[ START_MONITOR ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(ems.isMonitoring ? accentAmber : accentGreen)
                        .frame(height: 32)
                        .padding(.horizontal, 12)
                        .background(shellSurface)
                        .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    Task { await ems.checkNow() }
                } label: {
                    Text(ems.isCheckingNow ? "[ CHECKING… ]" : "[ CHECK_NOW ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(ems.isCheckingNow ? textTertiary : textSecondary)
                        .frame(height: 32)
                        .padding(.horizontal, 12)
                        .background(shellSurface)
                        .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(ems.isCheckingNow)

                Button {
                    IMAPCredentials.delete()
                    ems.stopMonitoring()
                    clearForm()
                } label: {
                    Text("[ DISCONNECT ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundColor(accentRed)
                        .frame(height: 32)
                        .padding(.horizontal, 12)
                        .background(shellSurface)
                        .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let err = saveError {
                Text(err)
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundColor(accentRed)
            }

            Button {
                save()
            } label: {
                Text(didSave ? "[ SAVED ✓ ]" : "[ SAVE_CONFIG ]")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundColor(canSave ? textPrimary : textTertiary)
                    .frame(height: 32)
                    .padding(.horizontal, 12)
                    .background(canSave ? accentRust : shellSurface)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(shellSurface)
        .overlay(alignment: .top) {
            Rectangle().fill(shellBorder).frame(height: 1)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func row<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        HStack {
            Text(label)
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(textTertiary)
                .frame(width: 96, alignment: .leading)
            content()
        }
        .frame(height: 28)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 10))
            .foregroundColor(textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 1)
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm · dd MMM"
        return fmt.string(from: date)
    }

    private func loadExisting() {
        guard let creds = IMAPCredentials.load() else { return }
        email    = creds.email
        password = creds.password
        folder   = creds.folder
        port     = String(creds.imapPort)
        pollMinutes = creds.pollMinutes

        // Match to preset index
        if let idx = IMAPCredentials.presets.firstIndex(where: { $0.host == creds.imapHost }) {
            selectedPreset = idx
        } else {
            selectedPreset = IMAPCredentials.presets.count - 1 // "Custom"
            customHost = creds.imapHost
        }
    }

    private func clearForm() {
        email = ""; password = ""; customHost = ""; folder = "INBOX"; port = "993"; pollMinutes = 15
        selectedPreset = 0; testResult = nil; saveError = nil; didSave = false
    }

    private func save() {
        saveError = nil
        do {
            try currentCredentials.save()
            didSave = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { didSave = false }
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func runTest() async {
        isTesting = true
        testResult = nil
        let result = await ems.testConnection(creds: currentCredentials)
        testResult = result.hasPrefix("CONNECTION_OK") ? "OK" : String(result.prefix(80))
        isTesting = false
    }
}

// MARK: - Preview

#Preview {
    EmailSetupSheet()
}
