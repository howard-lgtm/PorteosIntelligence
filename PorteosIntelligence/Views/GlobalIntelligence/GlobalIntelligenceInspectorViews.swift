import AppKit
import SwiftData
import SwiftUI

// MARK: - GlobalIntelligenceIdleInspector

struct GlobalIntelligenceIdleInspector: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("// SELECT_PIN_OR_MARKET")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textDim)
                Text("Tap a map pin for deal context, or select a market to see aggregate KPIs.")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
    }
}

// MARK: - GeoAssetInspectorPanel
// Figma frame 2 — slim 6-row deal panel shown in inspector when a GI map pin is selected.
// Deliberately NOT InspectorPane — no weights, no sliders. GI-specific context only.

struct GeoAssetInspectorPanel: View {

    let deal: PropertyDeal

    private let accent = ProfileType.globalIntelligence.accentColor

    // Always compute live so GI Inspector stays in sync with weight changes
    private var liveScore: PorteosScoreCalculator.PorteosMetrics {
        PropertyDealViewModel(deal: deal).porteosScore
    }
    private var grade: VibeGrade { VibeGrade.from(score: liveScore.finalScore) }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: label only — keep right edge clear of the [ ↗ ] detach overlay
            Text("// GI_INSPECTOR")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.blockGutter)
                .frame(height: DesignTokens.rowHeightHeader)
                .background(DesignTokens.surfacePanel)

            TerminalStructuralDivider()

            // Navigate to RE profile for full edit — avoids nested sheet ownership conflicts
            Button {
                WindowManager.shared.activeProfile = .realEstate
                // Brief delay so RE dashboard appears before the edit sheet opens
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NotificationCenter.default.post(name: .showEditDeal, object: deal.id)
                }
            } label: {
                Text("[ EDIT DEAL DATA ]")
                    .porteosMeta()
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.rowHeightData)
                    .background(accent.opacity(0.10))
                    .overlay { Rectangle().strokeBorder(accent.opacity(0.4), lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
            .background(DesignTokens.surfacePanel)

            TerminalStructuralDivider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    panelHeader
                    TerminalStructuralDivider()
                    kpiRow("STATUS",  deal.status.rawValue.uppercased(), color: deal.status.tokenColor)
                    kpiRow("SCORE",   String(format: "%.0f / 100", liveScore.finalScore))
                    kpiRow("GRADE",   grade.rawValue, color: Color(hex: grade.hexColor))
                    if deal.purchasePrice > 0 {
                        kpiRow("PRICE",   formatCurrency(deal.purchasePrice))
                    }
                    if deal.totalArea > 0 {
                        kpiRow("AREA",    UnitSystemService.shared.formatArea(deal.totalArea, country: deal.locationCountry))
                    }
                    kpiRow("GEOCODE", geocodeLabel, color: geocodeColor)

                    TerminalStructuralDivider()
                        .padding(.vertical, 10)

                    actionLink("[ OPEN IN REAL ESTATE ↗ ]") {
                        WindowManager.shared.activeProfile = .realEstate
                    }
                    actionLink("[ VIEW ON MAP ]") {
                        WindowManager.shared.geoActiveTab = "map"
                    }
                }
                .padding(DesignTokens.blockGutter)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
        // No .sheet here — sheet ownership belongs to AppShell only
    }

    private var panelHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("// ASSET_CONTEXT")
                .porteosMeta()
                .foregroundStyle(accent)
            Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName.uppercased())
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 12)
    }

    private var geocodeLabel: String {
        switch deal.geocodeStatus {
        case .ok:      return "✓ ok"
        case .pending: return "pending"
        case .failed:  return "failed"
        case .none:    return "—"
        }
    }

    private var geocodeColor: Color {
        switch deal.geocodeStatus {
        case .ok:      return DesignTokens.statusGo
        case .pending: return DesignTokens.statusWarn
        case .failed:  return DesignTokens.statusCritical
        case .none:    return DesignTokens.textDim
        }
    }

    private func kpiRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
            Spacer()
            Text(value)
                .porteosMeta()
                .foregroundStyle(color ?? DesignTokens.textSecondary)
        }
        .padding(.vertical, 8)
    }

    private func actionLink(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(accent)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 4)
    }

    private func formatCurrency(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        if value >= 1_000_000 {
            return String(format: "€%.2fM", value / 1_000_000)
        }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
    }
}

// MARK: - MarketContextInspector

struct MarketContextInspector: View {

    let marketId: String
    let deals: [PropertyDeal]

    private let accent = ProfileType.globalIntelligence.accentColor

    private var marketDeals: [PropertyDeal] {
        deals.filter { deal in
            if deal.marketId == marketId { return true }
            if let country = MarketFeedRegistry.countryId(for: marketId), deal.marketId == country { return true }
            if let parent = MarketFeedRegistry.market(id: deal.marketId)?.parentId, parent == marketId { return true }
            return false
        }
    }

    private var totalExposure: Double { marketDeals.reduce(0) { $0 + $1.purchasePrice } }
    private var geocodedCount: Int { marketDeals.filter(\.isGeocoded).count }

