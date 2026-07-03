import SwiftUI
import SwiftData

// MARK: - InspectorPane
// V2.06 — Figma img_00_21 + LOCK inspector-weights anatomy.

struct InspectorPane: View {

    @Bindable var deal: PropertyDeal
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab        = "weights"
    @State private var showFullEditSheet  = false
    @State private var showingPDFReport   = false
    @State private var vibeRefreshID      = UUID()
    @State private var convictionLevel:  Int = 1

    private var history: DealHistoryManager { DealHistoryManager.shared }

    // MARK: Tokens

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
            tabBar
            fullWidthDivider

            switch selectedTab {
            case "weights": weightsContent
            default:        aiVibeContent
            }

            Spacer(minLength: 0)
            fullWidthDivider
            historyBar
        }
        .frame(width: DesignTokens.inspectorPaneWidth)
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
        .onReceive(NotificationCenter.default.publisher(for: .autoTriggerAI)) { notif in
            guard let id = notif.userInfo?["dealID"] as? UUID,
                  deal.id == id else { return }
            deal.aiAnalysisText = nil
            vibeRefreshID       = UUID()
        }
        .onAppear { loadConvictionFromTags() }
        .onChange(of: deal.id) { _, _ in loadConvictionFromTags() }
    }

    // MARK: Pane Header — ./INSPECTOR_V2 + action buttons (28px)

    private var paneHeader: some View {
        VStack(spacing: 0) {
            Text("./INSPECTOR_V2")
                .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue))
                .foregroundStyle(textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.blockGutter)
                .frame(height: DesignTokens.rowHeightHeader)

            fullWidthDivider

            HStack(spacing: 8) {
                Button { showFullEditSheet = true } label: {
                    Text("[ EDIT DEAL DATA ]")
                        .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                        .foregroundStyle(shellBg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(accentRust)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button { showingPDFReport = true } label: {
                    Text("[ PDF ]")
                        .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                        .foregroundStyle(accentRust)
                        .frame(width: 64, height: 28)
                        .background(accentRust.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .stroke(accentRust.opacity(0.45), lineWidth: DesignTokens.dividerWidth)
                        )
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)

            fullWidthDivider
        }
    }

    // MARK: History Bar (footer — Figma img_00_21)

    private var historyBar: some View {
        HStack(spacing: 0) {
            Button { performUndo() } label: {
                Text("[ UNDO ]")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
                    .foregroundStyle(history.canUndo ? textSecondary : textTertiary.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!history.canUndo)
            .padding(.leading, DesignTokens.blockGutter)

            if history.canUndo {
                Text(history.undoLabel)
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 5)
            }

            Spacer()

            if history.canRedo {
                Text(history.redoLabel)
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.trailing, 5)
            }

            Button { performRedo() } label: {
                Text("[ REDO ]")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
                    .foregroundStyle(history.canRedo ? textSecondary : textTertiary.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!history.canRedo)
            .padding(.trailing, DesignTokens.blockGutter)
        }
        .frame(height: DesignTokens.rowHeightData)
        .background(shellBg)
    }

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

    // MARK: Tab Bar — [WEIGHTS] 2px rust underline | [AI VIBE]

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "WEIGHTS", id: "weights")
            tabButton(title: "AI VIBE", id: "ai_vibe")
            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
    }

    private func tabButton(title: String, id: String) -> some View {
        let isActive = selectedTab == id

        return Button {
            selectedTab = id
        } label: {
            VStack(spacing: 0) {
                Spacer()

                Text("[\(title)]")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? textPrimary : textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(isActive ? DesignTokens.surfaceElevated : Color.clear)

                Spacer()

                Rectangle()
                    .fill(isActive ? accentRust : Color.clear)
                    .frame(height: DesignTokens.navSelectionBorder)
            }
            .frame(height: DesignTokens.rowHeightHeader)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
    }

    // MARK: Weights Content

    private var weightsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                weightRow(label: "Real Estate",       value: deal.weightRealEstate,  accentColor: accentRe, key: "re")
                insetDivider
                weightRow(label: "Hospitality",       value: deal.weightHospitality, accentColor: accentHo, key: "ho")
                insetDivider
                weightRow(label: "Design",            value: deal.weightDesign,      accentColor: accentDe, key: "de")
                insetDivider
                weightRow(label: "Circular Economy",  value: deal.weightCircular,  accentColor: accentCi, key: "ci")
                insetDivider
                totalRow
                insetDivider
                founderLensSection
                if !displayTags.isEmpty {
                    insetDivider
                    tagRepositorySection
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: Founder Lens

    private var founderLensSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// FOUNDER_LENS")
                .font(DesignTokens.sectionLabelFont())
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 12)

            HStack(spacing: 16) {
                convictionNode(level: 0, marker: "( )", label: "LOW")
                convictionNode(level: 1, marker: "(•)", label: "MED")
                convictionNode(level: 2, marker: "( )", label: "HIGH")
            }
            .padding(.horizontal, DesignTokens.blockGutter)
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
                Text(isActive ? "(•)" : marker)
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                    .foregroundStyle(isActive ? accentRust : textTertiary)
                Text(label)
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.meta, weight: .bold))
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
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 8)

            FlowLayoutTags(tags: displayTags)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.bottom, 12)
        }
    }

    private func loadConvictionFromTags() {
        if deal.tags.contains("conviction:high")      { convictionLevel = 2 }
        else if deal.tags.contains("conviction:low")  { convictionLevel = 0 }
        else                                          { convictionLevel = 1 }
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

    // MARK: Weight Row — label + value + 2px profile bar (Figma img_00_21)

    private func weightRow(
        label: String,
        value: Double,
        accentColor: Color,
        key: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                    .tracking(0.08)
                    .foregroundStyle(textTertiary)

                Spacer()

                Text("\(value, specifier: "%.1f")%")
                    .font(DesignTokens.metricValueFont())
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)
            }

            InspectorWeightBar(value: value, accentColor: accentColor) { newValue in
                rebalanceWeights(changed: key, newValue: newValue)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 12)
    }

    private var totalRow: some View {
        let total = deal.weightRealEstate
                  + deal.weightHospitality
                  + deal.weightDesign
                  + deal.weightCircular

        return HStack {
            Text("TOTAL")
                .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                .tracking(0.08)
                .foregroundStyle(textTertiary)

            Spacer()

            Text("\(total, specifier: "%.1f")%")
                .font(DesignTokens.metricValueFont())
                .monospacedDigit()
                .foregroundStyle(abs(total - 100) < 0.01 ? textPrimary : DesignTokens.statusCritical)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 12)
    }

    private var fullWidthDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.horizontal, DesignTokens.blockGutter)
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

// MARK: - InspectorWeightBar
// Figma img_00_21 — thin 2px profile-colored fill, no thumb block.

private struct InspectorWeightBar: View {

    let value: Double
    let accentColor: Color
    let onChange: (Double) -> Void

    private let trackHeight: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let fillWidth  = CGFloat(value / 100) * trackWidth

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DesignTokens.dividerStructural)
                    .frame(height: trackHeight)

                Rectangle()
                    .fill(accentColor)
                    .frame(width: max(0, fillWidth), height: trackHeight)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard trackWidth > 0 else { return }
                        let raw = gesture.location.x / trackWidth * 100
                        onChange(max(0, min(100, raw)))
                    }
            )
        }
        .frame(height: 12)
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
    let deal = PropertyDeal(
        propertyName: "Lisbon Office Block A",
        weightRealEstate: 25,
        weightHospitality: 25,
        weightDesign: 25,
        weightCircular: 25
    )
    deal.tags = ["browser_import", "source:idealista", "has_url"]
    container.mainContext.insert(deal)

    return HStack(spacing: 0) {
        Spacer()
        InspectorPane(deal: deal)
    }
    .frame(width: 600, height: 700)
    .background(DesignTokens.canvasBase)
    .modelContainer(container)
}
