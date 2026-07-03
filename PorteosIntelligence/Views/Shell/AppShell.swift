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

    // MARK: Tokens (V2.06)

    private var shellBg:       Color { DesignTokens.canvasBase }
    private var shellSurface:  Color { DesignTokens.surfacePanel }
    private var shellBorder:   Color { DesignTokens.dividerStructural }
    private var textSecondary: Color { DesignTokens.textSecondary }
    private var textTertiary:  Color { DesignTokens.textDim }
    private var accentRust:    Color { DesignTokens.accentRust }

    // MARK: Layout Constants

    private var navPaneWidth:       CGFloat { DesignTokens.navPaneWidth }
    private var inspectorPaneWidth: CGFloat { DesignTokens.inspectorPaneWidth }
    private let dividerWidth:       CGFloat = 1

    // MARK: Body
    // Split into coreView + body to avoid Swift type-checker complexity limits
    // on long modifier chains.

    var body: some View {
        coreView
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
        .sheet(isPresented: $showServerConfig) {
            ServerConfigSheet()
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
        .onChange(of: wm.selectedDealID) { _, newID in
            guard let id = pendingAITriggerID, newID == id else { return }
            pendingAITriggerID = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                NotificationCenter.default.post(
                    name: .autoTriggerAI, object: nil,
                    userInfo: ["dealID": id]
                )
            }
        }
        // ── Ingestion toast (top-right corner) ────────────────────────────────
        .overlay(alignment: .topTrailing) {
            if let toast = toastManager.current {
                IngestionToastView(toast: toast) {
                    wm.selectedDealID = toast.dealID
                    wm.activeProfile  = .realEstate
                }
                .padding(.top, 48)
                .padding(.trailing, 12)
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .trailing).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast.id)
            }
        }
    }

    // MARK: Core View (first modifier batch)

    private var coreView: some View {
        VStack(spacing: 0) {
            TopHeaderBar(
                activeProfile: wm.activeProfile,
                selectedDealName: selectedDeal?.propertyName,
                onServerTap: { showServerConfig = true }
            )

            HStack(spacing: 0) {
                let navGone    = wm.detachedPanes.contains(.navigation)
                let centerGone = wm.detachedPanes.contains(.center)
                let inspGone   = wm.detachedPanes.contains(.inspector)

                if !navGone {
                    NavigationPane(
                        showNewDealSheet: $showNewDealSheet,
                        selectedDeal:     selectedDealBinding,
                        activeProfile:    activeProfileBinding,
                        showComparison:   $showComparison,
                        compareDeals:     $compareDeals
                    )
                    .overlay(alignment: .topTrailing) { detachButton(for: .navigation) }

                    if !centerGone || !inspGone { paneDivider }
                }

                if !centerGone {
                    centerPane
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .topTrailing) { detachButton(for: .center) }

                    if !inspGone { paneDivider }
                }

                if !inspGone {
                    inspectorPane
                        .overlay(alignment: .topTrailing) { detachButton(for: .inspector) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            GlobalCommandBar(lineCount: 0)
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .focusedValue(\.hasDealSelected, selectedDeal != nil)
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
        .onChange(of: deals) { _, _ in
            if let id = pendingDealID,
               deals.first(where: { $0.id == id }) != nil {
                wm.selectedDealID = id
                pendingDealID     = nil
            }
        }
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
        .overlay {
            if showCommandPalette {
                ZStack(alignment: .top) {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .onTapGesture { showCommandPalette = false }

                    CommandPalette(
                        isPresented: $showCommandPalette,
                        deals:       deals,
                        onSelectDeal: { deal in
                            wm.selectedDealID = deal.id
                            wm.activeProfile  = deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0
                                ? .hospitality
                                : .realEstate
                        },
                        onNewDeal: { showNewDealSheet = true },
                        onImport: {
                            NotificationCenter.default.post(name: .showImportDeals, object: nil)
                        },
                        onRunAI: {
                            if let deal = selectedDeal {
                                NotificationCenter.default.post(
                                    name: .autoTriggerAI,
                                    object: nil,
                                    userInfo: ["dealID": deal.id]
                                )
                            }
                            wm.activeProfile = .cmdCenter
                        }
                    )
                    .padding(.top, 100)
                }
            }
        }
        .overlay {
            if showShortcutsPanel {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .onTapGesture { showShortcutsPanel = false }

                    ShortcutsLegendView(onDismiss: { showShortcutsPanel = false })
                }
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
            Group {
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
            emptyCenterState
        }
    }

    private var emptyCenterState: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(textTertiary)
                Text("// no deals found")
                    .font(DesignTokens.rowValueFont())
                    .foregroundStyle(textSecondary)
                Button(action: loadSampleDeal) {
                    Text("[ ./LOAD_SAMPLE_DEAL ]")
                        .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                        .foregroundStyle(DesignTokens.statusGo)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
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
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                    .foregroundStyle(wm.activeProfile.accentColor)
                Text("MODULE NOT YET IMPLEMENTED")
                    .font(DesignTokens.rowLabelFont())
                    .foregroundStyle(textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
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
                    .font(DesignTokens.rowLabelFont())
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