    private var avgScore: Double? {
        let scored = marketDeals.compactMap(\.porteosScore)
        guard !scored.isEmpty else { return nil }
        return scored.reduce(0, +) / Double(scored.count)
    }

    private var dominantStatus: DealStatus? {
        let counts = Dictionary(grouping: marketDeals, by: \.status).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // Static macro indicators per country (2024–2026 estimates, labelled // BENCHMARK)
    private struct MacroIndicators {
        let gdpGrowth: String
        let tourismIndex: String
    }

    private var macroIndicators: MacroIndicators? {
        let id = MarketFeedRegistry.countryId(for: marketId) ?? marketId
        switch id {
        case "PT": return MacroIndicators(gdpGrowth: "2.1 %", tourismIndex: "↑ +4%")
        case "ES": return MacroIndicators(gdpGrowth: "2.4 %", tourismIndex: "↑ +6%")
        case "IT": return MacroIndicators(gdpGrowth: "0.7 %", tourismIndex: "↑ +2%")
        case "FR": return MacroIndicators(gdpGrowth: "1.1 %", tourismIndex: "↑ +3%")
        case "UK": return MacroIndicators(gdpGrowth: "0.8 %", tourismIndex: "↑ +1%")
        case "DE": return MacroIndicators(gdpGrowth: "0.2 %", tourismIndex: "→ flat")
        case "HR": return MacroIndicators(gdpGrowth: "3.0 %", tourismIndex: "↑ +8%")
        case "GR": return MacroIndicators(gdpGrowth: "2.2 %", tourismIndex: "↑ +5%")
        case "SE": return MacroIndicators(gdpGrowth: "0.5 %", tourismIndex: "→ flat")
        case "DK": return MacroIndicators(gdpGrowth: "1.8 %", tourismIndex: "↑ +2%")
        case "NO": return MacroIndicators(gdpGrowth: "1.2 %", tourismIndex: "↑ +3%")
        case "FI": return MacroIndicators(gdpGrowth: "0.3 %", tourismIndex: "→ flat")
        case "US": return MacroIndicators(gdpGrowth: "2.8 %", tourismIndex: "↑ +5%")
        case "JP": return MacroIndicators(gdpGrowth: "0.9 %", tourismIndex: "↑ +18%")
        default:   return nil
        }
    }

    // Capital city of this market for benchmark lookup
    private var benchmarkCity: String {
        switch marketId {
        case "PT": return "Lisbon"
        case "ES": return "Madrid"
        case "IT": return "Rome"
        case "FR": return "Paris"
        case "UK": return "London"
        case "DE": return "Berlin"
        case "HR": return "Split"
        case "GR": return "Athens"
        case "SE": return "Stockholm"
        case "DK": return "Copenhagen"
        case "NO": return "Oslo"
        case "FI": return "Helsinki"
        case "US": return "New York"
        case "JP": return "Tokyo"
        default:
            if let market = MarketFeedRegistry.market(id: marketId) {
                return market.cityAliases.first?.capitalized ?? market.displayName
            }
            return marketId
        }
    }

    private var benchmark: CityMetrics? { MarketBenchmarks.benchmark(for: benchmarkCity) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                inspectorHeader
                TerminalStructuralDivider()

                kpiRow("ASSETS IN MARKET", "\(marketDeals.count)")
                kpiRow("ON MAP",           "\(geocodedCount)")
                kpiRow("TOTAL EXPOSURE",   formatCurrency(totalExposure))
                if let avg = avgScore {
                    kpiRow("AVG SCORE",    String(format: "%.0f / 100", avg))
                }
                if let status = dominantStatus {
                    kpiRow("MARKET",       status.rawValue.uppercased(),
                           color: status.tokenColor)
                }

                TerminalStructuralDivider()
                    .padding(.vertical, 2)

                if let bm = benchmark {
                    kpiRow("PRIME YIELD",  String(format: "%.2f %%", bm.avgCapRate),
                           note: "// 2024-25 ESTIMATE")
                    // Spread vs market lending rate (not hardcoded ECB)
                    let baseRate = bm.avgInterestRate
                    let spread   = bm.avgCapRate - baseRate
                    kpiRow("YIELD SPREAD", String(format: "%+.0f bps", spread * 100),
                           note: "// vs \(String(format: "%.1f", baseRate))% market rate")
                    kpiRow("INT. RATE",    String(format: "%.1f %%", bm.avgInterestRate),
                           note: "// 2024-25 ESTIMATE")
                }
                if let macro = macroIndicators {
                    kpiRow("GDP GROWTH",    macro.gdpGrowth,    note: "// STATIC 2024-25 ESTIMATE")
                    kpiRow("TOURISM INDEX", macro.tourismIndex, note: "// STATIC 2024-25 ESTIMATE")
                }

                if let market = MarketFeedRegistry.market(id: marketId),
                   market.investmentThesis.count > 0 {
                    TerminalStructuralDivider()
                        .padding(.vertical, 2)
                    Text("// THESIS")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .padding(.top, 8)
                    Text(market.investmentThesis)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }

                TerminalStructuralDivider()
                    .padding(.vertical, 10)

                Button {
                    exportMarketReport()
                } label: {
                    Text("[ EXPORT MARKET REPORT ]")
                        .porteosMeta()
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }
            .padding(DesignTokens.blockGutter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
    }

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("// MARKET_CONTEXT")
                .porteosMeta()
                .foregroundStyle(accent)
            Text(MarketFeedRegistry.market(id: marketId)?.displayName.uppercased() ?? marketId)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .padding(.bottom, 12)
    }

    private func kpiRow(_ label: String, _ value: String,
                        color: Color? = nil, note: String? = nil) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textDim)
                if let note {
                    Text(note)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .font(.system(size: 9, design: .monospaced))
                }
            }
            Spacer()
            Text(value)
                .porteosMeta()
                .foregroundStyle(color ?? DesignTokens.textSecondary)
        }
        .padding(.vertical, 7)
    }

    private func formatCurrency(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        if value >= 1_000_000 {
            return String(format: "€%.1fM", value / 1_000_000)
        }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
    }

    private func exportMarketReport() {
        let name = MarketFeedRegistry.market(id: marketId)?.displayName ?? marketId
        var lines = ["PORTEOS MARKET REPORT — \(name.uppercased())",
                     "Generated: \(ISO8601DateFormatter().string(from: Date()))", ""]
        lines.append("ASSETS IN MARKET: \(marketDeals.count)")
        lines.append("ON MAP: \(geocodedCount)")
        lines.append("TOTAL EXPOSURE: \(formatCurrency(totalExposure))")
        if let avg = avgScore { lines.append(String(format: "AVG SCORE: %.0f / 100", avg)) }
        if let bm = benchmark {
            lines.append(String(format: "PRIME YIELD: %.2f%% (2024-25 estimate)", bm.avgCapRate))
            let spread = bm.avgCapRate - bm.avgInterestRate
            lines.append(String(format: "YIELD SPREAD: %+.0f bps vs %.1f%% market rate", spread * 100, bm.avgInterestRate))
        }
        lines.append("")
        lines.append("DEALS:")
        for d in marketDeals {
            let price = formatCurrency(d.purchasePrice)
            let score = d.porteosScore.map { String(format: "%.0f", $0) } ?? "—"
            lines.append("  \(d.propertyName) · \(d.status.rawValue.uppercased()) · \(price) · Score \(score)")
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
    }
}

