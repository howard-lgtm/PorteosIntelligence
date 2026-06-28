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
        case propertyName, location, propertyType, purchasePrice, totalArea, notes
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

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let accentTeal    = Color(hex: "#14B8A6")
    private let accentPurple  = Color(hex: "#A855F7")
    private let accentBlue    = Color(hex: "#3B82F6")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

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
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .base:        baseContent
                    case .realEstate:  realEstateContent
                    case .hospitality: hospitalityContent
                    case .design:      designContent
                    case .circular:    circularContent
                    }
                }
                .padding(16)
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
        .frame(width: 560)
    }

    // MARK: Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("deal --edit --asset=\"\(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)\"")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentRust)
                .lineLimit(1)
            Spacer()
            Button { dismiss() } label: {
                Text("✕")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .foregroundStyle(textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(shellSurface)
    }

    // MARK: Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    let isActive = selectedTab == tab
                    Button { selectedTab = tab } label: {
                        VStack(spacing: 0) {
                            Text("[\(tab.rawValue)]")
                                .font(.custom("JetBrains Mono", size: 13).weight(isActive ? .bold : .regular))
                                .foregroundStyle(isActive ? textPrimary : textTertiary)
                                .padding(.horizontal, 10)
                                .frame(height: 26)
                            Rectangle()
                                .fill(isActive ? accentRust : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(height: 28)
                        .clipShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 16)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 1 — BASE
    // ─────────────────────────────────────────────────────────────────────────

    private var baseContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("01 // IDENTITY", color: textTertiary)
            TerminalInputField(label: "Property Name",  placeholder: "Asset Name",     prefix: nil, suffix: nil,  text: $deal.propertyName).focused($focusedField, equals: .propertyName)
            TerminalInputField(label: "Location",       placeholder: "City, Country",  prefix: nil, suffix: nil,  text: $deal.locationCity)
                .focused($focusedField, equals: .location)
                .onSubmit { checkForBenchmark() }

            if showBenchmarkPrompt {
                HStack(spacing: 12) {
                    Text("porteos@system ~ %")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(textTertiary)

                    Text("Market benchmarks available for \(pendingBenchmarkCity).")
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textPrimary)

                    Spacer()

                    Button("[ APPLY ]") {
                        applyBenchmarks()
                        showBenchmarkPrompt = false
                    }
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(accentRust)
                    .buttonStyle(.plain)

                    Button("[ DISMISS ]") {
                        showBenchmarkPrompt = false
                    }
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(shellSurface)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: 1))
                .clipShape(Rectangle())
                .padding(.top, 4)
            }

            TerminalInputField(label: "Property Type",  placeholder: "e.g. Commercial",prefix: nil, suffix: nil,  text: $deal.propertyType).focused($focusedField, equals: .propertyType)

            sectionLabel("02 // ACQUISITION", color: textTertiary)
            TerminalInputField(label: "Purchase Price", placeholder: "0.00", prefix: "€", suffix: nil,  value: $deal.purchasePrice, formatter: currencyFormatter).focused($focusedField, equals: .purchasePrice)
            TerminalInputField(label: "Total Area",     placeholder: "0", prefix: nil, suffix: "m²", text: numStr($deal.totalArea)).focused($focusedField, equals: .totalArea)

            sectionLabel("03 // STATUS", color: textTertiary)
            pickerField(label: "Deal Status") {
                Picker("", selection: $deal.status) {
                    ForEach(DealStatus.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            TerminalInputField(label: "Notes", placeholder: "Optional…", prefix: nil, suffix: nil, text: $deal.notes).focused($focusedField, equals: .notes)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 2 — REAL ESTATE
    // ─────────────────────────────────────────────────────────────────────────

    private var realEstateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("01 // INCOME", color: accentRust)
            TerminalInputField(label: "Gross Potential Income", placeholder: "0.00", prefix: "€",  suffix: nil, value: $deal.grossPotentialIncome, formatter: currencyFormatter).focused($focusedField, equals: .grossPotentialIncome)
            TerminalInputField(label: "Vacancy Rate",           placeholder: "0.00", prefix: nil,  suffix: "%", value: $deal.vacancyRate, formatter: Self.percentFormatter).focused($focusedField, equals: .vacancyRate)
            TerminalInputField(label: "Other Income",           placeholder: "0.00", prefix: "€",  suffix: nil, value: $deal.otherIncome, formatter: currencyFormatter).focused($focusedField, equals: .otherIncome)

            sectionLabel("02 // EXPENSES", color: accentRust)
            TerminalInputField(label: "Operating Expenses",    placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.operatingExpenses,       formatter: currencyFormatter).focused($focusedField, equals: .operatingExpenses)
            TerminalInputField(label: "Property Management",   placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexPropertyManagement,  formatter: currencyFormatter)
            TerminalInputField(label: "Property Tax",          placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexPropertyTax,          formatter: currencyFormatter)
            TerminalInputField(label: "Insurance",             placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexInsurance,            formatter: currencyFormatter)
            TerminalInputField(label: "Utilities",             placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexUtilities,            formatter: currencyFormatter)
            TerminalInputField(label: "Maintenance & Repairs", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexMaintenance,          formatter: currencyFormatter)
            TerminalInputField(label: "Capital Reserves",      placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.opexCapitalReserves,      formatter: currencyFormatter)

            sectionLabel("03 // ACQUISITION", color: accentRust)
            TerminalInputField(label: "Closing Costs",     placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.closingCosts,     formatter: currencyFormatter).focused($focusedField, equals: .closingCosts)
            TerminalInputField(label: "Renovation Budget", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.renovationBudget, formatter: currencyFormatter).focused($focusedField, equals: .renovationBudget)

            sectionLabel("04 // LEVERAGE", color: accentRust)
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
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("01 // OPERATIONAL", color: accentTeal)
            TerminalInputField(label: "Room Count",     placeholder: "0",   prefix: nil, suffix: nil, text: intStr($deal.hospitalityRoomCount)).focused($focusedField, equals: .roomCount)
            TerminalInputField(label: "ADR",            placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityADR, formatter: currencyFormatter).focused($focusedField, equals: .adr)
            TerminalInputField(label: "Occupancy Rate", placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityOccupancyRate, formatter: Self.percentFormatter).focused($focusedField, equals: .occupancyRate)
            TerminalInputField(label: "OpEx Ratio",     placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityOpExRatio, formatter: Self.percentFormatter).focused($focusedField, equals: .opexRatio)

            sectionLabel("02 // REVENUE STREAMS", color: accentTeal)
            TerminalInputField(label: "F&B Revenue",     placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityFBRevenue,      formatter: currencyFormatter).focused($focusedField, equals: .fAndBRevenue)
            TerminalInputField(label: "Spa Revenue",     placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalitySpaRevenue,     formatter: currencyFormatter).focused($focusedField, equals: .spaRevenue)
            TerminalInputField(label: "Meeting Revenue", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityMeetingRevenue,  formatter: currencyFormatter).focused($focusedField, equals: .meetingRevenue)
            TerminalInputField(label: "Other Revenue",   placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityOtherRevenue,    formatter: currencyFormatter).focused($focusedField, equals: .otherRevenue)

            sectionLabel("03 // DISTRIBUTION", color: accentTeal)
            TerminalInputField(label: "Direct Booking",    placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityDirectBookingPct, formatter: Self.percentFormatter).focused($focusedField, equals: .directBooking)
            TerminalInputField(label: "OTA Booking",       placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.hospitalityOTABookingPct, formatter: Self.percentFormatter).focused($focusedField, equals: .otaBooking)
            TerminalInputField(label: "Distribution Cost", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.hospitalityDistributionCost, formatter: currencyFormatter).focused($focusedField, equals: .distributionCost)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 4 — DESIGN
    // ─────────────────────────────────────────────────────────────────────────

    private var designContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("01 // SPACE_EFFICIENCY", color: accentPurple)
            TerminalInputField(label: "Gross Floor Area (GFA)",  placeholder: "0",   prefix: nil, suffix: "m²", text: numStr($deal.designGFA)).focused($focusedField, equals: .gfa)
            TerminalInputField(label: "Net Internal Area (NIA)", placeholder: "0",   prefix: nil, suffix: "m²", text: numStr($deal.designNIA)).focused($focusedField, equals: .nia)
            TerminalInputField(label: "Circulation",             placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designCirculationPct, formatter: Self.percentFormatter).focused($focusedField, equals: .circulation)
            TerminalInputField(label: "Space Utilization",       placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designSpaceUtilization, formatter: Self.percentFormatter).focused($focusedField, equals: .spaceUtilization)

            sectionLabel("02 // WELLNESS", color: accentPurple)
            TerminalInputField(label: "Daylighting Coverage", placeholder: "0.0", prefix: nil, suffix: "%",   value: $deal.designDaylighting, formatter: Self.percentFormatter).focused($focusedField, equals: .daylightingCoverage)
            TerminalInputField(label: "CO2 Levels",           placeholder: "0",   prefix: nil, suffix: "ppm", text: numStr($deal.designCO2ppm)).focused($focusedField, equals: .co2Levels)
            TerminalInputField(label: "Air Changes Per Hour", placeholder: "0.0", prefix: nil, suffix: "ACH", text: numStr($deal.designACH, decimals: 2)).focused($focusedField, equals: .airChangesPerHour)
            TerminalInputField(label: "Thermal Comfort",      placeholder: "0.0", prefix: nil, suffix: "%",   value: $deal.designThermalComfort, formatter: Self.percentFormatter).focused($focusedField, equals: .thermalComfort)
            TerminalInputField(label: "Acoustic Comfort",     placeholder: "0.0", prefix: nil, suffix: "%",   value: $deal.designAcousticComfort, formatter: Self.percentFormatter).focused($focusedField, equals: .acousticComfort)

            sectionLabel("03 // BIOPHILIC", color: accentPurple)
            TerminalInputField(label: "Biophilic Elements",  placeholder: "0",   prefix: nil, suffix: nil,  text: intStr($deal.designBiophilicCount)).focused($focusedField, equals: .biophilicElements)
            TerminalInputField(label: "Green Wall Coverage", placeholder: "0",   prefix: nil, suffix: "m²", text: numStr($deal.designGreenWallM2)).focused($focusedField, equals: .greenWallCoverage)
            TerminalInputField(label: "Views to Nature",     placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designViewsToNaturePct, formatter: Self.percentFormatter).focused($focusedField, equals: .viewsToNature)
            TerminalInputField(label: "Natural Materials",   placeholder: "0.0", prefix: nil, suffix: "%",  value: $deal.designNaturalMaterialsPct, formatter: Self.percentFormatter).focused($focusedField, equals: .naturalMaterials)

            sectionLabel("04 // ADAPTABILITY", color: accentPurple)
            TerminalInputField(label: "Movable Partition",  placeholder: "0.0", prefix: nil, suffix: "%",    value: $deal.designMovablePartitionPct, formatter: Self.percentFormatter).focused($focusedField, equals: .movablePartition)
            TerminalInputField(label: "Multi-Use Spaces",   placeholder: "0",   prefix: nil, suffix: nil,    text: intStr($deal.designMultiUseSpaces)).focused($focusedField, equals: .multiUseSpaces)
            TerminalInputField(label: "Adaptability Score", placeholder: "0",   prefix: nil, suffix: "/100", text: numStr($deal.designAdaptabilityScore)).focused($focusedField, equals: .adaptabilityScore)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 5 — CIRCULAR
    // ─────────────────────────────────────────────────────────────────────────

    private var circularContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("01 // MATERIAL_FLOW", color: accentBlue)
            TerminalInputField(label: "Total Construction Cost",  placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.circularTotalConstructionCost,  formatter: currencyFormatter).focused($focusedField, equals: .totalConstructionCost)
            TerminalInputField(label: "Repurposed Material Cost", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.circularRepurposedMaterialCost, formatter: currencyFormatter).focused($focusedField, equals: .repurposedMaterialCost)
            TerminalInputField(label: "Kg Materials Used",        placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularKgMaterialsUsed)).focused($focusedField, equals: .kgMaterialsUsed)
            TerminalInputField(label: "Kg Materials Returned",    placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularKgMaterialsReturned)).focused($focusedField, equals: .kgMaterialsReturned)
            TerminalInputField(label: "Kg Materials Disposed",    placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularKgMaterialsDisposed)).focused($focusedField, equals: .kgMaterialsDisposed)
            TerminalInputField(label: "Waste Generated",          placeholder: "0", prefix: nil,  suffix: "kg", text: numStr($deal.circularWasteGenerated)).focused($focusedField, equals: .wasteGenerated)
            TerminalInputField(label: "Recycled Content",         placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.circularRecycledContentPct, formatter: Self.percentFormatter).focused($focusedField, equals: .recycledContent)
            TerminalInputField(label: "Renewable Content",        placeholder: "0.0", prefix: nil, suffix: "%", value: $deal.circularRenewableContentPct, formatter: Self.percentFormatter).focused($focusedField, equals: .renewableContent)

            sectionLabel("02 // CARBON", color: accentBlue)
            TerminalInputField(label: "CO2 Embodied",         placeholder: "0",   prefix: nil, suffix: "kg",        text: numStr($deal.circularCO2Embodied)).focused($focusedField, equals: .co2Embodied)
            TerminalInputField(label: "Operational Carbon",   placeholder: "0.0", prefix: nil, suffix: "tCO2e/yr",  text: numStr($deal.circularOperationalCarbon, decimals: 2)).focused($focusedField, equals: .operationalCarbon)
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
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textSecondary)
                    .frame(height: 32)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { commitChanges() } label: {
                Text("[ COMMIT_CHANGES ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(Color(hex: "#0F1115"))
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(accentRust)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
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
        dismiss()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        return formatter
    }()

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

    private func sectionLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 13).weight(.bold))
            .foregroundStyle(color)
    }

    private func pickerField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .tracking(0.05)
                .foregroundStyle(textTertiary)

            content()
                .font(.custom("JetBrains Mono", size: 14))
                .foregroundStyle(textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 32)
                .padding(.horizontal, 8)
                .background(shellBg)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: 1))
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
        .background(Color(hex: "#0F1115"))
}
