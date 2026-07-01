import SwiftUI
import SwiftData

// MARK: - DetachedWindowHeader
// Shared top-bar rendered inside every detached NSWindow.

private struct DetachedWindowHeader: View {
    let title: String
    let pane:  WindowManager.PaneType

    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textTertiary = Color(hex: "#64748B")

    var body: some View {
        HStack(spacing: 0) {
            Text("// \(title)")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(textTertiary)
                .padding(.leading, 16)

            Spacer()

            Button { WindowManager.shared.reattach(pane) } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
            .help("Reattach to main window")
        }
        .frame(height: 32)
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
        .background(Color(hex: "#0F1115"))
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

    private let shellBg       = Color(hex: "#0F1115")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let shellBorder   = Color(hex: "#2E333F")

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
            let viewModel = PropertyDealViewModel(deal: deal)
            ScrollView {
                VStack(spacing: 0) {
                    PorteosScoreBlock(metrics: viewModel.porteosScore)
                    Rectangle().fill(shellBg).frame(height: 16)
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
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textSecondary)
            Text("select from the navigation panel")
                .font(.custom("JetBrains Mono", size: 11))
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

    private let shellSurface  = Color(hex: "#1A1D24")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

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
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(shellSurface)
            }
        }
    }
}
