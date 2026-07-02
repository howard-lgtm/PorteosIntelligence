import SwiftUI
import SwiftData

// MARK: - InspectorPane

struct InspectorPane: View {

    @Bindable var deal: PropertyDeal
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab        = "weights"
    @State private var showFullEditSheet  = false
    @State private var showingPDFReport   = false
    /// Bumped every time deal data changes. Forwarded to AIVibePanel so it can
    /// invalidate its in-memory result without InspectorPane reaching into its state.
    @State private var vibeRefreshID      = UUID()
    @State private var convictionLevel:  Int = 1   // 0=low ( ), 1=med (•), 2=high (*)

    private var history: DealHistoryManager { DealHistoryManager.shared }

    // MARK: Tokens (V2.06)

    private var shellBg:       Color { DesignTokens.canvasBase }
    private var shellSurface:  Color { DesignTokens.surfacePanel }
    private var shellBorder:   Color { DesignTokens.dividerStructural }
    private var textPrimary:   Color { DesignTokens.textPrimary }
    private var textSecondary: Color { DesignTokens.textSecondary }
    private var textTertiary:  Color { DesignTokens.textDim }
    private var accentRust:    Color { DesignTokens.accentRust }

    private var accentRe: Color { ProfileType.realEstate.accentColor }
    private var accentHo: Color { ProfileType.hospitality.accentColor }
    private var accentDe: Color { ProfileType.design.accentColor }
    private var accentCi: Color { ProfileType.circular.accentColor }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            paneHeader
            historyBar
            Rectangle().fill(shellBorder).frame(height: 1)
            tabBar

            Rectangle()
                .fill(shellBorder)
                .frame(height: 1)

            switch selectedTab {
            case "weights": weightsContent
            default:        aiVibeContent
            }

