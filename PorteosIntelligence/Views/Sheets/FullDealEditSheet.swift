import SwiftUI
import SwiftData

// MARK: - FullDealEditSheet

struct FullDealEditSheet: View {

    @Bindable var deal: PropertyDeal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: Focus

    enum Field: String, Hashable, CaseIterable {
        // BASE
        case propertyName, address, location, propertyType, purchasePrice, totalArea, notes
        // REAL ESTATE
        case grossPotentialIncome, vacancyRate, operatingExpenses, otherIncome
        case loanAmount, interestRate, amortizationMonths, closingCosts, renovationBudget
        // HOSPITALITY
        case roomCount, adr, occupancyRate, opexRatio
        case fAndBRevenue, spaRevenue, meetingRevenue, otherRevenue
        case directBooking, otaBooking, distributionCost
        // DESIGN
        case gfa, nia, circulation, spaceUtilization
        case daylightingCoverage, co2Levels, airChangesPerHour, thermalComfort, acousticComfort
        case biophilicElements, greenWallCoverage, viewsToNature, naturalMaterials
        case movablePartition, multiUseSpaces, adaptabilityScore
        // CIRCULAR
        case totalConstructionCost, repurposedMaterialCost
        case kgMaterialsUsed, kgMaterialsReturned, kgMaterialsDisposed, wasteGenerated
        case recycledContent, renewableContent, co2Embodied, operationalCarbon
        case buildingArea, waterRecyclingRate
    }

    @FocusState private var focusedField: Field?

    // MARK: Tokens

    private let shellBg       = DesignTokens.canvasBase
    private let shellSurface  = DesignTokens.surfacePanel
    private let shellBorder   = DesignTokens.dividerStructural
    private let accentRust    = DesignTokens.accentRust
    private let accentTeal    = ProfileType.hospitality.accentColor
    private let accentPurple  = ProfileType.design.accentColor
    private let accentBlue    = ProfileType.circular.accentColor
    private let textPrimary   = DesignTokens.textPrimary
    private let textSecondary = DesignTokens.textSecondary
    private let textTertiary  = DesignTokens.textDim

    // MARK: Tab

    private enum Tab: String, CaseIterable {
        case base        = "BASE"
        case realEstate  = "REAL_ESTATE"
        case hospitality = "HOSPITALITY"
        case design      = "DESIGN"
        case circular    = "CIRCULAR"
    }

    @State private var selectedTab: Tab = .base

