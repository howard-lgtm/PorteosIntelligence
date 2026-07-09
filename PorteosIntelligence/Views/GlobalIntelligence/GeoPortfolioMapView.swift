import MapKit
import SwiftUI

// MARK: - GeoMapPin

struct GeoMapPin: View {
    let isSelected: Bool
    let accent: Color

    var body: some View {
        Rectangle()
            .fill(isSelected ? accent : DesignTokens.canvasBase)
            .frame(width: 12, height: 12)
            .overlay {
                Rectangle()
                    .strokeBorder(isSelected ? DesignTokens.textPrimary : accent, lineWidth: isSelected ? 2 : 1)
            }
    }
}

// MARK: - GeoPinHoverBanner

struct GeoPinHoverBanner: View {

    let deal: PropertyDeal
    let accent: Color

    private var grade: VibeGrade { VibeGrade.from(score: deal.porteosScore) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(locationLine)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineLimit(1)

                Text(deal.status.rawValue.uppercased())
                    .porteosMeta()
                    .foregroundStyle(deal.status.tokenColor)

                HStack(spacing: 10) {
                    Text(formatPrice(deal.purchasePrice))
                        .porteosMeta()
                        .foregroundStyle(accent)
                    scoreLine
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: 220)
        .background(DesignTokens.surfacePanel.opacity(0.96))
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var scoreLine: some View {
        if let score = deal.porteosScore {
            HStack(spacing: 4) {
                Text(grade.rawValue)
                    .porteosScoreGrade()
                    .foregroundStyle(Color(hex: grade.hexColor))
                Text("·")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Text(String(format: "%.1f", score))
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        } else {
            Text("SCORE —")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
    }

    private var locationLine: String {
        if !deal.locationCity.isEmpty { return deal.locationCity }
        if !deal.marketId.isEmpty, let market = MarketFeedRegistry.market(id: deal.marketId) {
            return market.displayName
        }
        return "—"
    }

    private func formatPrice(_ value: Double) -> String {
        Self.formatEUR(value, prefix: "PRICE ")
    }

    static func formatEUR(_ value: Double, prefix: String = "") -> String {
        guard value > 0 else { return "\(prefix)—" }
        if value >= 1_000_000 {
            return "\(prefix)\(String(format: "€%.2fM", value / 1_000_000))"
        }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "EUR"
        f.maximumFractionDigits = 0
        let amount = f.string(from: NSNumber(value: value)) ?? "€\(Int(value))"
        return "\(prefix)\(amount)"
    }
}

// MARK: - GeoPortfolioMapView

struct GeoPortfolioMapView: View {

    let deals: [PropertyDeal]
    let marketFilterId: String?
    @Binding var selectedDealID: UUID?

    @State private var camera: MapCameraPosition = .automatic
    @State private var hoveredDealID: UUID?

    private let accent = ProfileType.globalIntelligence.accentColor

    private var mappableDeals: [PropertyDeal] {
        deals.filter { deal in
            guard deal.isGeocoded, let lat = deal.latitude, let lon = deal.longitude else { return false }
            guard lat != 0 || lon != 0 else { return false }
            guard matchesMarket(deal) else { return false }
            return true
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $camera, interactionModes: [.pan, .zoom]) {
                ForEach(mappableDeals, id: \.id) { deal in
                    if let lat = deal.latitude, let lon = deal.longitude {
                        Annotation("", coordinate: .init(latitude: lat, longitude: lon), anchor: .bottom) {
                            pinAnnotation(for: deal)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .colorScheme(.dark)
            .mapControlVisibility(.hidden)

            mapControls
                .padding(12)
        }
        .onAppear { fitCamera() }
        .onChange(of: marketFilterId) { _, _ in fitCamera() }
        .onChange(of: mappableDeals.count) { _, _ in fitCamera() }
    }

    private func pinAnnotation(for deal: PropertyDeal) -> some View {
        let isSelected = selectedDealID == deal.id
        let isHovered  = hoveredDealID == deal.id

        return VStack(spacing: 6) {
            if isHovered {
                GeoPinHoverBanner(deal: deal, accent: accent)
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
            }

            Button {
                selectedDealID = deal.id
            } label: {
                GeoMapPin(isSelected: isSelected, accent: accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(deal.propertyName.isEmpty ? "Property pin" : "\(deal.propertyName) map pin")
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .zIndex(isHovered ? 1 : 0)
        .onHover { isHovering in
            hoveredDealID = isHovering
                ? deal.id
                : (hoveredDealID == deal.id ? nil : hoveredDealID)
        }
    }

    private var mapControls: some View {
        VStack(spacing: 4) {
            mapControlButton("[ FIT ]") { fitCamera() }
            if let marketId = marketFilterId, let market = MarketFeedRegistry.market(id: marketId) {
                mapControlButton("[ \(market.id) ]") { zoomToMarket(market) }
            }
        }
    }

    private func mapControlButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignTokens.surfacePanel.opacity(0.92))
                .overlay { Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private func matchesMarket(_ deal: PropertyDeal) -> Bool {
        guard let filter = marketFilterId, !filter.isEmpty else { return true }
        if deal.marketId == filter { return true }
        if let country = MarketFeedRegistry.countryId(for: filter), deal.marketId == country { return true }
        if let parent = MarketFeedRegistry.market(id: deal.marketId)?.parentId, parent == filter { return true }
        return false
    }

    private func fitCamera() {
        if let marketId = marketFilterId, let market = MarketFeedRegistry.market(id: marketId) {
            zoomToMarket(market)
            return
        }
        let coords = mappableDeals.compactMap { deal -> CLLocationCoordinate2D? in
            guard let lat = deal.latitude, let lon = deal.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !coords.isEmpty else {
            camera = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.5, longitude: -8.0),
                span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
            ))
            return
        }
        if coords.count == 1, let c = coords.first {
            camera = .region(MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)))
            return
        }
        var rect = MKMapRect.null
        for c in coords {
            let point = MKMapPoint(c)
            let r = MKMapRect(x: point.x, y: point.y, width: 1, height: 1)
            rect = rect.isNull ? r : rect.union(r)
        }
        camera = .rect(rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25))
    }

    private func zoomToMarket(_ market: MarketDefinition) {
        camera = .region(MKCoordinateRegion(
            center: market.mapCenter,
            span: MKCoordinateSpan(latitudeDelta: market.mapSpanDelta, longitudeDelta: market.mapSpanDelta)
        ))
    }
}
