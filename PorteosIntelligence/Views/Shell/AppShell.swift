import SwiftUI
import SwiftData

struct AppShell: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PropertyDeal.createdAt, order: .reverse) private var deals: [PropertyDeal]

    @State private var showNewDealSheet = false
    @State private var selectedDeal: PropertyDeal?
    @State private var pendingDealID: UUID?        // set by NewDealSheet; resolved once @Query fires
    @State private var activeProfile: ProfileType = .cmdCenter

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#0F1115")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Layout Constants

    private let navPaneWidth:       CGFloat = 280
    private let inspectorPaneWidth: CGFloat = 320
    private let dividerWidth:       CGFloat = 1

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            TopHeaderBar(activeProfile: activeProfile)

            HStack(spacing: 0) {
                NavigationPane(
                    showNewDealSheet: $showNewDealSheet,
                    selectedDeal: $selectedDeal,
                    activeProfile: $activeProfile
                )

                paneDivider

                centerPane

                paneDivider

                inspectorPane
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlobalCommandBar(lineCount: 120)
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .onChange(of: deals) {
            // Resolve a pending selection created by NewDealSheet
            if let id = pendingDealID,
               let deal = deals.first(where: { $0.id == id }) {
                selectedDeal = deal
                pendingDealID = nil
            }
        }
        .sheet(isPresented: $showNewDealSheet) {
            NewDealSheet { newID in
                // @Query may not yet contain the new deal; defer resolution
                pendingDealID  = newID
                activeProfile  = .realEstate
            }
        }
    }

    // MARK: Center Pane

    @ViewBuilder
    private var centerPane: some View {
        if activeProfile == .cmdCenter {
            CmdCenterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(shellBg)
        } else if let deal = selectedDeal {
            let viewModel = PropertyDealViewModel(deal: deal)
            VStack(spacing: 0) {
                PorteosScoreBlock(metrics: viewModel.porteosScore)
                Rectangle().fill(shellBg).frame(height: 16)
                switch activeProfile {
                case .realEstate:
                    RealEstateDashboardView(deal: deal)
                    case .hospitality:
                        HospitalityDashboardView(deal: deal)
                case .design:
                    DesignDashboardView(deal: deal)
                case .circular:
                    CircularEconomyDashboardView(deal: deal)
                default:
                    profilePlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shellBg)
        } else {
            switch activeProfile {
            case .realEstate:
                realEstateNoDealState
            default:
                noDealState
            }
        }
    }

    // Shown when /real_estate is active but no deal is selected.
    private var realEstateNoDealState: some View {
        VStack {
            Spacer()
            TerminalBlock(command: "ls ./deals", accentColor: textTertiary, contentPadding: 0) {
                VStack(spacing: 12) {
                    Text("No deal selected")
                        .font(.custom("JetBrains Mono", size: 14))
                        .foregroundStyle(textSecondary)
                    Text("Select a deal from the sidebar or click [ ./NEW_DEAL ]")
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textTertiary)
                    Rectangle().fill(shellBorder).frame(height: 1)
                    Button(action: loadSampleDeal) {
                        Text("[ ./LOAD_SAMPLE_DEAL ]")
                            .font(.custom("JetBrains Mono", size: 13))
                            .foregroundStyle(Color(hex: "#10B981"))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    private func loadSampleDeal() {
        let deal = PropertyDeal(
            propertyName:           "Lisbon Office Block A",
            purchasePrice:          1_250_000,
            closingCosts:           37_500,
            grossPotentialIncome:   125_000,
            vacancyRate:            5,
            operatingExpenses:      45_000,
            loanAmount:             937_500,
            interestRate:           4.5,
            amortizationMonths:     360,
            exitCapRate:            5.5,
            opexPropertyManagement: 9_000,
            opexPropertyTax:        12_500,
            opexInsurance:          3_750,
            opexUtilities:          8_750,
            opexMaintenance:        7_500,
            opexCapitalReserves:    3_500
        )
        modelContext.insert(deal)
        selectedDeal  = deal
        activeProfile = .realEstate
    }

    // Shown when a deal is selected but the profile has no dashboard yet.
    private var profilePlaceholder: some View {
        VStack {
            Spacer()
            VStack(spacing: 4) {
                Text("01 // \(activeProfile.displayName)")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .foregroundStyle(activeProfile.accentColor)
                Text("MODULE NOT YET IMPLEMENTED")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }

    // Shown when no deal is selected and the profile has no specific empty state.
    private var noDealState: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
                Text("select or create a deal to begin")
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    // MARK: Inspector Pane

    @ViewBuilder
    private var inspectorPane: some View {
        if let deal = selectedDeal {
            InspectorPane(deal: deal)
        } else {
            VStack {
                Spacer()
                Text("./INSPECTOR_V2")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                Spacer()
            }
            .frame(width: inspectorPaneWidth)
            .frame(maxHeight: .infinity)
            .background(shellSurface)
        }
    }

    // MARK: Pane Divider

    private var paneDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(width: dividerWidth)
            .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("With Deal") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal = PropertyDeal(
        purchasePrice:        2_000_000,
        grossPotentialIncome: 180_000,
        vacancyRate:          5,
        operatingExpenses:    55_000,
        loanAmount:           1_500_000,
        interestRate:         4.5,
        amortizationMonths:   360
    )
    container.mainContext.insert(deal)
    return AppShell()
        .modelContainer(container)
        .frame(width: 1200, height: 800)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    return AppShell()
        .modelContainer(container)
        .frame(width: 1200, height: 800)
}
