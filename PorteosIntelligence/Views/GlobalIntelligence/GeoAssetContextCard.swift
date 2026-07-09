import SwiftData
import SwiftUI

// MARK: - GeoAssetContextCard

struct GeoAssetContextCard: View {

    @Environment(\.modelContext) private var modelContext

    let deal: PropertyDeal
    var onDismiss: () -> Void

    private let accent = ProfileType.globalIntelligence.accentColor

    var body: some View {
        TerminalBlock(command: "asset --context", accentColor: accent) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                        .porteosRowValue()
                        .foregroundStyle(DesignTokens.textPrimary)
                    Spacer()
                    Button(action: onDismiss) {
                        Text("[ × ]")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                    }
                    .buttonStyle(.plain)
                    .help("Deselect pin")
                }

                if !deal.locationCity.isEmpty {
                    metaRow("CITY", deal.locationCity)
                }
                if !deal.address.isEmpty {
                    metaRow("ADDRESS", deal.address)
                }
                if !deal.marketId.isEmpty, let market = MarketFeedRegistry.market(id: deal.marketId) {
                    metaRow("MARKET", market.displayName)
                }
                if let score = deal.porteosScore {
                    metaRow("SCORE", String(format: "%.1f", score))
                }

                metaRow("GEOCODE", geocodeStatusLabel)

                if let coords = coordinateLabel {
                    metaRow("COORDS", coords)
                }

                geoActionRow
            }
            .padding(.vertical, 8)
        }
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
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.statusWarn)
                actionButton("[ RE-GEOCODE ]") {
                    GeocodingService.shared.scheduleGeocode(deal: deal, context: modelContext)
                }
                if deal.latitude != nil {
                    actionButton("[ CLEAR PIN ]", role: .destructive) {
                        GeocodingService.shared.clearPin(deal: deal, context: modelContext)
                    }
                }
            } else if deal.needsGeocode {
                Text("// GEOCODE_PENDING")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.statusWarn)
                actionButton("[ GEOCODE NOW ]") {
                    GeocodingService.shared.scheduleGeocode(deal: deal, context: modelContext)
                }
            } else {
                Text("// NO_COORDINATES — add city or address in deal edit")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textDim)
            }
        }
    }

    private var geocodeStatusLabel: String {
        switch deal.geocodeStatus {
        case .none:    return "NONE"
        case .pending: return "PENDING"
        case .ok:      return "OK"
        case .failed:  return "FAILED"
        }
    }

    private var coordinateLabel: String? {
        guard let lat = deal.latitude, let lon = deal.longitude else { return nil }
        return String(format: "%.5f, %.5f", lat, lon)
    }

    private func metaRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 64, alignment: .leading)
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
