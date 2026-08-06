import SwiftUI
import SwiftData

// MARK: - ProfileWindowView
// Root view for all independent profile windows. Receives a ProfileWindowValue
// binding from the scene, queries SwiftData directly, and manages its own
// selected deal — completely decoupled from WindowManager.shared.

struct ProfileWindowView: View {

    @Binding var windowValue: ProfileWindowValue?

    @Environment(\.modelContext) private var ctx
    @Query(sort: \PropertyDeal.createdAt, order: .reverse) private var deals: [PropertyDeal]

    @State private var selectedDealID: UUID? = nil

    // MARK: Derived

    private var selectedDeal: PropertyDeal? {
        guard let id = selectedDealID else { return deals.first }
        return deals.first { $0.id == id } ?? deals.first
    }

    private var profileLabel: String {
        switch windowValue?.profile {
        case "realEstate":  return "// REAL_ESTATE"
        case "hospitality": return "// HOSPITALITY"
        case "design":      return "// DESIGN"
        case "circular":    return "// CIRCULAR_ECONOMY"
        default:            return "// PROFILE"
        }
    }

    // MARK: Tokens

    private var shellBg:    Color { DesignTokens.canvasBase }
    private var shellBorder: Color { DesignTokens.dividerStructural }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle().fill(shellBorder).frame(height: 1)

            if deals.isEmpty {
                emptyState
            } else if let deal = selectedDeal {
                HStack(spacing: 0) {
                    profileContent(for: deal)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Rectangle().fill(shellBorder).frame(width: 1)
                    CompactDealInspector(deal: deal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyState
            }
        }
        .background(shellBg)
        .onAppear { resolveSelectedDeal() }
        .onChange(of: deals) { _, _ in resolveSelectedDeal() }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack(spacing: 0) {
            // Wordmark
            Text("PORTEOS@SYSTEM")
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.leading, 12)

            Rectangle().fill(shellBorder).frame(width: 1).padding(.vertical, 6)

            // Profile label
            Text(profileLabel)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .padding(.horizontal, 12)

            Spacer()

            // Deal picker
            if !deals.isEmpty {
                dealPicker
                    .padding(.trailing, 12)
            }
        }
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    private var dealPicker: some View {
        Menu {
            ForEach(deals) { deal in
                Button(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName) {
                    selectedDealID = deal.id
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedDeal?.propertyName.isEmpty == false
                     ? (selectedDeal?.propertyName ?? "Select Deal")
                     : "Select Deal")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundStyle(DesignTokens.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DesignTokens.surfacePanel)
            .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: Profile Routing

    @ViewBuilder
    private func profileContent(for deal: PropertyDeal) -> some View {
        switch windowValue?.profile {
        case "hospitality": HospitalityDashboardView(deal: deal)
        case "design":      DesignDashboardView(deal: deal)
        case "circular":    CircularEconomyDashboardView(deal: deal)
        default:            RealEstateDashboardView(deal: deal)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("// NO_DEALS")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text("Add a deal in the main window to get started.")
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    // MARK: Helpers

    private func resolveSelectedDeal() {
        let targetID = windowValue?.dealID
        if let id = targetID, deals.contains(where: { $0.id == id }) {
            selectedDealID = id
        } else {
            selectedDealID = deals.first?.id
        }
    }
}
