import SwiftUI
import SwiftData

// MARK: - BatchTriageView

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
        GridItem(.flexible(), spacing: DesignTokens.blockSpacing),
        GridItem(.flexible(), spacing: DesignTokens.blockSpacing),
        GridItem(.flexible(), spacing: DesignTokens.blockSpacing)
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
        .frame(minWidth: 760, minHeight: 540)
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

    private var header: some View {
        HStack(spacing: 16) {
            HStack(spacing: 0) {
                Text("porteos@system ~ % ")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textDim)
                Text("deal --triage")
                    .font(DesignTokens.mono(size: 11, weight: .bold))
                    .foregroundStyle(DesignTokens.accentRust)
            }
            Spacer()
            statPill("TOTAL",     "\(pipelineDeals.count)")
            statPill("SELECTED",  "\(selectedDealIDs.count)")
            statPill("AVG_SCORE", averageScore)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 12)
        .background(DesignTokens.surfacePanel)
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(DesignTokens.mono(size: 10))
                .foregroundStyle(DesignTokens.textDim)
            Text(value)
                .font(DesignTokens.mono(size: 10, weight: .bold))
                .foregroundStyle(DesignTokens.textPrimary)
                .monospacedDigit()
        }
    }

    private var dealGrid: some View {
        Group {
            if pipelineDeals.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("> NO_PIPELINE_DEALS")
                        .font(DesignTokens.mono(size: 11))
                        .foregroundStyle(DesignTokens.textDim)
                    Text("> import deals or set status to PIPELINE to begin triage")
                        .font(DesignTokens.mono(size: 10))
                        .foregroundStyle(DesignTokens.textDim.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: DesignTokens.blockSpacing) {
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

    @ViewBuilder
    private func dealCard(_ deal: PropertyDeal) -> some View {
        let isSelected = selectedDealIDs.contains(deal.id)
        let isHovered  = hoveredDealID == deal.id
        let grade      = VibeGrade.from(score: deal.porteosScore)
        let heat       = cityHeat[deal.locationCity]

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(isSelected ? DesignTokens.accentRust : Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(Rectangle().stroke(isSelected ? DesignTokens.accentRust : DesignTokens.dividerStructural, lineWidth: 1))
                    .overlay(
                        Text(isSelected ? "✓" : "")
                            .font(DesignTokens.mono(size: 9, weight: .bold))
                            .foregroundStyle(DesignTokens.canvasBase)
                    )
                    .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(deal.propertyName.isEmpty ? "UNTITLED" : deal.propertyName.uppercased())
                        .font(DesignTokens.mono(size: 11, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)
                    Text(deal.locationCity.isEmpty ? "—" : deal.locationCity.uppercased())
                        .font(DesignTokens.mono(size: 10))
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                Spacer()

                VStack(spacing: 1) {
                    Text(deal.porteosScore.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(DesignTokens.mono(size: 20, weight: .bold))
                        .foregroundStyle(grade.semanticColor)
                        .monospacedDigit()
                    Text(grade.rawValue)
                        .font(DesignTokens.mono(size: 8, weight: .bold))
                        .foregroundStyle(grade.semanticColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)

            TerminalStructuralDivider()

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    metricLine("PRICE", formatCurrency(deal.purchasePrice))
                    metricLine("AREA",  deal.totalArea > 0 ? "\(Int(deal.totalArea)) m²" : "—")
                }
                Spacer()
                if let h = heat {
                    Text(h)
                        .font(DesignTokens.mono(size: 9, weight: .bold))
                        .foregroundStyle(heatColor(h))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(heatColor(h).opacity(0.12))
                        .clipShape(Rectangle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(isSelected ? DesignTokens.accentRust.opacity(0.07)
                    : (isHovered ? DesignTokens.surfacePanel : DesignTokens.canvasBase))
        .overlay(
            Rectangle().stroke(
                isSelected ? DesignTokens.accentRust : (isHovered ? DesignTokens.textDim : DesignTokens.dividerStructural),
                lineWidth: isSelected ? 1.5 : 1
            )
        )
        .clipShape(Rectangle())
        .contentShape(Rectangle())
        .onHover { hoveredDealID = $0 ? deal.id : (hoveredDealID == deal.id ? nil : hoveredDealID) }
        .onTapGesture { toggleSelection(deal.id) }
    }

    private func metricLine(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(DesignTokens.mono(size: 9))
                .foregroundStyle(DesignTokens.textDim)
            Text(value)
                .font(DesignTokens.mono(size: 9, weight: .bold))
                .foregroundStyle(DesignTokens.textSecondary)
                .monospacedDigit()
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("[ APPROVE_SELECTED ]") { approveSelected() }
                .buttonStyle(TerminalButtonStyle(color: .green))
                .disabled(selectedDealIDs.isEmpty)
                .opacity(selectedDealIDs.isEmpty ? 0.4 : 1)

            Button("[ REJECT_SELECTED ]") { rejectSelected() }
                .buttonStyle(TerminalButtonStyle(color: .red))
                .disabled(selectedDealIDs.isEmpty)
                .opacity(selectedDealIDs.isEmpty ? 0.4 : 1)

            Spacer()

            if !selectedDealIDs.isEmpty {
                Text("\(selectedDealIDs.count) selected  ·  A approve  ·  R reject  ·  Space toggle")
                    .font(DesignTokens.mono(size: 9))
                    .foregroundStyle(DesignTokens.textDim)
            }

            Button("[ DISMISS ]") { dismiss() }
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textSecondary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 12)
        .background(DesignTokens.surfacePanel)
    }

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

    private func computeHeat() {
        let cities = Set(pipelineDeals.map(\.locationCity)).filter { !$0.isEmpty }
        var result: [String: String] = [:]
        for city in cities {
            let heat = TrendAnalyzer.calculateMarketHeat(for: city, context: modelContext)
            if heat.level != "COOL" { result[city] = heat.level }
        }
        cityHeat = result
    }

    private func formatCurrency(_ v: Double) -> String {
        guard v > 0 else { return "—" }
        if v >= 1_000_000 { return String(format: "€%.2fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "€%.0fK", v / 1_000) }
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
        case .a, .b: return ProfileType.circular.accentColor
        case .c:     return DesignTokens.statusWarn
        case .d, .f: return DesignTokens.statusCritical
        }
    }
}
