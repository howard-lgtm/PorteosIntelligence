import SwiftUI

// MARK: - PaletteAction
// A static command the user can run from the palette.

struct PaletteAction: Identifiable {
    let id:       String
    let title:    String
    let subtitle: String
    let execute:  () -> Void
}

// MARK: - PaletteItem
// Unified result type combining deals and actions.

private enum PaletteItem: Identifiable {

    case deal(PropertyDeal)
    case action(PaletteAction)

    var id: String {
        switch self {
        case .deal(let d):   return "deal_\(d.id.uuidString)"
        case .action(let a): return "action_\(a.id)"
        }
    }

    var icon: String {
        switch self {
        case .deal:   return "[D]"
        case .action: return "[>]"
        }
    }

    var title: String {
        switch self {
        case .deal(let d):   return d.propertyName.isEmpty ? "Untitled Deal" : d.propertyName
        case .action(let a): return a.title
        }
    }

    var subtitle: String {
        switch self {
        case .deal(let d):
            let loc = d.locationCity.isEmpty ? "" : "\(d.locationCity) · "
            return "\(loc)\(d.status.rawValue.uppercased())"
        case .action(let a):
            return a.subtitle
        }
    }

    /// Execute the item's primary action and return whether to dismiss the palette.
    func execute(
        onNavigate:   (ProfileType) -> Void,
        onSelectDeal: (PropertyDeal) -> Void,
        onNewDeal:    () -> Void,
        onExport:     () -> Void
    ) {
        switch self {
        case .deal(let d):   onSelectDeal(d)
        case .action(let a): a.execute()
        }
    }
}

// MARK: - CommandPalette

struct CommandPalette: View {

    @Binding var isPresented: Bool
    let deals: [PropertyDeal]

    // Callbacks — supplied by AppShell
    var onNavigate:   (ProfileType) -> Void  = { _ in }
    var onSelectDeal: (PropertyDeal) -> Void = { _ in }
    var onNewDeal:    () -> Void             = {}
    var onExport:     () -> Void             = {}

    // MARK: State

    @State private var query         = ""
    @State private var selectedIndex = 0
    @FocusState private var fieldFocused: Bool

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentGreen   = Color(hex: "#10B981")

    // MARK: Static Actions

    private var actions: [PaletteAction] { [
        .init(id: "nav.cmd",   title: "Go to Command Center",   subtitle: "Navigate") { onNavigate(.cmdCenter)   },
        .init(id: "nav.re",    title: "Go to Real Estate",      subtitle: "Navigate") { onNavigate(.realEstate)  },
        .init(id: "nav.hosp",  title: "Go to Hospitality",      subtitle: "Navigate") { onNavigate(.hospitality) },
        .init(id: "nav.des",   title: "Go to Design",           subtitle: "Navigate") { onNavigate(.design)      },
        .init(id: "nav.circ",  title: "Go to Circular Economy", subtitle: "Navigate") { onNavigate(.circular)    },
        .init(id: "new.deal",  title: "New Deal",               subtitle: "Action")   { onNewDeal()              },
        .init(id: "export",    title: "Export Data",            subtitle: "Action")   { onExport()               },
    ] }

    // MARK: Filtered Results