// MARK: - GeocodeStatusInspector
// Figma frame 4 — inspector when deals lack coordinates.

struct GeocodeStatusInspector: View {

    @Environment(\.modelContext) private var modelContext

    let deals: [PropertyDeal]

    private let accent = ProfileType.globalIntelligence.accentColor

    private var locatable: [PropertyDeal] {
        deals.filter { !$0.locationCity.isEmpty || !$0.address.isEmpty }
    }

    private var geocodedCount: Int { locatable.filter(\.isGeocoded).count }
    private var pendingCount: Int  { locatable.filter { !$0.isGeocoded && $0.geocodeStatus != .failed }.count }
    private var failedCount: Int   { locatable.filter { $0.geocodeStatus == .failed }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("// GEOCODE_STATUS")
                        .porteosMeta()
                        .foregroundStyle(accent)
                    Text("Portfolio coordinate health")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                .padding(.bottom, 12)

                TerminalStructuralDivider()
                kpiRow("GEOCODED", "\(geocodedCount) / \(locatable.count)")
                kpiRow("PENDING",  "\(pendingCount)")
                kpiRow("FAILED",   "\(failedCount)")

                if pendingCount > 0 || failedCount > 0 {
                    TerminalStructuralDivider()
                        .padding(.vertical, 10)
                    Button {
                        GeocodingService.shared.scheduleGeocodeAllPending(
                            deals: locatable.filter { $0.needsGeocode },
                            context: modelContext
                        )
                    } label: {
                        Text("[ RUN GEOCODE PASS ]")
                            .porteosMeta()
                            .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 8)

                    if !locatable.isEmpty {
                        TerminalStructuralDivider()
                            .padding(.vertical, 8)
                        Text("// GEOCODE_LOG")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                            .padding(.bottom, 4)
                        ForEach(locatable, id: \.id) { deal in
                            HStack {
                                Text(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)
                                    .porteosMeta()
                                    .foregroundStyle(DesignTokens.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(geocodeTag(deal))
                                    .porteosMeta()
                                    .foregroundStyle(geocodeTagColor(deal))
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
            .padding(DesignTokens.blockGutter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surfacePanel)
    }

    private func kpiRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
            Spacer()
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.vertical, 8)
    }

    private func geocodeTag(_ deal: PropertyDeal) -> String {
        switch deal.geocodeStatus {
        case .ok:      return "ok"
        case .pending: return "pending"
        case .failed:  return "failed"
        case .none:    return "—"
        }
    }

    private func geocodeTagColor(_ deal: PropertyDeal) -> Color {
        switch deal.geocodeStatus {
        case .ok:      return DesignTokens.statusGo
        case .pending: return DesignTokens.statusWarn
        case .failed:  return DesignTokens.statusCritical
        case .none:    return DesignTokens.textDim
        }
    }
}
