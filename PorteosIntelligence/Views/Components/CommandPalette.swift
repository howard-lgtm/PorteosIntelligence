import SwiftUI

// MARK: - CommandPalette
// Figma img_00_7 — DEALS list + ACTIONS + footer hints.

struct CommandPalette: View {

    @Binding var isPresented: Bool
    let deals: [PropertyDeal]

    var onSelectDeal: (PropertyDeal) -> Void = { _ in }
    var onNewDeal:    () -> Void             = {}
    var onImport:     () -> Void             = {}
    var onRunAI:      () -> Void             = {}

    @State private var query         = ""
    @State private var selectedIndex = 0
    @FocusState private var fieldFocused: Bool

    // MARK: Figma actions

    private struct PaletteAction: Identifiable {
        let id:          String
        let command:     String
        let description: String
        let execute:     () -> Void
    }

    private var actions: [PaletteAction] {
        [
            .init(id: "new",    command: "[ ./NEW_DEAL ]",     description: "Create new deal entry",   execute: onNewDeal),
            .init(id: "import", command: "[ ./IMPORT_DEALS ]", description: "Import CSV or API",       execute: onImport),
            .init(id: "ai",     command: "[ ./RUN_AI ]",       description: "Run portfolio analysis", execute: onRunAI),
        ]
    }

    private var filteredDeals: [PropertyDeal] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return deals }
        return deals.filter {
            $0.propertyName.lowercased().contains(q)
                || $0.locationCity.lowercased().contains(q)
                || $0.status.rawValue.lowercased().contains(q)
        }
    }

    private var filteredActions: [PaletteAction] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return actions }
        return actions.filter {
            $0.command.lowercased().contains(q)
                || $0.description.lowercased().contains(q)
        }
    }

    private var selectableCount: Int { filteredDeals.count + filteredActions.count }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar
            divider

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !filteredDeals.isEmpty {
                        sectionHeader("DEALS")
                        ForEach(Array(filteredDeals.enumerated()), id: \.element.id) { idx, deal in
                            dealRow(deal, index: idx)
                            if idx < filteredDeals.count - 1 { insetDivider }
                        }
                    }

                    if !filteredActions.isEmpty {
                        if !filteredDeals.isEmpty {
                            divider.padding(.vertical, 4)
                        }
                        sectionHeader("ACTIONS")
                        ForEach(Array(filteredActions.enumerated()), id: \.element.id) { idx, action in
                            actionRow(action, index: filteredDeals.count + idx)
                            if idx < filteredActions.count - 1 { insetDivider }
                        }
                    }

                    if filteredDeals.isEmpty && filteredActions.isEmpty {
                        emptyState
                    }
                }
            }
            .frame(maxHeight: 320)

            divider
            footerBar
        }
        .frame(width: 560)
        .background(DesignTokens.surfacePanel)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
        .onAppear {
            fieldFocused  = true
            selectedIndex = 0
        }
        .onChange(of: query) { selectedIndex = 0 }
        .onChange(of: selectableCount) {
            selectedIndex = min(selectedIndex, max(selectableCount - 1, 0))
        }
    }

    // MARK: Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("", text: $query, prompt: Text("SEARCH DEALS OR COMMANDS…").foregroundStyle(DesignTokens.textDim))
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .onKeyPress(phases: .down) { press in
                    switch press.key {
                    case .upArrow:
                        selectedIndex = max(0, selectedIndex - 1)
                        return .handled
                    case .downArrow:
                        selectedIndex = min(selectableCount - 1, selectedIndex + 1)
                        return .handled
                    case .return:
                        commitSelected()
                        return .handled
                    case .escape:
                        isPresented = false
                        return .handled
                    default:
                        return .ignored
                    }
                }

            Text("CMD+K")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Deal row

    private func dealRow(_ deal: PropertyDeal, index: Int) -> some View {
        let isSelected = selectedIndex == index

        return Button {
            selectedIndex = index
            openDeal(deal)
        } label: {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dealTitle(deal))
                        .porteosButtonPrimary()
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Text(dealMeta(deal))
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .lineLimit(1)
                }
                .padding(.leading, DesignTokens.blockGutter)

                Spacer(minLength: 8)

                Text("OPEN")
                    .porteosMeta()
                    .foregroundStyle(isSelected ? DesignTokens.accentRust : DesignTokens.textDim)
                    .padding(.trailing, DesignTokens.blockGutter)
            }
            .frame(minHeight: DesignTokens.rowHeightHeader + 8)
            .background(isSelected ? DesignTokens.surfaceElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Action row

    private func actionRow(_ action: PaletteAction, index: Int) -> some View {
        let isSelected = selectedIndex == index

        return Button {
            selectedIndex = index
            commitAction(action)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(action.command)
                    .porteosButtonPrimary()
                    .foregroundStyle(isSelected ? DesignTokens.accentRust : DesignTokens.textPrimary)

                Text(action.description)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
            .background(isSelected ? DesignTokens.surfaceElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Chrome

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var emptyState: some View {
        Text("no results for \"\(query.uppercased())\"")
            .porteosRowValue()
            .foregroundStyle(DesignTokens.textDim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            footerHint("navigate")
            footerHint("enter:select")
            footerHint("esc:close")
            footerHint("CMD+K:toggle")
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightCommandBar)
        .background(DesignTokens.canvasBase)
    }

    private func footerHint(_ text: String) -> some View {
        Text(text)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
    }

    private var divider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.leading, DesignTokens.blockGutter)
    }

    // MARK: Helpers

    private func dealTitle(_ deal: PropertyDeal) -> String {
        let name = deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
        return name.uppercased()
    }

    private func dealMeta(_ deal: PropertyDeal) -> String {
        let profile = profileAbbrev(for: deal)
        let status  = deal.status.rawValue.uppercased()
        let score   = Int((deal.porteosScore ?? 0).rounded())
        return "\(profile)  \(status)  \(score)pt"
    }

    private func profileAbbrev(for deal: PropertyDeal) -> String {
        if deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0 { return "HOSP" }
        if deal.designGFA > 0 { return "DES" }
        if deal.circularKgMaterialsUsed > 0 || deal.circularRecycledContentPct > 0 { return "CIRC" }
        return "RE"
    }

    private func commitSelected() {
        guard selectableCount > 0, selectedIndex < selectableCount else { return }
        if selectedIndex < filteredDeals.count {
            openDeal(filteredDeals[selectedIndex])
        } else {
            let actionIdx = selectedIndex - filteredDeals.count
            guard actionIdx < filteredActions.count else { return }
            commitAction(filteredActions[actionIdx])
        }
    }

    private func openDeal(_ deal: PropertyDeal) {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            onSelectDeal(deal)
        }
    }

    private func commitAction(_ action: PaletteAction) {
        isPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            action.execute()
        }
    }
}

// MARK: - Preview

#Preview {
    let deals = [
        PropertyDeal(propertyName: "Lisbon Office Block A", locationCity: "Lisbon", porteosScore: 87, status: .viable),
        PropertyDeal(propertyName: "Porto Waterfront",      locationCity: "Porto",  porteosScore: 74, status: .review),
        PropertyDeal(propertyName: "Madrid Logistics",      locationCity: "Madrid", porteosScore: 68, status: .pipeline),
    ]
    ZStack {
        DesignTokens.canvasBase.ignoresSafeArea()
        CommandPalette(isPresented: .constant(true), deals: deals)
    }
    .frame(width: 700, height: 600)
}
