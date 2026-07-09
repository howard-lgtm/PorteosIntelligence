import SwiftData
import SwiftUI

// MARK: - GeoAssetContextCard
// Figma frame 2 — compact strip between map and news (not a full TerminalBlock).

struct GeoAssetContextCard: View {

    @Environment(\.modelContext) private var modelContext

    let deal: PropertyDeal
    var onDismiss: () -> Void

    private let accent = ProfileType.globalIntelligence.accentColor

    private var grade: VibeGrade { VibeGrade.from(score: deal.porteosScore) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: DesignTokens.profileBarHeight)

            VStack(alignment: .leading, spacing: 4) {
                headerRow
                Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)
                Text(contextLine)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineLimit(1)
                Text(statsLine)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)
                geoActionRow
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(DesignTokens.surfacePanel)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text("// ASSET_CONTEXT")
                .porteosMeta()
                .foregroundStyle(accent)
            Spacer(minLength: 8)
            Button {
                wmOpenInRealEstate()
            } label: {
                Text("[ OPEN DEAL ↗ ]")
                    .porteosMeta()
                    .foregroundStyle(accent)
            }
            .buttonStyle(.plain)
            Button(action: onDismiss) {
                Text("[ × ]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .help("Deselect pin")
        }
    }

    private var contextLine: String {
        var parts: [String] = []
        if !deal.locationCity.isEmpty { parts.append(deal.locationCity) }
        if let market = resolvedMarketName { parts.append(market) }
        if !deal.propertyType.isEmpty { parts.append(deal.propertyType) }
        parts.append(deal.status.rawValue.uppercased())
        return parts.joined(separator: " · ")
    }

    private var statsLine: String {
        var parts: [String] = []
        if let score = deal.porteosScore {
            parts.append("Score \(String(format: "%.0f", score)) / 100")
            parts.append("Grade \(grade.rawValue)")
        }
        if deal.purchasePrice > 0 {
            parts.append(GeoPinHoverBanner.formatEUR(deal.purchasePrice))
        }
        if deal.totalArea > 0 {
            parts.append("\(Int(deal.totalArea)) m²")
        }
        parts.append("Geocode \(geocodeStatusLabel)")
        return parts.joined(separator: " · ")
    }

    private var resolvedMarketName: String? {
        if let market = MarketFeedRegistry.market(id: deal.marketId) {
            return market.displayName
        }
        if !deal.locationCity.isEmpty,
           let metro = MarketFeedRegistry.resolveMarketId(city: deal.locationCity),
           let market = MarketFeedRegistry.market(id: metro) {
            return market.displayName
        }
        return nil
    }

    @ViewBuilder
    private var geoActionRow: some View {
        HStack(spacing: 8) {
            if deal.isGeocoded {
                actionButton("[ CLEAR PIN ]", role: .destructive) {
                    GeocodingService.shared.clearPin(deal: deal, context: modelContext)
                }
                actionButton("[ RE-GEOCODE ]") {
                    GeocodingService.shared.scheduleGeocode(deal: deal, context: modelContext)
                }
            } else if deal.geocodeStatus == .failed {
                Text("// GEOCODE_FAILED")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.statusWarn)
                actionButton("[ RE-GEOCODE ]") {
                    GeocodingService.shared.scheduleGeocode(deal: deal, context: modelContext)
                }
            } else if deal.needsGeocode {
                actionButton("[ GEOCODE NOW ]") {
                    GeocodingService.shared.scheduleGeocode(deal: deal, context: modelContext)
                }
            }
        }
    }

    private var geocodeStatusLabel: String {
        switch deal.geocodeStatus {
        case .none:    return "—"
        case .pending: return "pending"
        case .ok:      return "ok"
        case .failed:  return "failed"
        }
    }

    private func wmOpenInRealEstate() {
        WindowManager.shared.activeProfile = .realEstate
    }

    private enum ActionRole { case normal, destructive }

    private func actionButton(
        _ label: String,
        role: ActionRole = .normal,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(role == .destructive ? DesignTokens.statusWarn : accent)
        }
        .buttonStyle(.plain)
    }
}
