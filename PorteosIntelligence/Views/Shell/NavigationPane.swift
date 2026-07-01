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

    private func profileFor(_ deal: PropertyDeal) -> ProfileType {
        if deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0 {
            return .hospitality
        }
        return .realEstate
    }

    // MARK: Tokens

    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentRust    = Color(hex: "#C25E30")
    private let accentGreen   = Color(hex: "#10B981")

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
        .frame(width: 260)
        .frame(maxHeight: .infinity)
        .background(shellSurface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(shellBorder)
                .frame(width: 1)
        }
        .clipShape(Rectangle())
        .sheet(item: $dealToEdit) { deal in
            EditDealSheet(deal: deal)
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

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("PORTEOS@SYSTEM")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(textPrimary)

            Text("STATUS: ENCRYPTED")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(accentRust)
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .padding(.leading, 16)
    }

    // MARK: Nav Section

    private var navSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("NAVIGATION")
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(ProfileType.allCases) { profile in
                    navLinkRow(profile)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func navLinkRow(_ profile: ProfileType) -> some View {
        let isActive = profile == activeProfile

        return Button {
            activeProfile = profile
        } label: {
            HStack(spacing: 0) {
                // Active indicator pip
                Rectangle()
                    .fill(isActive ? profile.accentColor : Color.clear)
                    .frame(width: 2)

                Text(profile.navPath)
                    .font(.custom("JetBrains Mono", size: 13).weight(isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? textPrimary : textSecondary)
                    .padding(.leading, 14)

                Spacer()
            }
            .frame(height: 28)
            .background(isActive ? shellElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Deals Section

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(shellBorder).frame(height: 1).padding(.bottom, 8)

            // Deals header + compare toggle + filter toggle
            HStack(spacing: 0) {
                sectionHeader("DEALS")
                Spacer()

                // Filter toggle — badge dot when active
                Button {
                    showFilterPanel.toggle()
                } label: {
                    HStack(spacing: 2) {
                        Text("[ FILTER\(filters.isActive ? "•" : "") ]")
                            .font(.custom("JetBrains Mono", size: 11).weight(showFilterPanel ? .bold : .regular))
                            .foregroundStyle(filters.isActive ? accentRust : (showFilterPanel ? textSecondary : textTertiary))
                    }
                    .padding(.trailing, 4)
                }
                .buttonStyle(.plain)

                // Triage — batch pipeline review
                Button {
                    showTriage = true
                } label: {
                    Text("[ TRIAGE ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(textTertiary)
                        .padding(.trailing, 4)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showTriage) {
                    BatchTriageView()
                }

                Button {
                    compareMode.toggle()
                    if !compareMode { pendingCompare.removeAll() }
                } label: {
                    Text(compareMode ? "[ EXIT ]" : "[ CMP ]")
                        .font(.custom("JetBrains Mono", size: 11).weight(compareMode ? .bold : .regular))
                        .foregroundStyle(compareMode ? accentRust : textTertiary)
                        .padding(.trailing, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)

            // Inline text search bar
            searchBar
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

            // Collapsible advanced filter panel
            if showFilterPanel {
                AdvancedFilterPanel(filters: $filters)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            // Status filter tabs
            filterTabs.padding(.bottom, 4)
            Rectangle().fill(shellBorder).frame(height: 1)

            // Deal list
            if filteredDeals.isEmpty {
                Text(deals.isEmpty ? "no deals yet"
                     : filters.isActive ? "no matches"
                     : "no \(statusFilter?.rawValue ?? "") deals")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textSecondary)
                    .padding(.leading, 16)
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
                        .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                        .foregroundStyle(Color(hex: "#0F1115"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(accentRust)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Bulk actions
            Rectangle().fill(shellBorder).frame(height: 1)
            bulkActions
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
            Text("↳ ")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(textTertiary)
                .padding(.leading, 8)

            TextField("search…", text: $filters.searchText)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textPrimary)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)

            if !filters.searchText.isEmpty {
                Button {
                    filters.searchText = ""
                } label: {
                    Text("×")
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
        .frame(height: 26)
        .background(Color(hex: "#0F1115"))
        .overlay(Rectangle().stroke(
            filters.searchText.isEmpty ? shellBorder : accentRust,
            lineWidth: 1
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
                                .font(.custom("JetBrains Mono", size: 13).weight(isActive ? .bold : .regular))
                                .foregroundStyle(isActive ? textPrimary : textTertiary)
                                .frame(height: 24)
                                .padding(.horizontal, 8)
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

    private var bulkActions: some View {
        HStack(spacing: 0) {
            Button { showExportSheet = true } label: {
                Text("[ ./BULK_EXPORT ]")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(filteredDeals.isEmpty ? textTertiary : accentGreen)
                    .padding(.leading, 16)
                    .frame(height: 32, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(filteredDeals.isEmpty)

            Spacer()

            Button { showDeleteConfirm = true } label: {
                Text("[ ./BULK_DELETE ]")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(filteredDeals.isEmpty ? textTertiary : Color(hex: "#EF4444"))
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
        let pipColor: Color = compareMode
            ? (isChecked ? accentGreen : Color(hex: "#2E333F"))
            : (isSelected ? accentRust : Color.clear)

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
                    .frame(width: 2)

                HStack(spacing: 4) {
                    // Checkbox indicator in compare mode
                    if compareMode {
                        Rectangle()
                            .fill(isChecked ? accentGreen : Color.clear)
                            .frame(width: 8, height: 8)
                            .overlay(Rectangle().strokeBorder(isChecked ? accentGreen : textTertiary, lineWidth: 1))
                            .clipShape(Rectangle())
                    }

                    Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(
                            compareMode ? (isChecked ? textPrimary : textSecondary)
                                        : (isSelected ? textPrimary : textSecondary)
                        )
                        .lineLimit(1)

                    Spacer()

                    Text(deal.status.rawValue.uppercased())
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(statusColor(deal.status))
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 32)
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

    private func statusColor(_ status: DealStatus) -> Color {
        switch status {
        case .viable:   return Color(hex: "#10B981")  // green
        case .review:   return Color(hex: "#F59E0B")  // amber
        case .rejected: return Color(hex: "#EF4444")  // red
        case .acquired: return Color(hex: "#3B82F6")  // blue
        case .pipeline: return Color(hex: "#64748B")  // tertiary
        }
    }

    // MARK: Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("JetBrains Mono", size: 13).weight(.bold))
            .tracking(0.08)
            .foregroundStyle(textTertiary)
            .textCase(.uppercase)
            .padding(.leading, 16)
    }

    // MARK: Footer Actions

    private var footerActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(shellBorder)
                .frame(height: 1)

            scriptButton(label: "[ ./NEW_DEAL ]") {
                showNewDealSheet = true
            }

            Rectangle()
                .fill(shellBorder)
                .frame(height: 1)
                .padding(.horizontal, 16)

            scriptButton(label: "[ ./IMPORT_DEALS ]") {
                showImportSheet = true
            }
        }
    }

    private func scriptButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(accentGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .frame(height: 32)
        }
        .buttonStyle(.plain)
        .clipShape(Rectangle())
        .padding(.vertical, 4)
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
    .background(Color(hex: "#0F1115"))
    .modelContainer(container)
}