            Spacer(minLength: 0)
        }
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(shellSurface)
        .clipShape(Rectangle())
        .sheet(isPresented: $showFullEditSheet) {
            FullDealEditSheet(deal: deal)
        }
        .sheet(isPresented: $showingPDFReport) {
            PDFReportSheet(deal: deal)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showEditDeal)) { _ in
            showFullEditSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPDFReport)) { _ in
            showingPDFReport = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .undoDealEdit)) { _ in
            performUndo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .redoDealEdit)) { _ in
            performRedo()
        }
        .onChange(of: deal.updatedAt) {
            deal.aiAnalysisText = nil
            vibeRefreshID       = UUID()
        }
        // Auto-trigger AI analysis when a deal is imported via browser extension / server
        .onReceive(NotificationCenter.default.publisher(for: .autoTriggerAI)) { notif in
            guard let id = notif.userInfo?["dealID"] as? UUID,
                  deal.id == id else { return }
            deal.aiAnalysisText = nil
            vibeRefreshID       = UUID()
        }
        .onAppear { loadConvictionFromTags() }
        .onChange(of: deal.id) { _, _ in loadConvictionFromTags() }
    }

    // MARK: Pane Header

    private var paneHeader: some View {
        VStack(spacing: 0) {
            // Module header line
            Text("./INSPECTOR_V2")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 36)

            Rectangle().fill(shellBorder).frame(height: 1)

            // Action buttons row
            HStack(spacing: 8) {
                // Primary: EDIT DEAL DATA (Rust fill)
                Button { showFullEditSheet = true } label: {
                    Text("[ EDIT DEAL DATA ]")
                        .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                        .foregroundStyle(DesignTokens.canvasBase)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(accentRust)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Secondary: PDF (bordered, no fill)
                Button { showingPDFReport = true } label: {
                    Text("[ PDF ]")
                        .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                        .foregroundStyle(accentRust)
                        .frame(width: 64, height: 28)
                        .background(accentRust.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .stroke(accentRust.opacity(0.45), lineWidth: 1)
                        )
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: History Bar

    private var historyBar: some View {
        HStack(spacing: 0) {
            // ── Undo ───────────────────────────────────────────────────────
            Button { performUndo() } label: {
                Text("[ ↩ ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .foregroundStyle(history.canUndo ? textSecondary : textTertiary.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!history.canUndo)
            .padding(.leading, 16)

            if history.canUndo {
                Text(history.undoLabel)
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 5)
            }

            Spacer()

            // ── Redo ───────────────────────────────────────────────────────
            if history.canRedo {
                Text(history.redoLabel)
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.trailing, 5)
            }

            Button { performRedo() } label: {
                Text("[ ↪ ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .foregroundStyle(history.canRedo ? textSecondary : textTertiary.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!history.canRedo)
            .padding(.trailing, 16)
        }
        .frame(height: 26)
        .background(shellBg)
    }

    // MARK: Undo / Redo Execution

    private func performUndo() {
        guard let snap = history.undo(currentState: deal) else { return }
        history.apply(snap, to: deal)
        deal.updatedAt = Date()
        try? modelContext.save()
    }

    private func performRedo() {
        guard let snap = history.redo(currentState: deal) else { return }
        history.apply(snap, to: deal)
        deal.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "WEIGHTS", id: "weights")
            tabButton(title: "AI VIBE", id: "ai_vibe")
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
    }

    private func tabButton(title: String, id: String) -> some View {
        let isActive = selectedTab == id

        return Button {
            selectedTab = id
        } label: {
            VStack(spacing: 0) {
                Spacer()

                Text("[\(title)]")
                    .font(.custom("JetBrains Mono", size: 13).weight(isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? textPrimary : textTertiary)
                    .padding(.horizontal, 4)

                Spacer()

                // Active: 2px Rust underline; inactive: transparent
                Rectangle()
                    .fill(isActive ? accentRust : Color.clear)
                    .frame(height: 2)
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
    }

    // MARK: Weights Content

    private var weightsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                weightRow(
                    label: "Real Estate",
                    value: deal.weightRealEstate,
                    accentColor: accentRe,
                    key: "re"
                )
                rowDivider
                weightRow(
                    label: "Hospitality",
                    value: deal.weightHospitality,
                    accentColor: accentHo,
                    key: "ho"
                )
                rowDivider
                weightRow(
                    label: "Design",
                    value: deal.weightDesign,
                    accentColor: accentDe,
                    key: "de"
                )
                rowDivider
                weightRow(
                    label: "Circular Economy",
                    value: deal.weightCircular,
                    accentColor: accentCi,
                    key: "ci"
                )
                rowDivider
                totalRow
                rowDivider
                founderLensSection
                if !displayTags.isEmpty {
                    rowDivider
                    tagRepositorySection
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: Founder Lens (V2.06 Tier C)

    private var founderLensSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// FOUNDER_LENS")
                .font(DesignTokens.sectionLabelFont())
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            HStack(spacing: 16) {
                convictionNode(level: 0, marker: "( )", label: "LOW")
                convictionNode(level: 1, marker: "(•)", label: "MED")
                convictionNode(level: 2, marker: "(*)", label: "HIGH")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func convictionNode(level: Int, marker: String, label: String) -> some View {
        let isActive = convictionLevel == level
        return Button {
            convictionLevel = level
            persistConviction(level)
        } label: {
            HStack(spacing: 6) {
                Text(marker)
                    .font(DesignTokens.mono(size: 13, weight: .bold))
                    .foregroundStyle(isActive ? accentRust : textTertiary)
                Text(label)
                    .font(DesignTokens.mono(size: 10, weight: .bold))
                    .foregroundStyle(isActive ? textPrimary : textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private var displayTags: [String] {
        deal.tags.filter { !$0.hasPrefix("conviction:") }
    }

    private var tagRepositorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// TAG_REPOSITORY")
                .font(DesignTokens.sectionLabelFont())
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            FlowLayoutTags(tags: displayTags)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }

    private func loadConvictionFromTags() {
        if deal.tags.contains("conviction:high")      { convictionLevel = 2 }
        else if deal.tags.contains("conviction:low") { convictionLevel = 0 }
        else                                         { convictionLevel = 1 }
    }

    private func persistConviction(_ level: Int) {
        deal.tags.removeAll { $0.hasPrefix("conviction:") }
        switch level {
        case 0:  deal.tags.append("conviction:low")
        case 2:  deal.tags.append("conviction:high")
        default: deal.tags.append("conviction:med")
        }
        try? modelContext.save()
    }

    // MARK: Weight Row

    private func weightRow(
        label: String,
        value: Double,
        accentColor: Color,
        key: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .tracking(0.08)
                    .foregroundStyle(textTertiary)

                Spacer()

                Text("\(value, specifier: "%.1f")%")
                    .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)
            }

            TerminalSlider(value: value, accentColor: accentColor) { newValue in
                rebalanceWeights(changed: key, newValue: newValue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Total Row

    private var totalRow: some View {
        let total = deal.weightRealEstate
                  + deal.weightHospitality
                  + deal.weightDesign
                  + deal.weightCircular

        return HStack {
            Text("TOTAL")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textTertiary)

            Spacer()

            Text("\(total, specifier: "%.1f")%")
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(abs(total - 100) < 0.01 ? textPrimary : Color(hex: "#EF4444"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    // MARK: AI Vibe Content

    private var aiVibeContent: some View {
        AIVibePanel(deal: deal, refreshID: vibeRefreshID)
    }

    // MARK: Rebalance Logic

    private func rebalanceWeights(changed: String, newValue: Double) {
        let clamped = max(0, min(100, newValue))

        let re = deal.weightRealEstate
        let ho = deal.weightHospitality
        let de = deal.weightDesign
        let ci = deal.weightCircular

        typealias WeightPair = (key: String, value: Double)
        let others: [WeightPair]
        switch changed {
        case "re": others = [("ho", ho), ("de", de), ("ci", ci)]
        case "ho": others = [("re", re), ("de", de), ("ci", ci)]
        case "de": others = [("re", re), ("ho", ho), ("ci", ci)]
        default:   others = [("re", re), ("ho", ho), ("de", de)]
        }

        let otherTotal = others.reduce(0) { $0 + $1.value }
        let remaining  = max(0, 100 - clamped)

        for pair in others {
            let adjusted = otherTotal > 0
                ? pair.value * remaining / otherTotal
                : remaining / 3

            switch pair.key {
            case "re": deal.weightRealEstate  = adjusted
            case "ho": deal.weightHospitality = adjusted
            case "de": deal.weightDesign      = adjusted
            default:   deal.weightCircular    = adjusted
            }
        }

        switch changed {
        case "re": deal.weightRealEstate  = clamped
        case "ho": deal.weightHospitality = clamped
        case "de": deal.weightDesign      = clamped
        default:   deal.weightCircular    = clamped
        }
    }
}

// MARK: - TerminalSlider

private struct TerminalSlider: View {

    let value: Double
    let accentColor: Color
    let onChange: (Double) -> Void

    private let shellBorder  = Color(hex: "#2E333F")
    private let trackHeight: CGFloat = 2
    private let thumbWidth:  CGFloat = 8
    private let thumbHeight: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let fillWidth  = CGFloat(value / 100) * trackWidth
            let thumbX     = fillWidth - thumbWidth / 2

            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(shellBorder)
                    .frame(height: trackHeight)

                // Fill
                Rectangle()
                    .fill(accentColor)
                    .frame(width: max(0, fillWidth), height: trackHeight)

                // Thumb
                Rectangle()
                    .fill(accentColor)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .offset(x: max(0, min(thumbX, trackWidth - thumbWidth)))
                    .clipShape(Rectangle())
            }
            .frame(height: thumbHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let raw = gesture.location.x / trackWidth * 100
                        onChange(max(0, min(100, raw)))
                    }
            )
        }
        .frame(height: thumbHeight)
    }
}

// MARK: - FlowLayoutTags

private struct FlowLayoutTags: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 90), spacing: 6)],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(tags, id: \.self) { tag in
                TerminalTagChip(name: tag)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal = PropertyDeal()
    container.mainContext.insert(deal)

    return HStack(spacing: 0) {
        Spacer()
        InspectorPane(deal: deal)
    }
    .frame(width: 600, height: 700)
    .background(Color(hex: "#0F1115"))
    .modelContainer(container)
}
