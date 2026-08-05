import SwiftUI
import SwiftData

// MARK: - PreloadReviewSheet
// Shows all market-derived estimates for a deal. User reviews and applies
// individual fields — nothing is written until [ APPLY SELECTED ] is tapped.

struct PreloadReviewSheet: View {

    @Bindable var deal: PropertyDeal
    let estimate: DealPreloader.PreloadEstimate
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext

    // Selected fields — all on by default, user can opt out
    @State private var selected: Set<String> = []

    // Phase 3 overrides
    @State private var conditionOverride: DealPreloader.PropertyCondition? = nil
    @State private var season: DealPreloader.SeasonProfile = .shoulder

    private let accent = DesignTokens.accentRust

    // MARK: - Override computed values

    private var effectiveCondition: DealPreloader.PropertyCondition {
        conditionOverride ?? estimate.condition
    }

    /// Recover `area × costPerSqm × heritageMultiplier` from the original estimate so we
    /// can recompute renovation range for any condition without re-running the full estimator.
    private var renovBaseProduct: Double {
        let origLow = estimate.condition.renovationFactorRange.low
        guard origLow > 0 else { return 0 }
        return estimate.renovationLow / origLow
    }
    private var effectiveRenovLow:  Double { renovBaseProduct * effectiveCondition.renovationFactorRange.low }
    private var effectiveRenovHigh: Double { renovBaseProduct * effectiveCondition.renovationFactorRange.high }

    private var pricePSqmLine: String {
        let svc = UnitSystemService.shared
        let country = deal.locationCountry
        let p = svc.formatPricePerArea(estimate.pricePSqm, currency: "", country: country)
        let m = svc.formatPricePerArea(estimate.marketPSqm, currency: "", country: country)
        return "\(p) vs implied market \(m) — \(Int(estimate.discountRatio * 100))% of market value"
    }

