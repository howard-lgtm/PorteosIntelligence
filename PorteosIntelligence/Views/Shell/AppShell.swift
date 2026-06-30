import SwiftUI
import SwiftData

struct AppShell: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PropertyDeal.createdAt, order: .reverse) private var deals: [PropertyDeal]

    // Singleton observable — any wm.* access in body is auto-tracked.
    private let wm = WindowManager.shared

    @State private var pendingDealID:      UUID?          = nil
    @State private var showComparison      = false
    @State private var compareDeals:       [PropertyDeal] = []
    @State private var showShortcutsPanel  = false
    @State private var showCommandPalette  = false
    @State private var showNewDealSheet    = false
    @State private var showEmailSetup      = false
    @State private var showQuickAdd        = false
    @State private var showServerConfig    = false
    @State private var showSettings        = false
    @State private var pendingAITriggerID: UUID? = nil

    // Toast manager — @Observable, body re-renders on currentToast changes
    private let toastManager = ToastManager.shared

    // MARK: Derived deal state (WM-backed)

    private var selectedDeal: PropertyDeal? {
        deals.first { $0.id == wm.selectedDealID }
    }

    private var selectedDealBinding: Binding<PropertyDeal?> {
        Binding(
            get: { deals.first { $0.id == wm.selectedDealID } },
            set: { wm.selectedDealID = $0?.id }
        )
    }

    private var activeProfileBinding: Binding<ProfileType> {
        Binding(
            get: { wm.activeProfile },
            set: { wm.activeProfile = $0 }
        )
    }

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#0F1115")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentRust    = Color(hex: "#C25E30")

    // MARK: Layout Constants

    private let navPaneWidth:       CGFloat = 260
    private let inspectorPaneWidth: CGFloat = 280
    private let dividerWidth:       CGFloat = 1

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            TopHeaderBar(activeProfile: wm.activeProfile, onServerTap: { showServerConfig = true })

            HStack(spacing: 0) {
                let navGone    = wm.detachedPanes.contains(.navigation)
                let centerGone = wm.detachedPanes.contains(.center)
                let inspGone   = wm.detachedPanes.contains(.inspector)

                // ── Navigation ─────────────────────────────────────────────────
                if !navGone {
                    NavigationPane(
                        showNewDealSheet: $showNewDealSheet,
                        selectedDeal:     selectedDealBinding,
                        activeProfile:    activeProfileBinding,
                        showComparison:   $showComparison,
                        compareDeals:     $compareDeals
                    )
                    .overlay(alignment: .topTrailing) { detachButton(for: .navigation) }

                    // Divider only when something follows in the main window
                    if !centerGone || !inspGone { paneDivider }
                }

                // ── Center ─────────────────────────────────────────────────────
                if !centerGone {
                    centerPane
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .topTrailing) { detachButton(for: .center) }

                    if !inspGone { paneDivider }
                }

                // ── Inspector ──────────────────────────────────────────────────
                if !inspGone {
                    inspectorPane
                        .overlay(alignment: .topTrailing) { detachButton(for: .inspector) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlobalCommandBar(lineCount: 120)
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .focusedValue(\.hasDealSelected, selectedDeal != nil)
        // ── Bootstrap singletons with the live ModelContainer ─────────────────
        .onAppear {
            wm.modelContainer = modelContext.container
            EmailMonitorService.shared.injectContainer(modelContext.container)
            if EmailMonitorService.shared.isConfigured {
                EmailMonitorService.shared.startMonitoring()
            }
            DealIngestionServer.shared.injectContainer(modelContext.container)
            if DealIngestionServer.shared.autoStartEnabled {
                DealIngestionServer.shared.start()
            }
        }
        // ── Pending deal resolution (from TemplatePickerSheet) ─────────────────
        .onChange(of: deals) {
            if let id = pendingDealID,
               deals.first(where: { $0.id == id }) != nil {
                wm.selectedDealID = id
                pendingDealID     = nil
            }
        }
        // ── Notification receivers ─────────────────────────────────────────────
        .onReceive(NotificationCenter.default.publisher(for: .showNewDeal)) { _ in
            showNewDealSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateProfile)) { notif in
            guard let raw     = notif.userInfo?["profile"] as? String,
                  let profile = ProfileType(rawValue: raw)
            else { return }
            wm.activeProfile  = profile
            showComparison    = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .showShortcutsLegend)) { _ in
            showShortcutsPanel = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCommandPalette)) { _ in
            showCommandPalette = true
        }
        // ── Command Palette overlay ────────────────────────────────────────────
        .overlay {
            if showCommandPalette {
                ZStack(alignment: .top) {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .onTapGesture { showCommandPalette = false }

                    CommandPalette(
                        isPresented: $showCommandPalette,
                        deals:       deals,
                        onNavigate: { profile in
                            wm.activeProfile = profile
                            showComparison   = false
                        },
                        onSelectDeal: { deal in
                            wm.selectedDealID = deal.id
                            wm.activeProfile  = deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0
                                ? .hospitality
                                : .realEstate
                        },
                        onNewDeal:  { showNewDealSheet = true },
                        onExport:   {
                            NotificationCenter.default.post(name: .showExportSheet, object: nil)
                        }
                    )
                    .padding(.top, 100)
                }
            }
        }
        .sheet(isPresented: $showShortcutsPanel) {
            ShortcutsLegendView()
        }
        .sheet(isPresented: $showNewDealSheet) {
            TemplatePickerSheet { newID in
                pendingDealID    = newID
                wm.activeProfile = .realEstate
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showEmailSetup)) { _ in
            showEmailSetup = true
        }
        .sheet(isPresented: $showEmailSetup) {
            EmailSetupSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showSettings = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showQuickAdd)) { _ in
            showQuickAdd = true
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet { newID in
                pendingDealID    = newID
                wm.activeProfile = .realEstate
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showServerConfig)) { _ in
            showServerConfig = true
        }
        // Navigate to newly ingested deal + arm AI trigger
        .onReceive(NotificationCenter.default.publisher(for: .serverDidIngestDeal)) { notif in
            if let id = notif.userInfo?["dealID"] as? UUID {
                pendingDealID       = id
                pendingAITriggerID  = id
                wm.activeProfile    = .realEstate
            }
        }
        // Fire AI analysis once the deal is actually selected in the inspector
        .onChange(of: wm.selectedDealID) {
            if let id = pendingAITriggerID, wm.selectedDealID == id {
                pendingAITriggerID = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    NotificationCenter.default.post(
                        name: .autoTriggerAI, object: nil,
                        userInfo: ["dealID": id]
                    )
                }
            }
        }
        .sheet(isPresented: $showServerConfig) {
            ServerConfigSheet()
        }
        // ── Ingestion toast (top-right corner) ────────────────────────────────
        .overlay(alignment: .topTrailing) {
            if let toast = toastManager.current {
                IngestionToastView(toast: toast) {
                    wm.selectedDealID = toast.dealID
                    wm.activeProfile  = .realEstate
                }
                .padding(.top, 48)   // clear the TopHeaderBar
                .padding(.trailing, 12)
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .trailing).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast.id)
            }
        }
    }

    // MARK: Center Pane

    @ViewBuilder
    private var centerPane: some View {
        if showComparison && compareDeals.count >= 2 {
            ComparisonView(deals: compareDeals) {
                showComparison = false
                compareDeals   = []
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shellBg)
        } else if wm.activeProfile == .cmdCenter {
            CmdCenterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(shellBg)
        } else if let deal = selectedDeal {
            let viewModel = PropertyDealViewModel(deal: deal)
            VStack(spacing: 0) {
                PorteosScoreBlock(metrics: viewModel.porteosScore)
                Rectangle().fill(shellBg).frame(height: 16)
                switch wm.activeProfile {
                case .realEstate:  RealEstateDashboardView(deal: deal)
                case .hospitality: HospitalityDashboardView(deal: deal)
                case .design:      DesignDashboardView(deal: deal)
                case .circular:    CircularEconomyDashboardView(deal: deal)
                default:           profilePlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shellBg)
        } else {
            switch wm.activeProfile {
            case .realEstate: realEstateNoDealState
            default:          noDealState
            }
        }
    }

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
        wm.selectedDealID = deal.id
        wm.activeProfile  = .realEstate
    }

    private var profilePlaceholder: some View {
        VStack {
            Spacer()
            VStack(spacing: 4) {
                Text("01 // \(wm.activeProfile.displayName)")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .foregroundStyle(wm.activeProfile.accentColor)
                Text("MODULE NOT YET IMPLEMENTED")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }

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

    // MARK: Tear-Away Helpers

    /// Detach button overlaid at the top-right of each attached pane.
    /// Reattach is handled by DetachedWindowHeader inside the floating window.
    private func detachButton(for pane: WindowManager.PaneType) -> some View {
        Button { wm.detach(pane) } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
        }
        .buttonStyle(.plain)
        .padding(8)
        .help("Detach to separate window")
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
