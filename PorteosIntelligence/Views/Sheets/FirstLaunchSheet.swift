import SwiftUI

// MARK: - FirstLaunchSheet
// Shown once on first launch when no deals exist.
// Terminal aesthetic. Three setup paths + skip.

struct FirstLaunchSheet: View {

    var onDismiss:    () -> Void
    var onNewDeal:    () -> Void
    var onEmailSetup: () -> Void
    var onSettings:   () -> Void

    private let accent = DesignTokens.accentRust

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 0) {
                Text("porteos@system ~ % ")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textDim)
                Text("./welcome --init")
                    .porteosModuleCmd()
                    .foregroundStyle(accent)
                Spacer()
                Button("[ SKIP ]") { onDismiss() }
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .frame(height: 44)
            .background(DesignTokens.surfacePanel)

            Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Identity block
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PORTEOS INTELLIGENCE")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("Geo-anchored deal intelligence for value-add real estate.")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    // Setup checklist
                    VStack(alignment: .leading, spacing: 4) {
                        Text("// SETUP_CHECKLIST")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                            .padding(.bottom, 8)

                        setupStep(
                            number: "01",
                            title: "ADD YOUR FIRST DEAL",
                            description: "Import from Remax.pt, Idealista, or enter manually. Each deal runs through 4 scoring profiles.",
                            cta: "[ ./NEW_DEAL ]",
                            action: onNewDeal
                        )

                        Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)

                        setupStep(
                            number: "02",
                            title: "CONNECT BROWSER EXTENSION",
                            description: "Install Porteos Importer in Chrome → browse any listing → [ SEND TO PORTEOS ]. HTTP server runs on localhost:9000.",
                            cta: "[ OPEN SETTINGS ]",
                            action: onSettings
                        )

                        Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)

                        setupStep(
                            number: "03",
                            title: "SET UP EMAIL INGESTION",
                            description: "Point a Gmail saved-search alert at Porteos. New listings arrive automatically via IMAP.",
                            cta: "[ CONFIGURE EMAIL ]",
                            action: onEmailSetup
                        )

                        Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)

                        setupStep(
                            number: "04",
                            title: "ENABLE LOCAL AI (OPTIONAL)",
                            description: "Ollama + any model gives you SWOT analysis and Go/Review/NoGo verdicts on every deal. Settings → INTELLIGENCE.",
                            cta: "[ OPEN SETTINGS ]",
                            action: onSettings
                        )
                    }
                    .background(DesignTokens.surfacePanel)
                    .overlay { Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1) }

                    // Key shortcuts
                    VStack(alignment: .leading, spacing: 6) {
                        Text("// QUICK REFERENCE")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                        shortcutRow("⌘1–5", "Switch profiles (Cmd Center → Global Intelligence)")
                        shortcutRow("⌘K",   "Command palette — search deals, import, run AI")
                        shortcutRow("⌘N",   "New deal (opens template picker)")
                        shortcutRow("⌘⇧G",  "Glossary — all Porteos terms defined")
                        shortcutRow("⌘/",   "Full shortcuts legend")
                    }

                    // Privacy note
                    Text("// LOCAL_ONLY · All deal data stays on this machine. Ollama inference is on-device. No telemetry.")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .background(DesignTokens.canvasBase)

            // Footer
            Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
            HStack {
                Text("Porteos Intelligence v1.1")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
                Button("[ START → ADD FIRST DEAL ]") { onNewDeal() }
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.canvasBase)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accent)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(DesignTokens.surfacePanel)
        }
        .frame(width: 640, height: 680)
        .background(DesignTokens.canvasBase)
    }

    private func setupStep(
        number: String,
        title: String,
        description: String,
        cta: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .frame(width: 24, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                Text(description)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(cta, action: action)
                    .porteosMeta()
                    .foregroundStyle(accent)
                    .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func shortcutRow(_ keys: String, _ description: String) -> some View {
        HStack(spacing: 12) {
            Text(keys)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 60, alignment: .leading)
            Text(description)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
    }
}