    private var results: [PaletteItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()

        let dealItems: [PaletteItem] = deals
            .filter { deal in
                guard !q.isEmpty else { return true }
                return deal.propertyName.lowercased().contains(q)
                    || deal.locationCity.lowercased().contains(q)
                    || deal.status.rawValue.lowercased().contains(q)
            }
            .map { .deal($0) }

        let actionItems: [PaletteItem] = actions
            .filter { q.isEmpty || $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
            .map { .action($0) }

        return dealItems + actionItems
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputBar
            Rectangle().fill(shellBorder).frame(height: 1)

            if results.isEmpty {
                emptyState
            } else {
                resultList
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            hintBar
        }
        .frame(width: 500)
        .frame(maxHeight: 420)
        .background(shellSurface)
        .overlay {
            Rectangle().strokeBorder(shellBorder, lineWidth: 1)
        }
        .clipShape(Rectangle())
        .onAppear {
            fieldFocused   = true
            selectedIndex  = 0
        }
        .onChange(of: query) {
            selectedIndex = 0
        }
        .onChange(of: results.count) {
            selectedIndex = min(selectedIndex, max(results.count - 1, 0))
        }
    }

    // MARK: – Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text(">")
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .foregroundStyle(accentRust)

            TextField("Search deals or type a command…", text: $query)
                .font(.custom("JetBrains Mono", size: 14))
                .foregroundStyle(textPrimary)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                // ── Keyboard navigation ──────────────────────────────────────
                .onKeyPress(phases: .down) { press in
                    switch press.key {
                    case .upArrow:
                        selectedIndex = max(0, selectedIndex - 1)
                        return .handled
                    case .downArrow:
                        selectedIndex = min(results.count - 1, selectedIndex + 1)
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
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(shellBg)
    }

    // MARK: – Result List

    private var resultList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(results.indices, id: \.self) { i in
                        resultRow(results[i], index: i)
                            .id(i)
                        if i < results.count - 1 {
                            Rectangle()
                                .fill(shellBorder.opacity(0.5))
                                .frame(height: 1)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .onChange(of: selectedIndex) { _, newIndex in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    private func resultRow(_ item: PaletteItem, index: Int) -> some View {
        let isSelected = index == selectedIndex

        return Button {
            selectedIndex = index
            commitSelected()
        } label: {
            HStack(spacing: 0) {
                // Rust selection pip
                Rectangle()
                    .fill(isSelected ? accentRust : Color.clear)
                    .frame(width: 2)

                HStack(spacing: 10) {
                    // Icon tag
                    Text(item.icon)
                        .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                        .foregroundStyle(isSelected ? accentRust : textTertiary)
                        .frame(width: 28, alignment: .leading)

                    // Title
                    Text(item.title)
                        .font(.custom("JetBrains Mono", size: 13).weight(isSelected ? .bold : .regular))
                        .foregroundStyle(isSelected ? textPrimary : textSecondary)
                        .lineLimit(1)

                    Spacer()

                    // Subtitle / status
                    Text(item.subtitle)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(isSelected ? accentRust.opacity(0.8) : textTertiary)
                        .lineLimit(1)
                        .padding(.trailing, 16)
                }
                .padding(.leading, 12)
            }
            .frame(height: 40)
            .background(isSelected ? shellElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: – Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Text("no results for \"\(query)\"")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
                Text("try a deal name, city, or command")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary.opacity(0.6))
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(shellBg)
    }

    // MARK: – Hint Bar

    private var hintBar: some View {
        HStack(spacing: 16) {
            hintPair("↑↓", "navigate")
            hintPair("↩",  "select")
            hintPair("esc", "close")
            Spacer()
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
                .padding(.trailing, 16)
        }
        .padding(.leading, 16)
        .frame(height: 32)
        .background(shellBg)
    }

    private func hintPair(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(textPrimary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(hex: "#2E333F"))
                .clipShape(Rectangle())
            Text(label)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
        }
    }

    // MARK: – Helpers

    private func commitSelected() {
        guard !results.isEmpty,
              selectedIndex < results.count else { return }
        let item = results[selectedIndex]
        isPresented = false
        // Small delay so the palette dismisses before any sheet appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            item.execute(
                onNavigate:   onNavigate,
                onSelectDeal: onSelectDeal,
                onNewDeal:    onNewDeal,
                onExport:     onExport
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let deals = [
        PropertyDeal(propertyName: "Lisbon Office A",  locationCity: "Lisbon",  status: .viable),
        PropertyDeal(propertyName: "Porto Warehouse",  locationCity: "Porto",   status: .review),
        PropertyDeal(propertyName: "Cascais Villa",    locationCity: "Cascais", status: .pipeline),
    ]
    ZStack {
        Color(hex: "#0F1115").ignoresSafeArea()
        CommandPalette(
            isPresented: .constant(true),
            deals:       deals
        )
    }
    .frame(width: 700, height: 600)
}
