import SwiftData
import SwiftUI

// MARK: - GeoGeocodePendingOverlay
// Figma frame 4 — deals with address/city but no map coordinates.

struct GeoGeocodePendingOverlay: View {

    @Environment(\.modelContext) private var modelContext

    let pendingDeals: [PropertyDeal]
    var onGeocodeAll: () -> Void

    private let accent = ProfileType.globalIntelligence.accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DesignTokens.statusWarn)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("// GEOCODE_PENDING")
                        .porteosModuleCmd()
                        .foregroundStyle(accent)
                    Text("\(pendingDeals.count) deal\(pendingDeals.count == 1 ? "" : "s") lack coordinates. Run geocode pass to place on map.")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("./geocode --all")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
                .padding(.leading, 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(pendingDeals.prefix(6), id: \.id) { deal in
                    HStack {
                        Text(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(statusTag(deal))
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.statusWarn)
                    }
                }
                if pendingDeals.count > 6 {
                    Text("+ \(pendingDeals.count - 6) more")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                }
            }

            Button(action: onGeocodeAll) {
                Text("[ GEOCODE NOW ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.rowHeightButton)
                    .background(accent.opacity(0.85))
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(DesignTokens.surfacePanel.opacity(0.97))
        .overlay {
            Rectangle().strokeBorder(DesignTokens.statusWarn.opacity(0.6), lineWidth: 1)
        }
        .clipShape(Rectangle())
    }

    private func statusTag(_ deal: PropertyDeal) -> String {
        switch deal.geocodeStatus {
        case .pending: return "[ pending ]"
        case .failed:  return "[ failed ]"
        default:       return "[ pending ]"
        }
    }
}
