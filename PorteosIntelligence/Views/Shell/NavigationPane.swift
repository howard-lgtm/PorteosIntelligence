import SwiftUI
import SwiftData

// MARK: - NavigationPane

struct NavigationPane: View {

    @Binding var showNewDealSheet: Bool
    @Binding var selectedDealID: UUID?
    @Binding var activeProfile: ProfileType

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PropertyDeal.createdAt, order: .reverse) var deals: [PropertyDeal]

    @State private var dealToEdit:        PropertyDeal? = nil
    @State private var showImportSheet:   Bool          = false
    @State private var statusFilter:      DealStatus?   = nil   // nil = ALL
    @State private var showDeleteConfirm: Bool          = false

    private var filteredDeals: [PropertyDeal] {
        guard let filter = statusFilter else { return deals }
        return deals.filter { $0.status == filter }
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
        .frame(width: 220)
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
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("PORTEOS@SYSTEM")
                .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                .foregroundStyle(textPrimary)

            Text("STATUS: ENCRYPTED")
                .font(.custom("JetBrains Mono", size: 10))
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
                    .font(.custom("JetBrains Mono", size: 12).weight(isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? textPrimary : textSecondary)
                    .padding(.leading, 14)

                Spacer()
            }
            .frame(height: 24)
            .background(isActive ? shellElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Deals Section

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(shellBorder).frame(height: 1).padding(.bottom, 8)
            sectionHeader("DEALS").padding(.bottom, 6)

            // Filter tabs
            filterTabs.padding(.bottom, 4)
            Rectangle().fill(shellBorder).frame(height: 1)

            // Deal list
            if filteredDeals.isEmpty {
                Text(deals.isEmpty ? "no deals yet" : "no \(statusFilter?.rawValue ?? "") deals")
                    .font(.custom("JetBrains Mono", size: 11))
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
                selectedDealID = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
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
                                .font(.custom("JetBrains Mono", size: 9).weight(isActive ? .bold : .regular))
                                .foregroundStyle(isActive ? textPrimary : textTertiary)
                                .frame(height: 20)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .fill(isActive ? accentRust : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(height: 24)
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
            Button {
                // BULK_EXPORT: phase 2
            } label: {
                Text("[ ./BULK_EXPORT ]")
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundStyle(filteredDeals.isEmpty ? textTertiary : accentGreen)
                    .padding(.leading, 16)
                    .frame(height: 28, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(filteredDeals.isEmpty)

            Spacer()

            Button { showDeleteConfirm = true } label: {
                Text("[ ./BULK_DELETE ]")
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundStyle(filteredDeals.isEmpty ? textTertiary : Color(hex: "#EF4444"))
                    .padding(.trailing, 12)
                    .frame(height: 28, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .disabled(filteredDeals.isEmpty)
        }
    }

    private func dealRow(_ deal: PropertyDeal) -> some View {
        let isSelected = deal.id == selectedDealID

        return Button {
            selectedDealID = deal.id
        } label: {
            HStack(spacing: 0) {
                // 2pt selection accent border
                Rectangle()
                    .fill(isSelected ? accentRust : Color.clear)
                    .frame(width: 2)

                HStack(spacing: 4) {
                    Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(isSelected ? textPrimary : textSecondary)
                        .lineLimit(1)

                    Spacer()

                    Text(deal.status.rawValue.uppercased())
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundStyle(statusColor(deal.status))
                }
                .padding(.leading, 10)
                .padding(.trailing, 12)
                .padding(.vertical, 6)
            }
            .frame(height: 28)
            .background(isSelected ? shellElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                dealToEdit = deal
            } label: {
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
            .font(.custom("Inter", size: 11).weight(.bold))
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
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(accentGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .frame(height: 28)
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
            selectedDealID: .constant(deal.id),
            activeProfile: .constant(.realEstate)
        )
        Spacer()
    }
    .frame(width: 400, height: 600)
    .background(Color(hex: "#0F1115"))
    .modelContainer(container)
}
