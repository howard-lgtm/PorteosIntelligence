import SwiftUI
import SwiftData

// MARK: - BatchTriageView
// Figma img_00_13 — deal card grid, approve/reject triage.

struct BatchTriageView: View {

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PropertyDeal.createdAt, order: .reverse)
    private var allDeals: [PropertyDeal]

    @State private var selectedDealIDs: Set<UUID> = []
    @State private var hoveredDealID:   UUID?     = nil
    @FocusState private var isFocused: Bool
    @State private var cityHeat: [String: String] = [:]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var pipelineDeals: [PropertyDeal] {
        allDeals.filter { $0.status == .pipeline }
    }

    private var averageScore: String {
        let scores = pipelineDeals.compactMap(\.porteosScore)
        guard !scores.isEmpty else { return "—" }
        return String(format: "%.1f", scores.reduce(0, +) / Double(scores.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            TerminalStructuralDivider()
            dealGrid
            TerminalStructuralDivider()
            footer
        }
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
        .frame(width: 800)
        .frame(minHeight: 560)
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            computeHeat()
        }
        .onKeyPress(.space)  { toggleHovered();   return .handled }
        .onKeyPress("a")     { approveSelected(); return .handled }
        .onKeyPress("r")     { rejectSelected();  return .handled }
        .onKeyPress(.escape) { dismiss();          return .handled }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            HStack(spacing: 0) {
                Text("porteos@system ~ % ")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textDim)
                Text("deal --triage")
                    .porteosModuleCmd()
                    .foregroundStyle(DesignTokens.accentRust)
            }
            Spacer()
            statPill("TOTAL", "\(pipelineDeals.count)")
            selectedStatPill
            statPill("AVG_SCORE", averageScore)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textPrimary)
                .monospacedDigit()
        }
    }

    private var selectedStatPill: some View {
        HStack(spacing: 4) {
            Text("SELECTED:")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text("\(selectedDealIDs.count)")
                .porteosMeta()
                .foregroundStyle(DesignTokens.canvasBase)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DesignTokens.accentRust)
                .clipShape(Rectangle())
        }
    }

    // MARK: Grid

    private var dealGrid: some View {
        Group {
            if pipelineDeals.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("> NO_PIPELINE_DEALS")
                        .porteosRowLabel()
                        .foregroundStyle(DesignTokens.textDim)
                    Text("> import deals or set status to PIPELINE to begin triage")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(pipelineDeals) { deal in
                            dealCard(deal)
                        }
                    }
                    .padding(DesignTokens.blockGutter)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Card

    @ViewBuilder
    private func dealCard(_ deal: PropertyDeal) -> some View {
        let isSelected = selectedDealIDs.contains(deal.id)
        let isHovered  = hoveredDealID == deal.id
        let grade      = VibeGrade.from(score: deal.porteosScore)
        let accent     = profileAccent(for: deal)

        HStack(spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    selectionBox(isSelected: isSelected)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(deal.propertyName.isEmpty ? "UNTITLED" : deal.propertyName.uppercased())
                            .porteosButtonPrimary()
                            .foregroundStyle(DesignTokens.textPrimary)
                            .lineLimit(1)
                        Text(deal.locationCity.isEmpty ? "—" : deal.locationCity)
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                    }

                    Spacer(minLength: 0)

                    Text(scoreGradeLabel(deal: deal, grade: grade))
                        .porteosRowValue()
                        .foregroundStyle(grade.semanticColor)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)

                TerminalStructuralDivider()

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        metricLine("PRICE", formatCurrency(deal.purchasePrice))
                        metricLine("AREA", areaLabel(for: deal))
                    }
                    Spacer()
                    if let badge = cardBadge(for: deal) {
                        Text(badge.label)
                            .porteosMeta()
                            .foregroundStyle(badge.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.12))
                            .overlay {
                                Rectangle().strokeBorder(badge.color.opacity(0.35), lineWidth: DesignTokens.dividerWidth)
                            }
                            .clipShape(Rectangle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .background(isSelected ? DesignTokens.accentRust.opacity(0.06)
                    : (isHovered ? DesignTokens.surfacePanel : DesignTokens.surfaceElevated))
        .overlay {
            Rectangle().stroke(
                isSelected ? DesignTokens.accentRust : DesignTokens.dividerStructural,
                lineWidth: isSelected ? 1.5 : DesignTokens.dividerWidth
            )
        }
        .clipShape(Rectangle())
        .contentShape(Rectangle())
        .onHover { hoveredDealID = $0 ? deal.id : (hoveredDealID == deal.id ? nil : hoveredDealID) }
        .onTapGesture { toggleSelection(deal.id) }
    }

    private func selectionBox(isSelected: Bool) -> some View {
        Rectangle()
            .fill(isSelected ? DesignTokens.accentRust : Color.clear)
            .frame(width: 14, height: 14)
            .overlay {
                Rectangle().strokeBorder(
                    isSelected ? DesignTokens.accentRust : DesignTokens.dividerStructural,
                    lineWidth: DesignTokens.dividerWidth
                )
            }
    }

    private func scoreGradeLabel(deal: PropertyDeal, grade: VibeGrade) -> String {
        let score = deal.porteosScore.map { "\(Int($0.rounded()))" } ?? "—"
        return "\(score) / \(grade.rawValue)"
    }

    private func metricLine(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .monospacedDigit()
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Button("[ APPROVE_SELECTED ]") { approveSelected() }
                .buttonStyle(TerminalButtonStyle(outlined: .green))
                .disabled(selectedDealIDs.isEmpty)

            Button("[ REJECT_SELECTED ]") { rejectSelected() }
                .buttonStyle(TerminalButtonStyle(outlined: .red))
                .disabled(selectedDealIDs.isEmpty)

            Spacer()

            HStack(spacing: 4) {
                Text("\(selectedDealIDs.count) selected  ·  A approve  ·  R reject  ·  Space toggle")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Text("[")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Text("*")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.accentRust)
                Text("]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Actions

    private func toggleSelection(_ id: UUID) {
        if selectedDealIDs.contains(id) { selectedDealIDs.remove(id) }
        else { selectedDealIDs.insert(id) }
    }

    private func toggleHovered() {
        guard let id = hoveredDealID else { return }
        toggleSelection(id)
    }

    private func approveSelected() {
        guard !selectedDealIDs.isEmpty else { return }
        for deal in pipelineDeals where selectedDealIDs.contains(deal.id) {
            deal.status = .viable
            deal.updatedAt = Date()
        }
        try? modelContext.save()
        selectedDealIDs.removeAll()
    }

    private func rejectSelected() {
        guard !selectedDealIDs.isEmpty else { return }
        for deal in pipelineDeals where selectedDealIDs.contains(deal.id) {
            deal.status = .rejected
            deal.updatedAt = Date()
        }
        try? modelContext.save()
        selectedDealIDs.removeAll()
    }

    // MARK: Helpers

    private func computeHeat() {
        let cities = Set(pipelineDeals.map(\.locationCity)).filter { !$0.isEmpty }
        var result: [String: String] = [:]
        for city in cities {
            result[city] = TrendAnalyzer.calculateMarketHeat(for: city, context: modelContext).level
        }
        cityHeat = result
    }

    private func profileAccent(for deal: PropertyDeal) -> Color {
        if deal.hospitalityRoomCount > 0 || deal.hospitalityADR > 0 {
            return ProfileType.hospitality.accentColor
        }
        if deal.designGFA > 0 || deal.designNIA > 0 {
            return ProfileType.design.accentColor
        }
        if deal.circularKgMaterialsUsed > 0 || deal.circularRecycledContentPct > 0 {
            return ProfileType.circular.accentColor
        }
        return ProfileType.realEstate.accentColor
    }

    private func areaLabel(for deal: PropertyDeal) -> String {
        if deal.hospitalityRoomCount > 0 {
            return "\(deal.hospitalityRoomCount) rooms"
        }
        if deal.totalArea > 0 {
            return "\(Int(deal.totalArea)) m²"
        }
        return "—"
    }

    private struct CardBadge {
        let label: String
        let color: Color
    }

    private func cardBadge(for deal: PropertyDeal) -> CardBadge? {
        let grade = VibeGrade.from(score: deal.porteosScore)
        if grade == .d || grade == .f {
            return CardBadge(label: "RISK", color: DesignTokens.statusCritical)
        }
        guard !deal.locationCity.isEmpty, let level = cityHeat[deal.locationCity] else { return nil }
        return CardBadge(label: level, color: heatColor(level))
    }

    private func formatCurrency(_ v: Double) -> String {
        guard v > 0 else { return "—" }
        if v >= 1_000_000 { return String(format: "€%.1fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "€%.0fk", v / 1_000) }
        return String(format: "€%.0f", v)
    }

    private func heatColor(_ level: String) -> Color {
        switch level {
        case "HOT":  return DesignTokens.statusCritical
        case "WARM": return DesignTokens.statusWarn
        case "COOL": return ProfileType.circular.accentColor
        default:     return DesignTokens.textDim
        }
    }
}

// MARK: - VibeGrade semantic color

private extension VibeGrade {
    var semanticColor: Color {
        switch self {
        case .a, .b: return DesignTokens.statusGo
        case .c:     return DesignTokens.statusWarn
        case .d, .f: return DesignTokens.statusCritical
        }
    }
}

#Preview {
    BatchTriageView()
        .modelContainer(for: PropertyDeal.self, inMemory: true)
}