    private var effectiveADR: Double? {
        guard let base = estimate.hospitalityADR else { return nil }
        return DealPreloader.seasonalHospitality(baseADR: base, baseOccupancy: 0, season: season).adr
    }
    private var effectiveOccupancy: Double? {
        guard let base = estimate.hospitalityOccupancyRate else { return nil }
        return DealPreloader.seasonalHospitality(baseADR: 0, baseOccupancy: base, season: season).occupancy
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
            conditionBanner
            Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionRows
                }
            }
            Rectangle().fill(DesignTokens.dividerStructural).frame(height: 1)
            footer
        }
        .frame(width: 560)
        .background(DesignTokens.canvasBase)
        .onAppear { selected = Set(allFields.map(\.key)) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text("./preload --market=\(estimate.benchmarkCity.lowercased())")
                .porteosModuleCmd()
                .foregroundStyle(accent)
            Spacer()
            Button { onDismiss() } label: {
                Text("[ × ]")
                    .porteosModuleCmd()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: - Condition banner

    private var conditionBanner: some View {
        VStack(spacing: 0) {
            // Info row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(effectiveCondition.icon)
                            .porteosRowValue()
                            .foregroundStyle(conditionColor)
                        Text(effectiveCondition.rawValue.uppercased())
                            .porteosRowValue()
                            .foregroundStyle(conditionColor)
                        if conditionOverride != nil {
                            Text("// manual override")
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.textDim)
                        }
                    }
                        Text(pricePSqmLine)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("RENOVATION RANGE")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Text("€\(compactEur(effectiveRenovLow)) – €\(compactEur(effectiveRenovHigh))")
                        .porteosRowValue()
                        .foregroundStyle(conditionColor)
                    if estimate.isHeritage {
                        Text("// heritage +30%")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)

            // Condition picker
            HStack(spacing: 0) {
                Text("OVERRIDE:")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: 70, alignment: .leading)
                    .padding(.leading, DesignTokens.blockGutter)

                HStack(spacing: 1) {
                    ForEach(DealPreloader.PropertyCondition.allCases, id: \.self) { cond in
                        let isActive = effectiveCondition == cond
                        Button {
                            if conditionOverride == cond {
                                conditionOverride = nil   // second tap resets to auto
                            } else {
                                conditionOverride = cond
                            }
                        } label: {
                            Text("[ \(cond.shortLabel) ]")
                                .porteosMeta()
                                .foregroundStyle(isActive ? DesignTokens.canvasBase : DesignTokens.textDim)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isActive ? conditionColorFor(cond) : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
                if conditionOverride != nil {
                    Button("[ RESET AUTO ]") { conditionOverride = nil }
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .buttonStyle(.plain)
                        .padding(.trailing, DesignTokens.blockGutter)
                }
            }
            .padding(.bottom, 8)
        }
        .background(conditionColor.opacity(0.06))
    }

    private func conditionColorFor(_ cond: DealPreloader.PropertyCondition) -> Color {
        switch cond {
        case .ruin:      return DesignTokens.statusCritical
        case .needsWork: return DesignTokens.statusWarn
        case .habitable: return DesignTokens.statusGo
        case .good:      return DesignTokens.statusGo
        }
    }

    private var conditionColor: Color {
        switch effectiveCondition {
        case .ruin:      return DesignTokens.statusCritical
        case .needsWork: return DesignTokens.statusWarn
        case .habitable: return DesignTokens.statusGo
        case .good:      return DesignTokens.statusGo
        }
    }

    // MARK: - Field rows

    private var sectionRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("RENOVATION")
            fieldRow("renovationBudget",
                     label: "Renovation Budget (midpoint)",
                     value: "€\(compactEur((effectiveRenovLow + effectiveRenovHigh) / 2))",
                     note:  "\(effectiveCondition.rawValue) — range €\(compactEur(effectiveRenovLow))–€\(compactEur(effectiveRenovHigh))")

            sectionLabel("INCOME")
            fieldRow("grossPotentialIncome",
                     label: "Gross Potential Income",
                     value: "€\(compactEur(estimate.grossPotentialIncome))/yr",
                     note:  estimate.fieldNotes["grossPotentialIncome"])
            fieldRow("vacancyRate",
                     label: "Vacancy Rate",
                     value: "\(String(format: "%.1f", estimate.vacancyRate))%",
                     note:  estimate.fieldNotes["vacancyRate"])

            sectionLabel("EXPENSES")
            fieldRow("operatingExpenses",
                     label: "Operating Expenses (total)",
                     value: "€\(compactEur(estimate.operatingExpenses))/yr",
                     note:  estimate.fieldNotes["operatingExpenses"])
            fieldRow("opexPropertyManagement",
                     label: "  ↳ Property Management",
                     value: "€\(compactEur(estimate.opexPropertyManagement))/yr",
                     note:  "1.5% of purchase price")
            fieldRow("opexPropertyTax",
                     label: "  ↳ Property Tax",
                     value: "€\(compactEur(estimate.opexPropertyTax))/yr",
                     note:  "\(String(format: "%.2f", estimate.opexPropertyTax / max(1, deal.purchasePrice) * 100))% rate")
            fieldRow("opexInsurance",
                     label: "  ↳ Insurance",
                     value: "€\(compactEur(estimate.opexInsurance))/yr",
                     note:  "\(estimate.benchmarkCity) rate/\(UnitSystemService.shared.areaUnitLabel(for: deal.locationCountry))")
            fieldRow("opexUtilities",
                     label: "  ↳ Utilities",
                     value: "€\(compactEur(estimate.opexUtilities))/yr",
                     note:  "15% of total OpEx")
            fieldRow("opexMaintenance",
                     label: "  ↳ Maintenance",
                     value: "€\(compactEur(estimate.opexMaintenance))/yr",
                     note:  "15% of total OpEx")
            fieldRow("opexCapitalReserves",
                     label: "  ↳ Capital Reserves",
                     value: "€\(compactEur(estimate.opexCapitalReserves))/yr",
                     note:  "1% of purchase price")

            sectionLabel("FINANCING")
            fieldRow("loanAmount",
                     label: "Loan Amount (65% LTV)",
                     value: "€\(compactEur(estimate.loanAmount))",
                     note:  estimate.fieldNotes["loanAmount"])
            fieldRow("interestRate",
                     label: "Interest Rate",
                     value: "\(String(format: "%.1f", estimate.interestRate))%",
                     note:  estimate.fieldNotes["interestRate"])
            fieldRow("exitCapRate",
                     label: "Exit Cap Rate",
                     value: "\(String(format: "%.1f", estimate.exitCapRate))%",
                     note:  "Market prime yield — used for 5-year exit valuation")

            if estimate.hospitalityRoomCount != nil {
                // Season selector
                HStack(spacing: 0) {
                    Text("// HOSPITALITY")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .padding(.leading, DesignTokens.blockGutter)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                    Spacer()
                    HStack(spacing: 1) {
                        ForEach(DealPreloader.SeasonProfile.allCases, id: \.self) { s in
                            let isActive = season == s
                            Button {
                                season = s
                            } label: {
                                Text("\(s.icon) \(s.rawValue.uppercased())")
                                    .porteosMeta()
                                    .foregroundStyle(isActive ? DesignTokens.canvasBase : DesignTokens.textDim)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(isActive ? accent : Color.clear)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, DesignTokens.blockGutter)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                }

                if let rc = estimate.hospitalityRoomCount {
                    fieldRow("hospitalityRoomCount",
                             label: "Room Count",
                             value: "\(rc) rooms",
                             note:  estimate.fieldNotes["hospitalityRoomCount"])
                }
                if let adr = effectiveADR {
                    let baseAdr = estimate.hospitalityADR ?? adr
                    let label = season == .shoulder
                        ? "ADR (annual avg)"
                        : "ADR (\(season.rawValue)) — base €\(String(format: "%.0f", baseAdr))"
                    fieldRow("hospitalityADR",
                             label: label,
                             value: "€\(String(format: "%.0f", adr))",
                             note:  "\(estimate.benchmarkCity) × \(season.rawValue.lowercased()) multiplier")
                }
                if let occ = effectiveOccupancy {
                    let baseOcc = estimate.hospitalityOccupancyRate ?? occ
                    let label = season == .shoulder
                        ? "Occupancy Rate (annual avg)"
                        : "Occupancy (\(season.rawValue)) — base \(String(format: "%.0f", baseOcc))%"
                    fieldRow("hospitalityOccupancyRate",
                             label: label,
                             value: "\(String(format: "%.0f", occ))%",
                             note:  "\(season.rawValue): \(season.occupancyDelta >= 0 ? "+" : "")\(String(format: "%.0f", season.occupancyDelta))pp vs average")
                }
                if let opex = estimate.hospitalityOpExRatio {
                    fieldRow("hospitalityOpExRatio",
                             label: "OpEx Ratio",
                             value: "\(String(format: "%.0f", opex))%",
                             note:  "Industry standard (30–45%)")
                }
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Field row with toggle

    private func fieldRow(_ key: String, label: String, value: String, note: String?) -> some View {
        let isSelected = selected.contains(key)
        let isAlreadySet = isFieldAlreadySet(key)

        return Button {
            if isAlreadySet { return }  // don't toggle already-populated fields
            if isSelected { selected.remove(key) } else { selected.insert(key) }
        } label: {
            HStack(spacing: 10) {
                // Toggle square
                Rectangle()
                    .fill(isAlreadySet ? DesignTokens.textDim.opacity(0.3)
                          : isSelected ? accent : Color.clear)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Rectangle().strokeBorder(
                            isAlreadySet ? DesignTokens.textDim.opacity(0.3)
                            : isSelected ? accent : DesignTokens.dividerStructural,
                            lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .porteosMeta()
                        .foregroundStyle(isAlreadySet ? DesignTokens.textDim : DesignTokens.textSecondary)
                    if let note {
                        Text(note)
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                            .font(.system(size: 9, design: .monospaced))
                    }
                }

                Spacer(minLength: 8)

                if isAlreadySet {
                    Text("// already set")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                } else {
                    Text(value)
                        .porteosMeta()
                        .foregroundStyle(isSelected ? accent : DesignTokens.textDim)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
            .background(isSelected && !isAlreadySet ? accent.opacity(0.04) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAlreadySet)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text("// \(title)")
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Text("\(selected.count) of \(allFields.count) fields selected")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)

            Spacer()

            Button("[ SELECT ALL ]") {
                selected = Set(allFields.filter { !isFieldAlreadySet($0.key) }.map(\.key))
            }
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
            .buttonStyle(.plain)

            Button("[ APPLY SELECTED ]") {
                applySelected()
                onDismiss()
            }
            .porteosMeta()
            .foregroundStyle(DesignTokens.canvasBase)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(selected.isEmpty ? DesignTokens.textDim : accent)
            .buttonStyle(.plain)
            .disabled(selected.isEmpty)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 12)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: - Apply logic

    private struct FieldDef { let key: String }
    private var allFields: [FieldDef] {
        var f: [FieldDef] = [
            .init(key: "renovationBudget"),
            .init(key: "grossPotentialIncome"),
            .init(key: "vacancyRate"),
            .init(key: "operatingExpenses"),
            .init(key: "opexPropertyManagement"),
            .init(key: "opexPropertyTax"),
            .init(key: "opexInsurance"),
            .init(key: "opexUtilities"),
            .init(key: "opexMaintenance"),
            .init(key: "opexCapitalReserves"),
            .init(key: "loanAmount"),
            .init(key: "interestRate"),
            .init(key: "exitCapRate"),
        ]
        if estimate.hospitalityRoomCount != nil {
            f += [
                .init(key: "hospitalityRoomCount"),
                .init(key: "hospitalityADR"),
                .init(key: "hospitalityOccupancyRate"),
                .init(key: "hospitalityOpExRatio"),
            ]
        }
        return f
    }

    private func isFieldAlreadySet(_ key: String) -> Bool {
        switch key {
        case "renovationBudget":          return deal.renovationBudget > 0
        case "grossPotentialIncome":      return deal.grossPotentialIncome > 0
        case "vacancyRate":               return deal.vacancyRate > 0
        case "operatingExpenses":         return deal.operatingExpenses > 0
        case "opexPropertyManagement":    return deal.opexPropertyManagement > 0
        case "opexPropertyTax":           return deal.opexPropertyTax > 0
        case "opexInsurance":             return deal.opexInsurance > 0
        case "opexUtilities":             return deal.opexUtilities > 0
        case "opexMaintenance":           return deal.opexMaintenance > 0
        case "opexCapitalReserves":       return deal.opexCapitalReserves > 0
        case "loanAmount":                return deal.loanAmount > 0
        case "interestRate":              return deal.interestRate > 0
        case "exitCapRate":               return deal.exitCapRate > 0
        case "hospitalityRoomCount":      return deal.hospitalityRoomCount > 0
        case "hospitalityADR":            return deal.hospitalityADR > 0
        case "hospitalityOccupancyRate":  return deal.hospitalityOccupancyRate > 0
        case "hospitalityOpExRatio":      return deal.hospitalityOpExRatio > 0
        default: return false
        }
    }

    private func applySelected() {
        DealHistoryManager.shared.push(deal: deal, label: "Apply market preload (\(estimate.benchmarkCity))")

        let midReno = (effectiveRenovLow + effectiveRenovHigh) / 2

        for key in selected {
            switch key {
            case "renovationBudget":         deal.renovationBudget          = midReno
            case "grossPotentialIncome":     deal.grossPotentialIncome      = estimate.grossPotentialIncome
            case "vacancyRate":              deal.vacancyRate               = estimate.vacancyRate
            case "operatingExpenses":        deal.operatingExpenses         = estimate.operatingExpenses
            case "opexPropertyManagement":   deal.opexPropertyManagement    = estimate.opexPropertyManagement
            case "opexPropertyTax":          deal.opexPropertyTax           = estimate.opexPropertyTax
            case "opexInsurance":            deal.opexInsurance             = estimate.opexInsurance
            case "opexUtilities":            deal.opexUtilities             = estimate.opexUtilities
            case "opexMaintenance":          deal.opexMaintenance           = estimate.opexMaintenance
            case "opexCapitalReserves":      deal.opexCapitalReserves       = estimate.opexCapitalReserves
            case "loanAmount":               deal.loanAmount                = estimate.loanAmount
            case "interestRate":             deal.interestRate              = estimate.interestRate
            case "exitCapRate":              deal.exitCapRate               = estimate.exitCapRate
            case "hospitalityRoomCount":     deal.hospitalityRoomCount      = estimate.hospitalityRoomCount ?? 0
            case "hospitalityADR":           deal.hospitalityADR            = effectiveADR ?? estimate.hospitalityADR ?? 0
            case "hospitalityOccupancyRate": deal.hospitalityOccupancyRate  = effectiveOccupancy ?? estimate.hospitalityOccupancyRate ?? 0
            case "hospitalityOpExRatio":     deal.hospitalityOpExRatio      = estimate.hospitalityOpExRatio ?? 35
            default: break
            }
        }

        deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        deal.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Formatting helpers

    private func compactEur(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.2fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "%.0fk", v / 1_000) }
        return String(format: "%.0f", v)
    }
}
