import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

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

    // MARK: Research Import State
    @State private var showResearchImporter: Bool          = false
    @State private var researchImportResult: String?       = nil   // success/failure line

    // MARK: Preload State
    @State private var showPreloadReview: Bool             = false
    @State private var preloadEstimate: DealPreloader.PreloadEstimate? = nil

    // MARK: Cancel revert — snapshot captured before any edits
    @State private var openSnapshot: DealSnapshot? = nil

    // MARK: Media
    @State private var showMediaGallery: Bool = false

    // MARK: GPS manual entry
    @State private var gpsEntry: String = ""

    // MARK: Live score — single source of truth via PropertyDealViewModel (includes Design score)
    private var liveScore: (score: Double, grade: String, color: Color)? {
        let result = PropertyDealViewModel(deal: deal).porteosScore
        let s = result.finalScore
        guard s > 0 else { return nil }
        let color: Color = s >= 65 ? DesignTokens.statusGo
                         : s >= 50 ? DesignTokens.statusWarn
                         : DesignTokens.statusCritical
        return (s, result.scoreGrade, color)
    }

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
            mediaStrip
            Rectangle().fill(shellBorder).frame(height: 1)
            footer
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 520)
        .alert("Validation Errors", isPresented: $showValidationAlert) {
            Button("Save Anyway", role: .destructive) { persistAndDismiss() }
            Button("Fix Issues", role: .cancel) {}
        } message: {
            Text(validationErrors.map { "• \($0.field): \($0.message)" }.joined(separator: "\n"))
        }
        .sheet(isPresented: $showMediaGallery) {
            DealMediaGalleryView(deal: deal)
                .frame(width: 480, height: 700)
        }
        .onAppear {
            // Capture a full snapshot before any edits for Cancel revert.
            // @Bindable writes immediately to SwiftData; snapshot is the only way to undo.
            let snap = DealSnapshot(
                deal: deal,
                label: "Edit: \(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)"
            )
            openSnapshot = snap
            DealHistoryManager.shared.push(
                deal:  deal,
                label: snap.label
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
                .truncationMode(.tail)

            Spacer(minLength: 8)

            // Live score chip — updates as fields change
            if let live = liveScore {
                HStack(spacing: 4) {
                    Text("\(Int(live.score.rounded()))")
                        .porteosMeta()
                        .foregroundStyle(live.color)
                        .monospacedDigit()
                    Text(live.grade)
                        .porteosMeta()
                        .foregroundStyle(live.color)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(live.color.opacity(0.1))
                .overlay { Rectangle().strokeBorder(live.color.opacity(0.4), lineWidth: 1) }
                .padding(.trailing, 8)
            }

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
            TerminalComboboxField(
                label: "City",
                placeholder: "Start typing…",
                text: $deal.locationCity,
                suggestions: { query in Self.citySuggestions(for: query) },
                focus: $focusedField,
                equals: .location
            )
            .onChange(of: deal.locationCity) { _, _ in checkForBenchmark() }

            TerminalComboboxField(
                label: "Country",
                placeholder: "e.g. Portugal, Spain",
                text: $deal.locationCountry,
                suggestions: { query in Self.countrySuggestions(for: query) }
            )

            gpsCoordinatesField

            // Preload button — appears when city + area are set
            if !deal.locationCity.isEmpty && deal.totalArea > 0 {
                Button {
                    preloadEstimate = DealPreloader.estimate(
                        city:          deal.locationCity,
                        area:          deal.totalArea,
                        landArea:      deal.landArea,
                        purchasePrice: deal.purchasePrice,
                        propertyType:  deal.propertyType,
                        propertyName:  deal.propertyName
                    )
                    if preloadEstimate != nil { showPreloadReview = true }
                } label: {
                    HStack(spacing: 8) {
                        Text("[ PRELOAD MARKET ASSUMPTIONS ]")
                            .porteosRowLabel()
                            .foregroundStyle(accentRust)
                        Spacer()
                        Text("// \(deal.locationCity) benchmarks")
                            .porteosMeta()
                            .foregroundStyle(textTertiary)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: DesignTokens.rowHeightData)
                    .background(accentRust.opacity(0.05))
                    .overlay(Rectangle().strokeBorder(accentRust.opacity(0.3), lineWidth: DesignTokens.dividerWidth))
                    .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showPreloadReview) {
                    if let est = preloadEstimate {
                        PreloadReviewSheet(deal: deal, estimate: est) {
                            showPreloadReview = false
                        }
                    }
                }
            }

            sourceURLField

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

            researchImportRow

            sectionLabel("FINANCIAL DETAILS")
            TerminalInputField(label: "Purchase Price", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.purchasePrice, formatter: currencyFormatter)
                .focused($focusedField, equals: .purchasePrice)
            statusPickerField
            TerminalInputField(label: "Area m²", placeholder: "0", prefix: nil, suffix: "m²", text: numStr($deal.totalArea))
                .focused($focusedField, equals: .totalArea)
            TerminalInputField(label: "Land m²", placeholder: "0", prefix: nil, suffix: "m²", text: numStr($deal.landArea))
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

            regulatorySection
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

    // MARK: Research Import

    private var researchImportRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Button("[ IMPORT RESEARCH JSON ]") {
                    showResearchImporter = true
                }
                .porteosRowLabel()
                .foregroundStyle(accentRust)
                .buttonStyle(.plain)

                Spacer()

                if let result = researchImportResult {
                    Text(result)
                        .porteosMeta()
                        .foregroundStyle(result.hasPrefix("//") ? textTertiary : DesignTokens.statusGo)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: DesignTokens.rowHeightData)
            .background(shellBg)
            .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
            .clipShape(Rectangle())
        }
        .fileImporter(
            isPresented: $showResearchImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            guard let url = try? result.get().first,
                  url.startAccessingSecurityScopedResource() else {
                researchImportResult = "// Could not access file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else {
                researchImportResult = "// Could not read file"
                return
            }

            let importResult = DealResearchImporter.apply(json: data, to: deal, context: modelContext)
            if importResult.applied.isEmpty {
                researchImportResult = "// No new fields — already populated"
            } else {
                let gpsNote = importResult.hadGPS ? " · GPS pinned ✓" : ""
                researchImportResult = "Applied: \(importResult.applied.joined(separator: " · "))\(gpsNote)"
            }
        }
    }

    @ViewBuilder
    private var sourceURLField: some View {
        if let url = ListingURLHelpers.extractFromNotes(deal.notes),
           let link = URL(string: url) {
            sectionLabel("SOURCE")
            HStack(spacing: 8) {
                Link(destination: link) {
                    Text(url)
                        .porteosMeta()
                        .foregroundStyle(accentRust)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: DesignTokens.rowHeightData)
            .background(shellBg)
            .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
            .clipShape(Rectangle())
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("// NOTES")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
                Spacer()
                if !deal.notes.isEmpty {
                    Text("\(deal.notes.count) chars")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
            }

            TextEditor(text: $deal.notes)
                // porteosRowValue() forces frame(height: lineHeight) — single line only.
                // Apply font directly; let the explicit frame below control height.
                .font(DesignTokens.TypeScale.rowValue)
                .foregroundStyle(textPrimary)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 260)
                .background(shellBg)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
                .clipShape(Rectangle())
                .focused($focusedField, equals: .notes)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────────────────
    // MARK: RE ↔ Hospitality helpers
    // ─────────────────────────────────────────────────────────────────────────

    /// Total from individual OPEX line items (when any are non-zero)
    private var opexLineItemsTotal: Double {
        deal.opexPropertyManagement + deal.opexPropertyTax + deal.opexInsurance +
        deal.opexUtilities + deal.opexMaintenance + deal.opexCapitalReserves
    }

    /// Effective OpEx used by calculators: line items total when present, else aggregate field
    private var effectiveOpEx: Double {
        opexLineItemsTotal > 0 ? opexLineItemsTotal : deal.operatingExpenses
    }

    /// GPI implied by hospitality metrics (room revenue + ancillary)
    private var hospImpliedGPI: Double? {
        guard deal.hospitalityRoomCount > 0,
              deal.hospitalityADR > 0,
              deal.hospitalityOccupancyRate > 0 else { return nil }
        let roomRev = Double(deal.hospitalityRoomCount)
            * deal.hospitalityADR
            * (deal.hospitalityOccupancyRate / 100)
            * 365
        let ancillary = deal.hospitalityFBRevenue + deal.hospitalitySpaRevenue
            + deal.hospitalityMeetingRevenue + deal.hospitalityOtherRevenue
        return roomRev + ancillary
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Tab 2 — REAL ESTATE
    // ─────────────────────────────────────────────────────────────────────────

    private var realEstateContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("INCOME", color: accentRust)

            // GPI — show hospitality-implied suggestion when available
            TerminalInputField(label: "Gross Potential Income", placeholder: "0.00", prefix: "€",  suffix: nil, value: $deal.grossPotentialIncome, formatter: currencyFormatter).focused($focusedField, equals: .grossPotentialIncome)
            if let implied = hospImpliedGPI, abs(implied - deal.grossPotentialIncome) > 100 {
                HStack(spacing: 8) {
                    Text("// HOSP. CALC → €\(Int(implied.rounded())) (room rev + ancillary)")
                        .porteosMeta()
                        .foregroundStyle(textTertiary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button("[ SYNC GPI ]") {
                        deal.grossPotentialIncome = implied
                    }
                    .porteosMeta()
                    .foregroundStyle(accentRust)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(accentRust.opacity(0.06))
                .overlay(Rectangle().strokeBorder(accentRust.opacity(0.25), lineWidth: 1))
                .clipShape(Rectangle())
            }

            TerminalInputField(label: "Vacancy Rate",           placeholder: "0.00", prefix: nil,  suffix: "%", value: $deal.vacancyRate, formatter: Self.percentFormatter).focused($focusedField, equals: .vacancyRate)
            TerminalInputField(label: "Other Income",           placeholder: "0.00", prefix: "€",  suffix: nil, value: $deal.otherIncome, formatter: currencyFormatter).focused($focusedField, equals: .otherIncome)

            sectionLabel("EXPENSES", color: accentRust)

            // OpEx aggregate — warn when out of sync with line items
            TerminalInputField(label: "Operating Expenses", placeholder: "0.00", prefix: "€", suffix: nil, value: $deal.operatingExpenses, formatter: currencyFormatter).focused($focusedField, equals: .operatingExpenses)
            if opexLineItemsTotal > 0 && abs(opexLineItemsTotal - deal.operatingExpenses) > 1 {
                HStack(spacing: 8) {
                    Text("// LINE ITEMS TOTAL: €\(Int(opexLineItemsTotal.rounded())) — aggregate differs")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusWarn)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button("[ SYNC ]") {
                        deal.operatingExpenses = opexLineItemsTotal
                    }
                    .porteosMeta()
                    .foregroundStyle(accentRust)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(DesignTokens.statusWarn.opacity(0.06))
                .overlay(Rectangle().strokeBorder(DesignTokens.statusWarn.opacity(0.25), lineWidth: 1))
                .clipShape(Rectangle())
            }

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
            if deal.hospitalityOpExRatio > 0 && deal.hospitalityOpExRatio < 20 {
                Text("// WARNING: OpEx ratio \(String(format: "%.1f", deal.hospitalityOpExRatio))% is unusually low — typical hospitality is 30–45%")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.statusWarn)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignTokens.statusWarn.opacity(0.06))
                    .overlay(Rectangle().strokeBorder(DesignTokens.statusWarn.opacity(0.25), lineWidth: 1))
                    .clipShape(Rectangle())
            }

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
    // MARK: Media Strip
    // ─────────────────────────────────────────────────────────────────────────

    private var mediaStrip: some View {
        let hero = deal.images.first(where: { $0.isHero })
        return HStack(spacing: DesignTokens.blockGutter) {
            // Hero thumbnail or dashed placeholder
            if let h = hero, let img = NSImage(data: h.thumbnailData) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
                    .clipShape(Rectangle())
            } else {
                ZStack {
                    shellBg
                    Text("+")
                        .porteosMeta()
                        .foregroundStyle(textTertiary)
                }
                .frame(width: 40, height: 40)
                .overlay(
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(shellBorder)
                )
                .clipShape(Rectangle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("// MEDIA")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
                Text("\(deal.images.count) IMAGES")
                    .porteosMeta()
                    .foregroundStyle(deal.images.isEmpty ? textTertiary : textSecondary)
            }

            Spacer()

            Button { showMediaGallery = true } label: {
                Text("[ MANAGE ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(accentRust)
                    .padding(.horizontal, 10)
                    .frame(height: DesignTokens.rowHeightData)
                    .background(accentRust.opacity(0.08))
                    .overlay(Rectangle().strokeBorder(accentRust.opacity(0.45), lineWidth: DesignTokens.dividerWidth))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: 56)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Footer
    // ─────────────────────────────────────────────────────────────────────────

    private var footer: some View {
        HStack(spacing: 12) {
            Button { revertAndDismiss() } label: {
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

    private func revertAndDismiss() {
        // Restore every field to the pre-edit snapshot so Cancel truly cancels.
        if let snap = openSnapshot {
            DealHistoryManager.shared.apply(snap, to: deal)
            deal.updatedAt = snap.timestamp
            try? modelContext.save()
        }
        dismiss()
    }

    @State private var validationErrors: [ValidationMessage] = []
    @State private var showValidationAlert: Bool = false

    private func commitChanges() {
        // Run validation — block on critical errors, warn on others
        let messages = DataValidator.validate(deal: deal)
        let criticals = messages.filter { $0.severity == .critical }
        if !criticals.isEmpty {
            validationErrors = criticals
            showValidationAlert = true
            return   // don't save yet — user must resolve or force-save
        }

        persistAndDismiss()
    }

    private func persistAndDismiss() {
        // Sync OpEx aggregate from line items if any are non-zero
        if opexLineItemsTotal > 0 {
            deal.operatingExpenses = opexLineItemsTotal
        }
        // Compute and persist the Porteos Score
        deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        deal.updatedAt    = Date()
        do {
            try modelContext.save()
            GeocodingService.shared.scheduleGeocode(deal: deal, context: modelContext)
        } catch {
            print("[ERROR] Failed to save: \(error)")
        }
        TrendRecorder.record(deal, context: modelContext, source: "portfolio")
        dismiss()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Helpers
    // ─────────────────────────────────────────────────────────────────────────

    // MARK: City autocomplete

    /// All city names from MarketBenchmarks + MarketFeedRegistry aliases, deduplicated and sorted.
    private static let allCityNames: [String] = {
        var names = Set<String>()
        // Benchmark city names (all have data — best for autocomplete)
        MarketBenchmarks.benchmarks.forEach { names.insert($0.cityName) }
        // Friendly aliases from MarketFeedRegistry metro definitions
        MarketFeedRegistry.metros.forEach { metro in
            metro.cityAliases.forEach { alias in
                let cap = alias.prefix(1).uppercased() + alias.dropFirst()
                names.insert(cap)
            }
            names.insert(metro.displayName)
        }
        return names.sorted()
    }()

    static func citySuggestions(for query: String) -> [String] {
        guard query.count >= 2 else { return [] }
        let q = query.lowercased()
        let prefix   = allCityNames.filter { $0.lowercased().hasPrefix(q) }
        let contains = allCityNames.filter { !$0.lowercased().hasPrefix(q) && $0.lowercased().contains(q) }
        return Array((prefix + contains).prefix(8))
    }

    private static let allCountryNames: [String] = {
        Array(Set(MarketBenchmarks.benchmarks.map(\.country))).sorted()
    }()

    static func countrySuggestions(for query: String) -> [String] {
        guard query.count >= 1 else { return [] }
        let q = query.lowercased()
        return allCountryNames.filter { $0.lowercased().hasPrefix(q) }.prefix(8).map { $0 }
    }

    // MARK: GPS coordinates field

    @ViewBuilder
    private var gpsCoordinatesField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GPS COORDINATES")
                .porteosMeta()
                .foregroundStyle(textTertiary)
            HStack(spacing: 8) {
                if let lat = deal.latitude, let lon = deal.longitude {
                    Text(String(format: "%.5f, %.5f", lat, lon))
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusGo)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("[ CLEAR ]") {
                        deal.latitude = nil
                        deal.longitude = nil
                        deal.geocodeStatus = .none
                    }
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.statusCritical)
                    .buttonStyle(.plain)
                } else {
                    TextField("lat, lon — e.g. 37.24355, -8.26125", text: $gpsEntry)
                        .textFieldStyle(.plain)
                        .porteosMeta()
                        .foregroundStyle(textPrimary)
                        .onSubmit { applyGPSEntry() }
                    if !gpsEntry.isEmpty {
                        Button("[ SET ]") { applyGPSEntry() }
                            .porteosMeta()
                            .foregroundStyle(accentRust)
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(minHeight: DesignTokens.rowHeightData)
            .background(shellBg)
            .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
            .clipShape(Rectangle())

            if deal.geocodeStatus == .failed || deal.geocodeStatus == .none {
                Text("// Paste coordinates from Google Maps or import research JSON to pin correctly")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
            }
        }
    }

    private func applyGPSEntry() {
        let parts = gpsEntry
            .replacingOccurrences(of: " ", with: "")
            .components(separatedBy: ",")
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              lat >= -90, lat <= 90,
              lon >= -180, lon <= 180 else { return }
        deal.latitude = lat
        deal.longitude = lon
        deal.geocodeStatus = .ok
        gpsEntry = ""
    }

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

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Regulatory Section
    // ─────────────────────────────────────────────────────────────────────────

    private var regulatorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("REGULATORY — advisory only, verify with local consultant")

            TerminalInputField(
                label: "Zoning Class",
                placeholder: "e.g. T1 Tourism, Mixed Use, R1 Residential",
                prefix: nil,
                suffix: nil,
                text: $deal.zoningClass
            )

            VStack(alignment: .leading, spacing: 4) {
                TerminalInputField(
                    label: "Floor Area Ratio (FAR)",
                    placeholder: "0.00",
                    prefix: nil,
                    suffix: "×",
                    text: numStr($deal.floorAreaRatio, decimals: 2)
                )
                if deal.advisoryMaxBuildableArea > 0 {
                    HStack(spacing: 8) {
                        Text("Max buildable: ~\(Int(deal.advisoryMaxBuildableArea))m²")
                            .porteosMeta()
                            .foregroundStyle(textSecondary)
                        if deal.farHeadroom > 0 {
                            Text("↑ \(Int(deal.farHeadroom))m² headroom")
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.statusGo)
                        } else if deal.farHeadroom < 0 {
                            Text("↓ \(Int(abs(deal.farHeadroom)))m² over FAR")
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.statusCritical)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }

            TerminalInputField(
                label: "Max Height (m)",
                placeholder: "0",
                prefix: nil,
                suffix: "m",
                text: numStr($deal.maxBuildingHeight, decimals: 1)
            )

            TerminalInputField(
                label: "Max Bedrooms / Units",
                placeholder: "unknown",
                prefix: nil,
                suffix: nil,
                text: intStr($deal.maxBedroomsOrUnits)
            )

            regulatoryChipRow(
                label: "PLANNING STATUS",
                options: ["unknown", "none", "applied", "approved"],
                selection: $deal.planningStatus
            )

            heritageToggleRow

            regulatoryChipRow(
                label: "SHORT-TERM RENTAL LICENCE",
                options: ["unknown", "none", "applied", "approved"],
                selection: $deal.strLicenceStatus
            )

            Text("// ADVISORY — not legal advice. Verify all regulatory data with a qualified local consultant.")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    private func regulatoryChipRow(label: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .porteosMeta()
                .foregroundStyle(textTertiary)

            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    let isActive = selection.wrappedValue == option
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option.uppercased())
                            .porteosMeta()
                            .foregroundStyle(isActive ? DesignTokens.statusGo : textTertiary)
                            .padding(.horizontal, 10)
                            .frame(height: DesignTokens.rowHeightData)
                            .background(isActive ? DesignTokens.statusGo.opacity(0.1) : shellBg)
                            .overlay(
                                Rectangle().strokeBorder(
                                    isActive ? DesignTokens.statusGo.opacity(0.5) : shellBorder,
                                    lineWidth: DesignTokens.dividerWidth
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(Rectangle())
        }
    }

    private var heritageToggleRow: some View {
        HStack(spacing: 8) {
            Text("HERITAGE / LISTED BUILDING")
                .porteosMeta()
                .foregroundStyle(textTertiary)
            Spacer()
            if deal.heritageOrListed {
                Text("score penalty applied")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.statusWarn)
            }
            Toggle("", isOn: $deal.heritageOrListed)
                .labelsHidden()
                .toggleStyle(.switch)
                .scaleEffect(0.75)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: DesignTokens.rowHeightData)
        .background(deal.heritageOrListed ? DesignTokens.statusWarn.opacity(0.05) : shellBg)
        .overlay(
            Rectangle().strokeBorder(
                deal.heritageOrListed ? DesignTokens.statusWarn.opacity(0.3) : shellBorder,
                lineWidth: DesignTokens.dividerWidth
            )
        )
        .clipShape(Rectangle())
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
