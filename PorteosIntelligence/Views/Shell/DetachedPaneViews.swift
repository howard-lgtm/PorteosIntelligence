import SwiftUI
import SwiftData

// MARK: - DetachedWindowHeader
// Shared top-bar rendered inside every detached NSWindow.

private struct DetachedWindowHeader: View {
    let title: String
    let pane:  WindowManager.PaneType

    private var shellSurface: Color { DesignTokens.surfacePanel }
    private var shellBorder:  Color { DesignTokens.dividerStructural }
    private var textTertiary: Color { DesignTokens.textDim }

    var body: some View {
        HStack(spacing: 0) {
            Text("// \(title)")
                .porteosMeta()
                .foregroundStyle(textTertiary)
                .padding(.leading, DesignTokens.blockGutter)

            Spacer()

            Button { WindowManager.shared.reattach(pane) } label: {
                Text("[ ↗ ]")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, DesignTokens.blockGutter)
            .help("Reattach to main window")
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(shellSurface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(shellBorder).frame(height: 1)
        }
    }
}

// MARK: - DetachedNavigationView

/// Full NavigationPane in its own NSWindow. Syncs deal selection and active
/// profile back to WindowManager.shared so the main window and other detached
/// windows stay in step.
struct DetachedNavigationView: View {

    private let wm = WindowManager.shared

    @Query(sort: \PropertyDeal.createdAt, order: .reverse) private var deals: [PropertyDeal]
    @State private var showNewDealSheet = false
    @State private var showComparison   = false
    @State private var compareDeals:    [PropertyDeal] = []

    // MARK: WM-backed bindings

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

    var body: some View {
        VStack(spacing: 0) {
            DetachedWindowHeader(title: "NAVIGATION", pane: .navigation)
            NavigationPane(
                showNewDealSheet: $showNewDealSheet,
                selectedDeal:     selectedDealBinding,
                activeProfile:    activeProfileBinding,
                showComparison:   $showComparison,
                compareDeals:     $compareDeals
            )
        }
        .background(DesignTokens.canvasBase)
        .sheet(isPresented: $showNewDealSheet) {
            TemplatePickerSheet { _ in }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewDeal)) { _ in
            showNewDealSheet = true
        }
    }
}

// MARK: - DetachedCenterView

/// Mirrors AppShell's center pane logic. Comparison mode is intentionally
/// omitted — comparison is initiated from NavigationPane which lives in a
/// different window when both are detached.
struct DetachedCenterView: View {

    private let wm = WindowManager.shared

    @Query(sort: \PropertyDeal.createdAt, order: .reverse) private var deals: [PropertyDeal]

    private var shellBg:       Color { DesignTokens.canvasBase }
    private var textSecondary: Color { DesignTokens.textSecondary }
    private var textTertiary:  Color { DesignTokens.textDim }
    private var shellBorder:   Color { DesignTokens.dividerStructural }

    private var selectedDeal: PropertyDeal? {
        deals.first { $0.id == wm.selectedDealID }
    }

    var body: some View {
        VStack(spacing: 0) {
            DetachedWindowHeader(title: "ANALYSIS", pane: .center)
            content
        }
        .background(shellBg)
    }

    @ViewBuilder
    private var content: some View {
        if wm.activeProfile == .cmdCenter {
            CmdCenterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let deal = selectedDeal {
            ScrollView {
                VStack(spacing: 0) {
                    dashboardView(for: deal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shellBg)
        } else {
            noDealState
        }
    }

    @ViewBuilder
    private func dashboardView(for deal: PropertyDeal) -> some View {
        switch wm.activeProfile {
        case .realEstate:  RealEstateDashboardView(deal: deal)
        case .hospitality: HospitalityDashboardView(deal: deal)
        case .design:      DesignDashboardView(deal: deal)
        case .circular:    CircularEconomyDashboardView(deal: deal)
        default:           EmptyView()
        }
    }

    private var noDealState: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("no deal selected")
                .porteosRowValue()
                .foregroundStyle(textSecondary)
            Text("select from the navigation panel")
                .porteosRowLabel()
                .foregroundStyle(textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }
}

// MARK: - DetachedInspectorView

/// InspectorPane in its own NSWindow. Follows wm.selectedDealID in real-time.
struct DetachedInspectorView: View {

    private let wm = WindowManager.shared

    @Query(sort: \PropertyDeal.createdAt, order: .reverse) private var deals: [PropertyDeal]

    private var shellSurface:  Color { DesignTokens.surfacePanel }
    private var textSecondary: Color { DesignTokens.textSecondary }

    private var selectedDeal: PropertyDeal? {
        deals.first { $0.id == wm.selectedDealID }
    }

    var body: some View {
        VStack(spacing: 0) {
            DetachedWindowHeader(title: "INSPECTOR", pane: .inspector)
            if let deal = selectedDeal {
                InspectorPane(deal: deal)
            } else {
                VStack {
                    Spacer()
                    Text("no deal selected")
                        .porteosRowValue()
                        .foregroundStyle(textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(shellSurface)
            }
        }
    }
}
