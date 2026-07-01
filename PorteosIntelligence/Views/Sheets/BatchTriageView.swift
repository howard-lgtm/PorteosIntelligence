import SwiftUI
import SwiftData

// MARK: - BatchTriageView

struct BatchTriageView: View {

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Pull all deals; pipeline filtering is a computed property to avoid
    // SwiftData enum-predicate limitations.
    @Query(sort: \PropertyDeal.createdAt, order: .reverse)
    private var allDeals: [PropertyDeal]

    @State private var selectedDealIDs: Set<UUID> = []
    @State private var hoveredDealID:   UUID?     = nil
    @FocusState private var isFocused: Bool

    // Pre-computed per unique city so heat queries run once, not per card.
    @State private var cityHeat: [String: String] = [:]

    // MARK: Tokens

    private let shellBg      = Color(hex: "#0F1115")
    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let accentRust   = Color(hex: "#C25E30")
    private let tp1          = Color(hex: "#F8F9FA")
    private let tp2          = Color(hex: "#94A3B8")
    private let tp3          = Color(hex: "#64748B")
    private let green        = Color(hex: "#10B981")
    private let amber        = Color(hex: "#F59E0B")
    private let red          = Color(hex: "#EF4444")
    private let blue         = Color(hex: "#3B82F6")

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 8)]

    // MARK: Derived

    private var pipelineDeals: [PropertyDeal] {
        allDeals.filter { $0.status == .pipeline }
    }

    private var averageScore: String {
        let scores = pipelineDeals.compactMap(\.porteosScore)
        guard !scores.isEmpty else { return "—" }
        return String(format: "%.1f", scores.reduce(0, +) / Double(scores.count))
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(shellBorder).frame(height: 1)
            dealGrid
            Rectangle().fill(shellBorder).frame(height: 1)
            footer
        }
        .background(shellBg)
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

    // MARK: – Header

    private var header: some View {
        HStack(spacing: 16) {
            Text("porteos@system ~ % deal --triage")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(accentRust)

            Spacer()

            statPill("TOTAL",      "\(pipelineDeals.count)")
            statPill("SELECTED",   "\(selectedDealIDs.count)")
            statPill("AVG_SCORE",  averageScore)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(shellSurface)
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(tp3)
            Text(value)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(tp1)
                .monospacedDigit()
        }
    }

    // MARK: – Deal Grid

    private var dealGrid: some View {
        Group {
            if pipelineDeals.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("> NO_PIPELINE_DEALS")
                        .font(.custom("JetBrains Mono", size: 13))
                        .foregroundStyle(tp3)
                    Text("> import deals or set status to PIPELINE to begin triage")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(tp3.opacity(0.6))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(pipelineDeals) { deal in
                            dealCard(deal)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    @ViewBuilder
    private func dealCard(_ deal: PropertyDeal) -> some View {
        let isSelected = selectedDealIDs.contains(deal.id)
        let isHovered  = hoveredDealID == deal.id
        let grade      = VibeGrade.from(score: deal.porteosScore)
        let heat       = cityHeat[deal.locationCity]

        VStack(alignment: .leading, spacing: 0) {

            // ── Card header ────────────────────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {
                // Selection checkbox
                Rectangle()
                    .fill(isSelected ? accentRust : Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(Rectangle().stroke(isSelected ? accentRust : shellBorder, lineWidth: 1))
                    .overlay(
                        Text(isSelected ? "✓" : "")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(hex: "#0F1115"))
                    )
                    .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(deal.propertyName.isEmpty ? "UNTITLED" : deal.propertyName.uppercased())
                        .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                        .foregroundStyle(tp1)
                        .lineLimit(1)
                    Text(deal.locationCity.isEmpty ? "—" : deal.locationCity.uppercased())
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundStyle(tp2)
                }

                Spacer()

                // Porteos score badge
                VStack(spacing: 1) {
                    Text(deal.porteosScore.map { "\(Int($0.rounded()))" } ?? "—")
                        .font(.custom("JetBrains Mono", size: 20).weight(.bold))
                        .foregroundStyle(Color(hex: grade.hexColor))
                        .monospacedDigit()
                    Text(grade.rawValue)
                        .font(.custom("JetBrains Mono", size: 8).weight(.bold))
                        .foregroundStyle(Color(hex: grade.hexColor))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Rectangle().fill(shellBorder).frame(height: 1)

            // ── Card body ──────────────────────────────────────────────────────
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    metricLine("PRICE", formatCurrency(deal.purchasePrice))
                    metricLine("AREA",  deal.totalArea > 0 ? "\(Int(deal.totalArea)) m²" : "—")
                }
                Spacer()
                // Market heat badge
                if let h = heat {
                    Text(h)
                        .font(.custom("JetBrains Mono", size: 9).weight(.bold))
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
        .background(isSelected ? accentRust.opacity(0.07) : (isHovered ? shellSurface : shellBg))
        .overlay(
            Rectangle().stroke(
                isSelected ? accentRust : (isHovered ? tp3 : shellBorder),
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
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundStyle(tp3)
            Text(value)
                .font(.custom("JetBrains Mono", size: 9).weight(.bold))
                .foregroundStyle(tp2)
                .monospacedDigit()
        }
    }

    // MARK: – Footer

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
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundStyle(tp3)
            }

            Button("[ DISMISS ]") { dismiss() }
                .buttonStyle(TerminalButtonStyle(color: .muted))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(shellSurface)
    }

    // MARK: – Actions

    private func toggleSelection(_ id: UUID) {
        if selectedDealIDs.contains(id) {
            selectedDealIDs.remove(id)
        } else {
            selectedDealIDs.insert(id)
        }
    }

    private func toggleHovered() {
        guard let id = hoveredDealID else { return }
        toggleSelection(id)
    }

    private func approveSelected() {
        guard !selectedDealIDs.isEmpty else { return }
        for deal in pipelineDeals where selectedDealIDs.contains(deal.id) {
            deal.status    = .viable
            deal.updatedAt = Date()
        }
        try? modelContext.save()
        selectedDealIDs.removeAll()
    }

    private func rejectSelected() {
        guard !selectedDealIDs.isEmpty else { return }
        for deal in pipelineDeals where selectedDealIDs.contains(deal.id) {
            deal.status    = .rejected
            deal.updatedAt = Date()
        }
        try? modelContext.save()
        selectedDealIDs.removeAll()
    }

    // MARK: – Heat pre-computation

    /// Runs once on appear. Queries market heat for each unique city so cards
    /// don't trigger individual SwiftData fetches inside LazyVGrid.
    private func computeHeat() {
        let cities = Set(pipelineDeals.map(\.locationCity)).filter { !$0.isEmpty }
        var result: [String: String] = [:]
        for city in cities {
            let heat = TrendAnalyzer.calculateMarketHeat(for: city, context: modelContext)
            if heat.level != "COOL" { result[city] = heat.level }   // only badge notable heat
        }
        cityHeat = result
    }

    // MARK: – Helpers

    private func formatCurrency(_ v: Double) -> String {
        guard v > 0 else { return "—" }
        if v >= 1_000_000 { return String(format: "€%.2fM", v / 1_000_000) }
        if v >= 1_000     { return String(format: "€%.0fK", v / 1_000) }
        return String(format: "€%.0f", v)
    }

    private func heatColor(_ level: String) -> Color {
        switch level {
        case "HOT":  return red
        case "WARM": return amber
        case "COOL": return blue
        default:     return tp3      // COLD
        }
    }
}
