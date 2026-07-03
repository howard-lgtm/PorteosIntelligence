import SwiftUI
import SwiftData

// MARK: - ScenarioManagerBlock
//
// A self-contained terminal block for saving, loading, and deleting named
// sensitivity scenarios for a specific deal+profile combination.
//
// Usage:
//   ScenarioManagerBlock(
//       deal:               deal,
//       profile:            "realEstate",
//       accentColor:        accentRust,
//       moduleLabel:        "07 // SAVED_SCENARIOS",
//       currentAdjustments: ["vacancyAdj": 2.0, "opexAdj": -5.0],
//       onLoad:             { dict in vacancyAdj = dict["vacancyAdj"] ?? 0 }
//   )

struct ScenarioManagerBlock: View {

    // ── Input ──────────────────────────────────────────────────────────────────
    let deal:               PropertyDeal
    let profile:            String          // "realEstate" | "hospitality" | "design" | "circular"
    let accentColor:        Color
    let moduleLabel:        String          // e.g. "07 // SAVED_SCENARIOS"
    let currentAdjustments: [String: Double]
    let onLoad:             ([String: Double]) -> Void

    // ── Environment ───────────────────────────────────────────────────────────
    @Environment(\.modelContext) private var modelContext

    // ── Local State ───────────────────────────────────────────────────────────
    @State private var scenarios:    [DealScenario] = []
    @State private var scenarioName: String          = ""
    @State private var saveError:    Bool            = false

    // ── Design tokens ─────────────────────────────────────────────────────────
    private let shellBg       = DesignTokens.canvasBase
    private let shellSurface  = DesignTokens.surfacePanel
    private let shellBorder   = DesignTokens.dividerStructural
    private let textPrimary   = DesignTokens.textPrimary
    private let textSecondary = DesignTokens.textSecondary
    private let textTertiary  = DesignTokens.textDim
    private let colorGreen    = DesignTokens.statusGo
    private let colorRed      = DesignTokens.statusCritical
    private let colorAmber    = Color(hex: "#F59E0B")

    // MARK: Body

    var body: some View {
        TerminalBlock(command: moduleLabel,
                      accentColor: accentColor,
                      contentPadding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                scenarioListSection
                Rectangle().fill(shellBorder).frame(height: 1)
                saveSection
            }
        }
        .onAppear { loadScenarios() }
    }

    // MARK: – Scenario List

    private var scenarioListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("SAVED SCENARIOS", count: scenarios.count)

            if scenarios.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(scenarios) { scenario in
                        scenarioRow(scenario)
                        if scenario.id != scenarios.last?.id {
                            Rectangle().fill(shellBorder).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Text("// NO SAVED SCENARIOS — SAVE THE CURRENT STATE BELOW")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func scenarioRow(_ scenario: DealScenario) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Name + date
            VStack(alignment: .leading, spacing: 3) {
                Text(scenario.name.uppercased())
                    .font(.custom("JetBrains Mono", size: 12).weight(.medium))
                    .foregroundStyle(textPrimary)

                Text(scenarioDate(scenario.createdAt))
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(textTertiary)
            }
            .frame(minWidth: 150, alignment: .leading)

            // Adjustments summary
            Text(adjustmentSummary(scenario.adjustments))
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons
            HStack(spacing: 8) {
                Button {
                    onLoad(scenario.adjustments)
                } label: {
                    Text("[ LOAD ]")
                        .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .stroke(accentColor.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    deleteScenario(scenario)
                } label: {
                    Text("[ × ]")
                        .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                        .foregroundStyle(colorRed.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(colorRed.opacity(0.06))
                        .overlay(
                            Rectangle()
                                .stroke(colorRed.opacity(0.30), lineWidth: 1)
                        )
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(shellSurface)
    }

    // MARK: – Save Section

    private var saveSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("SAVE CURRENT STATE", count: nil)

            HStack(spacing: 12) {
                // Name field
                ZStack(alignment: .leading) {
                    if scenarioName.isEmpty {
                        Text("e.g. Optimistic Case")
                            .font(.custom("JetBrains Mono", size: 12))
                            .foregroundStyle(textTertiary)
                    }
                    TextField("", text: $scenarioName)
                        .font(.custom("JetBrains Mono", size: 12))
                        .foregroundStyle(textPrimary)
                        .textFieldStyle(.plain)
                        .onSubmit { saveScenario() }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(shellBg)
                .overlay(
                    Rectangle()
                        .stroke(saveError ? colorAmber : shellBorder, lineWidth: 1)
                )
                .clipShape(Rectangle())
                .frame(maxWidth: .infinity)

                // Save button
                Button { saveScenario() } label: {
                    Text("[ SAVE SCENARIO ]")
                        .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(accentColor.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .stroke(accentColor.opacity(0.40), lineWidth: 1)
                        )
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if saveError {
                Text("// SCENARIO NAME IS REQUIRED")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(colorAmber)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: – Section Header

    private func sectionHeader(_ label: String, count: Int?) -> some View {
        HStack(spacing: 6) {
            Text("// \(label)")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(textTertiary)

            if let n = count {
                Text("(\(n))")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: – Data Operations

    private func loadScenarios() {
        let id   = deal.id
        let prof = profile
        let descriptor = FetchDescriptor<DealScenario>(
            predicate: #Predicate { $0.dealID == id && $0.profile == prof },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        scenarios = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveScenario() {
        let trimmed = scenarioName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            saveError = true
            return
        }
        saveError = false

        let scenario = DealScenario(
            dealID:      deal.id,
            name:        trimmed,
            profile:     profile,
            adjustments: currentAdjustments
        )
        modelContext.insert(scenario)
        try? modelContext.save()
        scenarioName = ""
        loadScenarios()
    }

    private func deleteScenario(_ scenario: DealScenario) {
        modelContext.delete(scenario)
        try? modelContext.save()
        loadScenarios()
    }

    // MARK: – Formatting Helpers

    private static let shortLabels: [String: String] = [
        "vacancyAdj":          "vac",
        "opexAdj":             "opex",
        "rateAdj":             "rate",
        "adrAdj":              "adr",
        "occupancyAdj":        "occ",
        "opexRatioAdj":        "opex",
        "daylightingAdj":      "day",
        "biophilicAdj":        "bio",
        "spaceUtilizationAdj": "spc",
        "recycledContentAdj":  "rec",
        "renewableContentAdj": "ren",
        "wasteReductionAdj":   "wst",
    ]

    private func adjustmentSummary(_ adj: [String: Double]) -> String {
        guard !adj.isEmpty else { return "—" }
        // Sort by key for stable display order
        return adj
            .sorted { $0.key < $1.key }
            .map { key, val in
                let label = Self.shortLabels[key] ?? key
                let sign  = val >= 0 ? "+" : "−"
                let abs   = Swift.abs(val)
                let str   = abs.truncatingRemainder(dividingBy: 1) == 0
                    ? String(Int(abs))
                    : String(format: "%.1f", abs)
                return "\(label): \(sign)\(str)"
            }
            .joined(separator: " · ")
    }

    private func scenarioDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy · HH:mm"
        return f.string(from: date)
    }
}
