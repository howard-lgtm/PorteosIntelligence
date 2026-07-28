import SwiftUI
import SwiftData

// MARK: - NavigationPane

struct NavigationPane: View {

    @Binding var showNewDealSheet: Bool
    @Binding var selectedDeal: PropertyDeal?
    @Binding var activeProfile: ProfileType
    /// Drives ComparisonView in AppShell's center pane.
    @Binding var showComparison: Bool
    @Binding var compareDeals: [PropertyDeal]

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PropertyDeal.createdAt, order: .reverse) var deals: [PropertyDeal]

    @State private var dealToEdit:        PropertyDeal? = nil
    @State private var showImportSheet:   Bool          = false
    @State private var showExportSheet:   Bool          = false
    @State private var statusFilter:      DealStatus?   = nil   // nil = ALL
    @State private var showDeleteConfirm: Bool          = false
    @State private var compareMode:       Bool          = false
    @State private var pendingCompare:    Set<UUID>     = []
    @State private var filters:           DealFilters   = DealFilters()
    @State private var showFilterPanel:   Bool          = false
    @State private var showTriage:        Bool          = false

    private var filteredDeals: [PropertyDeal] {
        deals.filter { deal in
            guard matchesStatus(deal) else { return false }
            return filters.matches(deal: deal)
        }
    }

    private func matchesStatus(_ deal: PropertyDeal) -> Bool {
        guard let filter = statusFilter else { return true }
        return deal.status == filter
    }

    /// Right column label: cap rate if computable, score if available, else status.
    private func dealRowRightLabel(_ deal: PropertyDeal) -> String {
        if deal.purchasePrice > 0 && deal.grossPotentialIncome > 0 {
            let egi = deal.grossPotentialIncome * (1 - deal.vacancyRate / 100)
            let noi = max(0, egi - deal.operatingExpenses)
            if noi > 0 {
                let cr = noi / deal.purchasePrice * 100
                return String(format: "%.1f%%", cr)
            }
        }
        if let score = deal.porteosScore { return "\(Int(score.rounded()))" }
        return deal.status.rawValue.uppercased()
    }

    private func dealRowRightColor(_ deal: PropertyDeal) -> Color {
        if deal.purchasePrice > 0 && deal.grossPotentialIncome > 0 {
            let egi = deal.grossPotentialIncome * (1 - deal.vacancyRate / 100)
            let noi = max(0, egi - deal.operatingExpenses)
            if noi > 0 { return DesignTokens.textSecondary }
        }
        if deal.porteosScore != nil { return DesignTokens.textSecondary }
        return deal.status.tokenColor
    }

    private func profileFor(_ deal: PropertyDeal) -> ProfileType {
        if deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0 {
            return .hospitality
        }
        return .realEstate
    }

    // MARK: Tokens (V2.06 — via DesignTokens)

    private var shellSurface:  Color { DesignTokens.surfacePanel }
    private var shellElevated: Color { DesignTokens.surfaceElevated }
    private var shellBorder:   Color { DesignTokens.dividerStructural }
    private var textPrimary:   Color { DesignTokens.textPrimary }
    private var textSecondary: Color { DesignTokens.textSecondary }
    private var textTertiary:  Color { DesignTokens.textDim }
    private var accentRust:    Color { DesignTokens.accentRust }
    private var accentGreen:   Color { DesignTokens.statusGo }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    navSection
                    dealsSection
                }
            }

            Spacer(minLength: 0)
            footerActions
        }
        .frame(width: DesignTokens.navPaneWidth)
        .frame(maxHeight: .infinity)
        .background(shellSurface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(shellBorder)
                .frame(width: 1)
        }
        .clipShape(Rectangle())
        .sheet(item: $dealToEdit) { deal in
            FullDealEditSheet(deal: deal)
        }
        .sheet(isPresented: $showImportSheet) {
            ImportDealSheet()
        }
        .sheet(isPresented: $showExportSheet) {
            BulkExportSheet(allDeals: deals, filteredDeals: filteredDeals)
        }
        // Keyboard shortcut receivers
        .onReceive(NotificationCenter.default.publisher(for: .showImportDeals)) { _ in
            showImportSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showExportSheet)) { _ in
            showExportSheet = true
        }
    }

    // MARK: Header — Figma img_00_21: PORTEOS@SYSTEM wordmark only

    private var header: some View {
        VStack(spacing: 0) {
            Text("PORTEOS@SYSTEM")
                .porteosButtonPrimary()
                .foregroundStyle(textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Rectangle().fill(shellBorder).frame(height: DesignTokens.dividerWidth)
        }
    }

    // MARK: Nav Section — uppercase profile labels, 2px accent pip

    private var navSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(ProfileType.allCases) { profile in
                    navLinkRow(profile)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func navLinkRow(_ profile: ProfileType) -> some View {
        let isActive = profile == activeProfile

        return Button {
            activeProfile = profile
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isActive ? textPrimary : Color.clear)
                    .frame(width: DesignTokens.navSelectionBorder)

                Text(profile.shellNavLabel)
                    .porteosTextStyle(.shellNav(isActive: isActive))
                    .foregroundStyle(isActive ? textPrimary : textTertiary)
                    .padding(.leading, 12)

                Spacer()
            }
            .frame(height: DesignTokens.rowHeightNavLink)
            .background(isActive ? shellElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Deals Section

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Compact utility row (filter / triage / compare)
            HStack(spacing: 0) {
                Spacer()
                Button { showFilterPanel.toggle() } label: {
                    Text("[ FILTER\(filters.isActive ? "•" : "") ]")
                        .porteosTextStyle(.shellAction(isActive: showFilterPanel || filters.isActive))
                        .foregroundStyle(filters.isActive ? accentRust : (showFilterPanel ? textSecondary : textTertiary))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)

                Button { showTriage = true } label: {
                    Text("[ TRIAGE ]")
                        .porteosButtonPrimary()
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
                .sheet(isPresented: $showTriage) { BatchTriageView() }

                Button {
                    compareMode.toggle()
                    if !compareMode { pendingCompare.removeAll() }
                } label: {
                    Text(compareMode ? "[ EXIT ]" : "[ CMP ]")
                        .porteosTextStyle(.shellAction(isActive: compareMode))
                        .foregroundStyle(compareMode ? accentRust : textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, DesignTokens.blockGutter)
            }
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Status filter tabs — before search (Figma img_00_21 order)
            filterTabs
                .padding(.bottom, 6)

            searchBar
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.bottom, 6)

            if showFilterPanel {
                AdvancedFilterPanel(filters: $filters)
                    .padding(.horizontal, DesignTokens.blockGutter)
                    .padding(.bottom, 6)
            }

            Rectangle().fill(shellBorder).frame(height: DesignTokens.dividerWidth)

            // Deal list
            if filteredDeals.isEmpty {
                Text(deals.isEmpty ? "no deals yet"
                     : filters.isActive ? "no matches"
                     : "no \(statusFilter?.rawValue ?? "") deals")
                    .porteosRowLabel()
                    .foregroundStyle(textSecondary)
                    .padding(.leading, DesignTokens.blockGutter)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredDeals) { deal in
                        dealRow(deal)
                    }
                }
            }

            // Launch compare button (visible when 2+ deals selected)
            if compareMode && pendingCompare.count >= 2 {
                Rectangle().fill(shellBorder).frame(height: 1)
                Button {
                    compareDeals  = deals.filter { pendingCompare.contains($0.id) }
                    showComparison = true
                    compareMode    = false
                    pendingCompare.removeAll()
                } label: {
                    Text("[ LAUNCH_COMPARE (\(pendingCompare.count)) ]")
                        .porteosButtonPrimary()
                        .foregroundStyle(DesignTokens.canvasBase)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(accentRust)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .confirmationDialog(
            "Delete \(filteredDeals.count) deal\(filteredDeals.count == 1 ? "" : "s")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                for deal in filteredDeals { modelContext.delete(deal) }
                selectedDeal = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: Search Bar

    private var searchBar: some View {
        HStack(spacing: 0) {
            Text("/ ")
                .porteosRowLabel()
                .foregroundStyle(textTertiary)
                .padding(.leading, DesignTokens.blockGutter)

            TextField("search deals...", text: $filters.searchText)
                .porteosRowLabel()
                .foregroundStyle(textPrimary)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            if !filters.searchText.isEmpty {
                Button { filters.searchText = "" } label: {
                    Text("×")
                        .porteosTextStyle(.shellAction(isActive: false))
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
        .frame(height: DesignTokens.rowHeightData)
        .background(DesignTokens.canvasBase)
        .overlay(Rectangle().stroke(
            filters.searchText.isEmpty ? shellBorder : accentRust,
            lineWidth: DesignTokens.dividerWidth
        ))
        .clipShape(Rectangle())
    }

    private var filterTabs: some View {
        let options: [(label: String, filter: DealStatus?)] = [
            ("ALL",      nil),
            ("PIPELINE", .pipeline),
            ("REVIEW",   .review),
            ("VIABLE",   .viable),
            ("REJECTED", .rejected),
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(options, id: \.label) { option in
                    let isActive = statusFilter == option.filter
                    Button { statusFilter = option.filter } label: {
                        VStack(spacing: 0) {
                            Text(option.label)
                                .porteosMeta()
                                .foregroundStyle(isActive ? textPrimary : textTertiary)
                                .frame(height: DesignTokens.rowHeightNavLink)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .fill(isActive ? textPrimary : Color.clear)
                                .frame(height: DesignTokens.navSelectionBorder)
                        }
                        .frame(height: DesignTokens.rowHeightData)
                        .clipShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, DesignTokens.blockGutter)
        }
    }

    private var bulkActions: some View {
        HStack(spacing: 0) {
            Button { showExportSheet = true } label: {
                Text("[ ./BULK_EXPORT ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(filteredDeals.isEmpty ? textTertiary : accentGreen)
                    .padding(.leading, 16)
                    .frame(height: 32, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(filteredDeals.isEmpty)

            Spacer()

            Button { showDeleteConfirm = true } label: {
                Text("[ ./BULK_DELETE ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(filteredDeals.isEmpty ? textTertiary : DesignTokens.statusCritical)
                    .padding(.trailing, 12)
                    .frame(height: 32, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .disabled(filteredDeals.isEmpty)
        }
    }

    private func dealRow(_ deal: PropertyDeal) -> some View {
        let isSelected   = deal.id == selectedDeal?.id
        let isChecked    = pendingCompare.contains(deal.id)
        let dealAccent = profileFor(deal).accentColor
        let pipColor: Color = compareMode
            ? (isChecked ? accentGreen : DesignTokens.dividerStructural)
            : (isSelected ? dealAccent : Color.clear)

        return Button {
            if compareMode {
                if isChecked { pendingCompare.remove(deal.id) }
                else         { pendingCompare.insert(deal.id) }
            } else {
                selectedDeal  = deal
                activeProfile = profileFor(deal)
            }
        } label: {
            HStack(spacing: 0) {
                // Left pip: Rust when selected (normal), Green when checked (compare)
                Rectangle()
                    .fill(pipColor)
                    .frame(width: compareMode ? 2 : 4)

                HStack(spacing: 4) {
                    if compareMode {
                        Rectangle()
                            .fill(isChecked ? accentGreen : Color.clear)
                            .frame(width: 8, height: 8)
                            .overlay(Rectangle().strokeBorder(isChecked ? accentGreen : textTertiary, lineWidth: 1))
                            .clipShape(Rectangle())
                    }

                    Text(deal.propertyName.isEmpty ? "UNTITLED DEAL" : deal.propertyName.uppercased())
                        .porteosTextStyle(.shellDeal(isSelected: isSelected || isChecked))
                        .foregroundStyle(
                            compareMode ? (isChecked ? textPrimary : textSecondary)
                                        : (isSelected ? textPrimary : textSecondary)
                        )
                        .lineLimit(1)

                    Spacer()

                    Text(dealRowRightLabel(deal))
                        .porteosMeta()
                        .monospacedDigit()
                        .foregroundStyle(dealRowRightColor(deal))
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
            }
            .frame(height: DesignTokens.rowHeightData)
            .background(
                compareMode ? (isChecked ? shellElevated : Color.clear)
                            : (isSelected ? shellElevated : Color.clear)
            )
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { dealToEdit = deal } label: {
                Label("Edit Deal", systemImage: "pencil")
            }
        }
    }

    // MARK: Footer — Figma img_00_21: ./IMPORT_DEALS + [ ./NEW_DEAL ] + CLI prompt

    private var footerActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(shellBorder)
                .frame(height: DesignTokens.dividerWidth)

            if !compareMode && !filteredDeals.isEmpty {
                bulkActions
                Rectangle()
                    .fill(shellBorder)
                    .frame(height: DesignTokens.dividerWidth)
            }

            Button { showImportSheet = true } label: {
                Text("./IMPORT_DEALS")
                    .porteosRowLabel()
                    .foregroundStyle(textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.blockGutter)
                    .frame(height: DesignTokens.rowHeightData)
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(shellBorder)
                .frame(height: DesignTokens.dividerWidth)
                .padding(.horizontal, DesignTokens.blockGutter)

            Button { showNewDealSheet = true } label: {
                Text("[ ./NEW_DEAL ]")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TerminalButtonStyle(color: .rust, height: DesignTokens.rowHeightButton))
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)

            Rectangle()
                .fill(shellBorder)
                .frame(height: DesignTokens.dividerWidth)

            HStack(spacing: 0) {
                Text("porteos@system ~ %")
                    .porteosCliPrompt()
                    .foregroundStyle(textTertiary)
                Rectangle()
                    .fill(textPrimary.opacity(0.85))
                    .frame(width: 7, height: 13)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
            .background(DesignTokens.canvasBase)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal = PropertyDeal(propertyName: "Lisbon Office Block A", address: "Av. da Liberdade, Lisboa")
    container.mainContext.insert(deal)

    return HStack(spacing: 0) {
        NavigationPane(
            showNewDealSheet: .constant(false),
            selectedDeal:     .constant(deal),
            activeProfile:    .constant(.realEstate),
            showComparison:   .constant(false),
            compareDeals:     .constant([])
        )
        Spacer()
    }
    .frame(width: 400, height: 600)
    .background(DesignTokens.canvasBase)
    .modelContainer(container)
}