    // MARK: Benchmark State
    @State private var showBenchmarkPrompt:  Bool   = false
    @State private var pendingBenchmarkCity: String = ""

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)
            tabBar
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch selectedTab {
                    case .base:        baseContent
                    case .realEstate:  realEstateContent
                    case .hospitality: hospitalityContent
                    case .design:      designContent
                    case .circular:    circularContent
                    }
                }
                .padding(DesignTokens.blockGutter)
            }
            .onKeyPress(.tab) {
                guard let current = focusedField,
                      let idx = Field.allCases.firstIndex(of: current) else { return .ignored }
                let next = Field.allCases.index(after: idx)
                if next < Field.allCases.endIndex {
                    focusedField = Field.allCases[next]
                }
                return .handled
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            footer
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 520)
        .onAppear {
            // Capture state before the user makes any edits.
            // Because FullDealEditSheet uses @Bindable, fields update the deal
            // in real-time; we must snapshot here, not at commit time.
            DealHistoryManager.shared.push(
                deal:  deal,
                label: "Edit: \(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)"
            )
        }
    }

    // MARK: Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(textTertiary)
            Text("deal --edit --asset=\"\(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)\"")
                .porteosModuleCmd()
                .foregroundStyle(accentRust)
                .lineLimit(1)
            Spacer()
            Button { dismiss() } label: {
                Text("[ × ]")
                    .porteosModuleCmd()
                    .foregroundStyle(textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(shellSurface)
    }

    // MARK: Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(Tab.allCases.enumerated()), id: \.element) { idx, tab in
                    if idx > 0 {
                        Rectangle()
                            .fill(shellBorder)
                            .frame(width: DesignTokens.dividerWidth, height: 18)
                    }
                    tabButton(tab)
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
        }
        .frame(height: DesignTokens.rowHeightHeader + 2)
        .background(shellSurface)
    }

    private func tabButton(_ tab: Tab) -> some View {
        let isActive = selectedTab == tab
        let accent   = tabAccent(tab)
        return Button { selectedTab = tab } label: {
            VStack(spacing: 0) {
                Spacer()
                Text(tab.rawValue)
                    .porteosTextStyle(.shellNav(isActive: isActive))
                    .foregroundStyle(isActive ? textPrimary : textTertiary)
                    .padding(.horizontal, 10)
                Spacer()
                Rectangle()
                    .fill(isActive ? accent : Color.clear)
                    .frame(height: 2)
            }
            .frame(height: DesignTokens.rowHeightHeader + 2)
        }
        .buttonStyle(.plain)
    }

    private func tabAccent(_ tab: Tab) -> Color {
        switch tab {
        case .base:        return textPrimary
        case .realEstate:  return accentRust
        case .hospitality: return accentTeal
        case .design:      return accentPurple
        case .circular:    return accentBlue
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 1 — BASE
    // ─────────────────────────────────────────────────────────────────────────

    private var baseContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("IDENTIFICATION")
            TerminalInputField(label: "Property Name", placeholder: "Asset Name", prefix: nil, suffix: nil, text: $deal.propertyName)
                .focused($focusedField, equals: .propertyName)
            TerminalInputField(label: "Address", placeholder: "Street address", prefix: nil, suffix: nil, text: $deal.address)
                .focused($focusedField, equals: .address)
            TerminalInputField(label: "City", placeholder: "City, Country", prefix: nil, suffix: nil, text: $deal.locationCity)
                .focused($focusedField, equals: .location)
                .onSubmit { checkForBenchmark() }

            if showBenchmarkPrompt {
                HStack(spacing: 12) {
                    Text("porteos@system ~ %")
                        .porteosMeta()
                        .foregroundStyle(textTertiary)

                    Text("Market benchmarks available for \(pendingBenchmarkCity).")
                        .porteosRowValue()
                        .foregroundStyle(textPrimary)

                    Spacer()

                    Button("[ APPLY ]") {
                        applyBenchmarks()
                        showBenchmarkPrompt = false
                    }
                    .porteosButtonPrimary()
                    .foregroundStyle(accentRust)
                    .buttonStyle(.plain)

                    Button("[ DISMISS ]") {
                        showBenchmarkPrompt = false
                    }
                    .porteosRowLabel()
                    .foregroundStyle(textTertiary)
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(shellSurface)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
                .clipShape(Rectangle())
                .padding(.top, 4)
            }

            sectionLabel("FINANCIAL DETAILS")
            TerminalInputField(label: "Purchase Price", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.purchasePrice, formatter: currencyFormatter)
                .focused($focusedField, equals: .purchasePrice)
            statusPickerField
            TerminalInputField(label: "Area m²", placeholder: "0", prefix: nil, suffix: "m²", text: numStr($deal.totalArea))
                .focused($focusedField, equals: .totalArea)
            TerminalComboboxField(
                label: "Property Type",
                placeholder: "e.g. Hotel, Office A-Class",
                text: $deal.propertyType,
                suggestions: { DealPropertyTypes.suggestions(matching: $0) },
                focus: $focusedField,
                equals: .propertyType
            )

            sectionLabel("NOTES")
            notesField
        }
    }

    private var statusPickerField: some View {
        pickerField(label: "Status") {
            Picker("", selection: $deal.status) {
                ForEach(DealStatus.allCases, id: \.self) {
                    Text($0.rawValue.uppercased()).tag($0)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var notesFieldHeight: CGFloat {
        let lineCount = max(1, deal.notes.components(separatedBy: .newlines).count)
        let wrapped   = max(0, deal.notes.count / 72)
        return min(320, max(140, CGFloat(lineCount + wrapped + 2) * 18))
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .porteosMeta()
                .foregroundStyle(textTertiary)

            TextEditor(text: $deal.notes)
                .porteosRowValue()
                .foregroundStyle(textPrimary)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: notesFieldHeight, maxHeight: 320)
                .background(shellBg)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
                .clipShape(Rectangle())
                .focused($focusedField, equals: .notes)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 2 — REAL ESTATE
    // ─────────────────────────────────────────────────────────────────────────

    private var realEstateContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("INCOME", color: accentRust)
            TerminalInputField(label: "Gross Potential Income", placeholder: "0.00", prefix: "€",  suffix: nil, value: $deal.grossPotentialIncome, formatter: currencyFormatter).focused($focusedField, equals: .grossPotentialIncome)
            TerminalInputField(label: "Vacancy Rate",           placeholder: "0.00", prefix: nil,  suffix: "%", value: $deal.vacancyRate, formatter: Self.percentFormatter).focused($focusedField, equals: .vacancyRate)
            TerminalInputField(label: "Other Income",           placeholder: "0.00", prefix: "€",  suffix: nil, value: $deal.otherIncome, formatter: currencyFormatter).focused($focusedField, equals: .otherIncome)

            sectionLabel("EXPENSES", color: accentRust)
            TerminalInputField(label: "Operating Expenses",    placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.operatingExpenses,       formatter: currencyFormatter).focused($focusedField, equals: .operatingExpenses)
            TerminalInputField(label: "Property Management",   placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexPropertyManagement,  formatter: currencyFormatter)
            TerminalInputField(label: "Property Tax",          placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexPropertyTax,          formatter: currencyFormatter)
            TerminalInputField(label: "Insurance",             placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexInsurance,            formatter: currencyFormatter)
            TerminalInputField(label: "Utilities",             placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexUtilities,            formatter: currencyFormatter)
            TerminalInputField(label: "Maintenance & Repairs", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexMaintenance,          formatter: currencyFormatter)
            TerminalInputField(label: "Capital Reserves",      placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexCapitalReserves,      formatter: currencyFormatter)

            sectionLabel("ACQUISITION", color: accentRust)
            TerminalInputField(label: "Closing Costs",     placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.closingCosts,     formatter: currencyFormatter).focused($focusedField, equals: .closingCosts)
            TerminalInputField(label: "Renovation Budget", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.renovationBudget, formatter: currencyFormatter).focused($focusedField, equals: .renovationBudget)

            sectionLabel("LEVERAGE", color: accentRust)
            TerminalInputField(label: "Loan Amount",         placeholder: "0.00", prefix: "€",  suffix: nil,  value: $deal.loanAmount, formatter: currencyFormatter).focused($focusedField, equals: .loanAmount)
            TerminalInputField(label: "Interest Rate",       placeholder: "0.0", prefix: nil,  suffix: "%",  value: $deal.interestRate, formatter: Self.percentFormatter).focused($focusedField, equals: .interestRate)
            TerminalInputField(label: "Amortization Months", placeholder: "360", prefix: nil,  suffix: "mo", text: intStr($deal.amortizationMonths)).focused($focusedField, equals: .amortizationMonths)
            TerminalInputField(label: "Exit Cap Rate",       placeholder: "0.0", prefix: nil,  suffix: "%",  value: $deal.exitCapRate, formatter: Self.percentFormatter)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 3 — HOSPITALITY
    // ─────────────────────────────────────────────────────────────────────────

    private var hospitalityContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("OPERATIONAL", color: accentTeal)
            TerminalInputField(label: "Room Count",     placeholder: "0",   prefix: nil, suffix: nil, text: intStr($deal.hospitalityRoomCount)).focused($focusedField, equals: .roomCount)
            TerminalInputField(label: "ADR",            placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityADR, formatter: currencyFormatter).focused($focusedField, equals: .adr)
            TerminalInputField(label: "Occupancy Rate", placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityOccupancyRate, formatter: Self.percentFormatter).focused($focusedField, equals: .occupancyRate)
            TerminalInputField(label: "OpEx Ratio",     placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityOpExRatio, formatter: Self.percentFormatter).focused($focusedField, equals: .opexRatio)

            sectionLabel("REVENUE STREAMS", color: accentTeal)
            TerminalInputField(label: "F&B Revenue",     placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityFBRevenue,      formatter: currencyFormatter).focused($focusedField, equals: .fAndBRevenue)
            TerminalInputField(label: "Spa Revenue",     placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalitySpaRevenue,     formatter: currencyFormatter).focused($focusedField, equals: .spaRevenue)
            TerminalInputField(label: "Meeting Revenue", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityMeetingRevenue,  formatter: currencyFormatter).focused($focusedField, equals: .meetingRevenue)
            TerminalInputField(label: "Other Revenue",   placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityOtherRevenue,    formatter: currencyFormatter).focused($focusedField, equals: .otherRevenue)

            sectionLabel("DISTRIBUTION", color: accentTeal)
            TerminalInputField(label: "Direct Booking",    placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityDirectBookingPct, formatter: Self.percentFormatter).focused($focusedField, equals: .directBooking)
            TerminalInputField(label: "OTA Booking",       placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityOTABookingPct, formatter: Self.percentFormatter).focused($focusedField, equals: .otaBooking)
            TerminalInputField(label: "Distribution Cost", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityDistributionCost, formatter: currencyFormatter).focused($focusedField, equals: .distributionCost)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 4 — DESIGN
    // ─────────────────────────────────────────────────────────────────────────

    private var designContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SPACE EFFICIENCY", color: accentPurple)
            TerminalInputField(label: "Gross Floor Area (GFA)",  placeholder: "0",   prefix: nil, suffix: "m²", text: numStr($deal.designGFA)).focused($focusedField, equals: .gfa)
            TerminalInputField(label: "Net Internal Area (NIA)", placeholder: "0",   prefix: nil, suffix: "m²", text: numStr($deal.designNIA)).focused($focusedField, equals: .nia)
            TerminalInputField(label: "Circulation",             placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designCirculationPct, formatter: Self.percentFormatter).focused($focusedField, equals: .circulation)
            TerminalInputField(label: "Space Utilization",       placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designSpaceUtilization, formatter: Self.percentFormatter).focused($focusedField, equals: .spaceUtilization)

            sectionLabel("WELLNESS", color: accentPurple)
            TerminalInputField(label: "Daylighting Coverage", placeholder: "0.0", prefix: nil, suffix: "%",   value: $deal.designDaylighting, formatter: Self.percentFormatter).focused($focusedField, equals: .daylightingCoverage)
            TerminalInputField(label: "CO2 Levels",           placeholder: "0",   prefix: nil, suffix: "ppm", text: numStr($deal.designCO2ppm)).focused($focusedField, equals: .co2Levels)
            TerminalInputField(label: "Air Changes Per Hour", placeholder: "0.0", prefix: nil, suffix: "ACH", text: numStr($deal.designACH, decimals: 2)).focused($focusedField, equals: .airChangesPerHour)
            TerminalInputField(label: "Thermal Comfort",      placeholder: "0.0", prefix: nil, suffix: "%",   value: $deal.designThermalComfort, formatter: Self.percentFormatter).focused($focusedField, equals: .thermalComfort)
            TerminalInputField(label: "Acoustic Comfort",     placeholder: "0.0", prefix: nil, suffix: "%",   value: $deal.designAcousticComfort, formatter: Self.percentFormatter).focused($focusedField, equals: .acousticComfort)

            sectionLabel("BIOPHILIC", color: accentPurple)
            TerminalInputField(label: "Biophilic Elements",  placeholder: "0",   prefix: nil, suffix: nil,  text: intStr($deal.designBiophilicCount)).focused($focusedField, equals: .biophilicElements)
            TerminalInputField(label: "Green Wall Coverage", placeholder: "0",   prefix: nil, suffix: "m²", text: numStr($deal.designGreenWallM2)).focused($focusedField, equals: .greenWallCoverage)
            TerminalInputField(label: "Views to Nature",     placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designViewsToNaturePct, formatter: Self.percentFormatter).focused($focusedField, equals: .viewsToNature)
            TerminalInputField(label: "Natural Materials",   placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designNaturalMaterialsPct, formatter: Self.percentFormatter).focused($focusedField, equals: .naturalMaterials)

            sectionLabel("ADAPTABILITY", color: accentPurple)
            TerminalInputField(label: "Movable Partition",  placeholder: "0.0", prefix: nil, suffix: "%",    value: $deal.designMovablePartitionPct, formatter: Self.percentFormatter).focused($focusedField, equals: .movablePartition)
            TerminalInputField(label: "Multi-Use Spaces",   placeholder: "0",   prefix: nil, suffix: nil,    text: intStr($deal.designMultiUseSpaces)).focused($focusedField, equals: .multiUseSpaces)
            TerminalInputField(label: "Adaptability Score", placeholder: "0",   prefix: nil, suffix: "/100", text: numStr($deal.designAdaptabilityScore)).focused($focusedField, equals: .adaptabilityScore)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 5 — CIRCULAR
    // ─────────────────────────────────────────────────────────────────────────

    private var circularContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("MATERIAL FLOW", color: accentBlue)
            designCircularSyncBar
            TerminalInputField(label: "Total Construction Cost",  placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.circularTotalConstructionCost,  formatter: currencyFormatter).focused($focusedField, equals: .totalConstructionCost)
            TerminalInputField(label: "Repurposed Material Cost", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.circularRepurposedMaterialCost, formatter: currencyFormatter).focused($focusedField, equals: .repurposedMaterialCost)
            TerminalInputField(label: "Kg Materials Used",        placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularKgMaterialsUsed)).focused($focusedField, equals: .kgMaterialsUsed)
            TerminalInputField(label: "Kg Materials Returned",    placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularKgMaterialsReturned)).focused($focusedField, equals: .kgMaterialsReturned)
            TerminalInputField(label: "Kg Materials Disposed",    placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularKgMaterialsDisposed)).focused($focusedField, equals: .kgMaterialsDisposed)
            TerminalInputField(label: "Waste Generated",          placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularWasteGenerated)).focused($focusedField, equals: .wasteGenerated)
            TerminalInputField(label: "Recycled Content",         placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.circularRecycledContentPct, formatter: Self.percentFormatter).focused($focusedField, equals: .recycledContent)
            TerminalInputField(label: "Renewable Content",        placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.circularRenewableContentPct, formatter: Self.percentFormatter).focused($focusedField, equals: .renewableContent)

            sectionLabel("CARBON", color: accentBlue)
            TerminalInputField(label: "CO2 Embodied",         placeholder: "0",   prefix: nil, suffix: "kg",        text: numStr($deal.circularCO2Embodied)).focused($focusedField, equals: .co2Embodied)
            TerminalInputField(label: "Operational Carbon",   placeholder: "0.00", prefix: nil, suffix: "tCO2e/yr",  value: $deal.circularOperationalCarbon, formatter: Self.carbonFormatter).focused($focusedField, equals: .operationalCarbon)
            TerminalInputField(label: "Building Area",        placeholder: "0",   prefix: nil, suffix: "m²",        text: numStr($deal.circularBuildingAreaM2)).focused($focusedField, equals: .buildingArea)
            TerminalInputField(label: "Water Recycling Rate", placeholder: "0.0", prefix: nil, suffix: "%",         value: $deal.circularWaterRecyclingRate, formatter: Self.percentFormatter).focused($focusedField, equals: .waterRecyclingRate)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Footer
    // ─────────────────────────────────────────────────────────────────────────

    private var footer: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
            }
            .buttonStyle(TerminalButtonStyle(outlined: .muted))

            Spacer()

            Button { commitChanges() } label: {
                Text("[ SAVE ]")
            }
            .buttonStyle(TerminalButtonStyle(color: .rust))
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Commit
    // ─────────────────────────────────────────────────────────────────────────

    private func commitChanges() {
        let viewModel = PropertyDealViewModel(deal: deal)
        deal.porteosScore = viewModel.porteosScore.finalScore
        deal.updatedAt    = Date()
        do {
            try modelContext.save()
            print("[SUCCESS] Deal saved: \(deal.propertyName)")
        } catch {
            print("[ERROR] Failed to save: \(error)")
        }
        // Record metrics into the trend time-series for this city
        TrendRecorder.record(deal, context: modelContext, source: "portfolio")
        dismiss()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static let percentFormatter: NumberFormatter = {
        decimalFormatter(maxFractionDigits: 2)
    }()

    private static let carbonFormatter: NumberFormatter = {
        let formatter = decimalFormatter(maxFractionDigits: 2)
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static func decimalFormatter(maxFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        return formatter
    }

    // MARK: Design ↔ Circular sync

    private var designCircularSyncBar: some View {
        let hasGFA      = deal.designGFA > 0
        let hasReno     = deal.renovationBudget > 0
        let hasArea     = deal.totalArea > 0

        return Group {
            if hasGFA || hasReno || hasArea {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Design & acquisition fields available — pull into material flow:")
                        .porteosRowValue()
                        .foregroundStyle(textPrimary)

                    HStack(spacing: 8) {
                        if hasGFA {
                            syncButton("[ GFA → AREA ]") {
                                deal.circularBuildingAreaM2 = deal.designGFA
                            }
                        } else if hasArea {
                            syncButton("[ AREA → BUILDING ]") {
                                deal.circularBuildingAreaM2 = deal.totalArea
                            }
                        }

                        if hasReno {
                            syncButton("[ RENO → COST ]") {
                                deal.circularTotalConstructionCost = deal.renovationBudget
                            }
                        }

                        if let estimate = estimatedConstructionCost {
                            syncButton("[ EST. COST ]") {
                                deal.circularTotalConstructionCost = estimate
                            }
                        }
                    }
                }
                .padding(8)
                .background(shellSurface)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
                .clipShape(Rectangle())
            }
        }
    }

    private var estimatedConstructionCost: Double? {
        guard deal.designGFA > 0 else { return nil }
        if let metrics = MarketBenchmarks.benchmark(for: deal.locationCity) {
            return deal.designGFA * metrics.avgConstructionCostPerSqm
        }
        return nil
    }

    private func syncButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .porteosButtonPrimary()
            .foregroundStyle(accentBlue)
            .buttonStyle(.plain)
    }

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = "EUR"
        return formatter
    }()

    private func numStr(_ value: Binding<Double>, decimals: Int = 0) -> Binding<String> {
        Binding<String>(
            get: {
                let v = value.wrappedValue
                guard v > 0 else { return "" }
                return decimals == 0 ? "\(Int(v))" : String(format: "%.\(decimals)f", v)
            },
            set: { str in
                if let d = Double(str.filter { $0.isNumber || $0 == "." }) {
                    value.wrappedValue = d
                } else if str.isEmpty {
                    value.wrappedValue = 0
                }
            }
        )
    }

    private func intStr(_ value: Binding<Int>) -> Binding<String> {
        Binding<String>(
            get: { value.wrappedValue == 0 ? "" : "\(value.wrappedValue)" },
            set: { str in value.wrappedValue = Int(str.filter(\.isNumber)) ?? value.wrappedValue }
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Benchmark Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private func checkForBenchmark() {
        guard !deal.locationCity.isEmpty else { return }
        if let _ = MarketBenchmarks.benchmark(for: deal.locationCity) {
            pendingBenchmarkCity = deal.locationCity
            showBenchmarkPrompt  = true
        }
    }

    private func applyBenchmarks() {
        guard let metrics = MarketBenchmarks.benchmark(for: deal.locationCity) else { return }
        // Real Estate tab
        deal.vacancyRate = metrics.avgVacancyRate
        // Calculate OpEx based on totalArea
        if deal.totalArea > 0 {
            deal.operatingExpenses = metrics.avgOpExPerSqm * deal.totalArea
        }
        // Hospitality tab
        deal.hospitalityADR           = metrics.avgADR
        deal.hospitalityOccupancyRate = metrics.avgOccupancyRate
        // Design tab
        deal.designDaylighting = metrics.typicalDaylighting
    }

    private func sectionLabel(_ text: String, color: Color = DesignTokens.textDim) -> some View {
        Text("// \(text)")
            .porteosMeta()
            .foregroundStyle(color)
            .padding(.top, 4)
    }

    private func pickerField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .porteosMeta()
                .foregroundStyle(textTertiary)

            content()
                .porteosRowValue()
                .foregroundStyle(textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: DesignTokens.rowHeightHeader)
                .padding(.horizontal, 8)
                .background(shellBg)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
                .clipShape(Rectangle())
        }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal = PropertyDeal(
        propertyName:         "Lisbon Office Block A",
        propertyType:         "Commercial",
        locationCity:         "Lisbon",
        purchasePrice:        1_250_000,
        grossPotentialIncome: 125_000,
        vacancyRate:          5,
        operatingExpenses:    45_000,
        loanAmount:           937_500,
        interestRate:         4.5,
        amortizationMonths:   360
    )
    container.mainContext.insert(deal)
    return FullDealEditSheet(deal: deal)
        .modelContainer(container)
        .background(DesignTokens.canvasBase)
}
