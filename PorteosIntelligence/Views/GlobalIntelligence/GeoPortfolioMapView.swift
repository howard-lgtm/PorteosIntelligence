import MapKit
import SwiftData
import SwiftUI

// MARK: - GeoMapPin

struct GeoMapPin: View {
    let isSelected: Bool
    let status: DealStatus
    let accent: Color

    var body: some View {
        Rectangle()
            .fill(isSelected ? accent : status.tokenColor)
            .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
            .overlay {
                Rectangle()
                    .strokeBorder(
                        isSelected ? DesignTokens.textPrimary : status.tokenColor.opacity(0.9),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
    }
}

// MARK: - GeoPinHoverBanner

struct GeoPinHoverBanner: View {

    let deal: PropertyDeal
    let accent: Color

    private var liveScore: Double { PropertyDealViewModel(deal: deal).porteosScore.finalScore }
    private var grade: VibeGrade { VibeGrade.from(score: liveScore) }

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
        HStack(spacing: 4) {
            Text(grade.rawValue)
                .porteosScoreGrade()
                .foregroundStyle(Color(hex: grade.hexColor))
            Text("·")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text(String(format: "%.1f", liveScore))
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
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

    @Environment(\.modelContext) private var modelContext

    let deals: [PropertyDeal]
    let marketFilterId: String?
    @Binding var selectedDealID: UUID?

    @State private var camera: MapCameraPosition = .automatic
    @State private var lastRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.5, longitude: -8.0),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
    )
    @State private var hoveredDealID: UUID?

    private let accent = ProfileType.globalIntelligence.accentColor
    private let dealCenterSpan = 0.75

    private var pendingGeocodeDeals: [PropertyDeal] {
        deals.filter { !$0.isGeocoded && (!$0.locationCity.isEmpty || !$0.address.isEmpty) }
    }

    private var showGeocodeOverlay: Bool {
        // Only overlay the map when it is literally empty — if any pins are already
        // plotted, let the geocode status inspector (right pane) handle communication
        // without blocking an otherwise usable map.
        !pendingGeocodeDeals.isEmpty && mappableDeals.isEmpty && selectedDealID == nil
    }

    private var selectedDeal: PropertyDeal? {
        guard let id = selectedDealID else { return nil }
        return deals.first { $0.id == id }
    }

    private var mappableDeals: [PropertyDeal] {
        deals.filter { deal in
            guard deal.hasPlottableCoordinates else { return false }
            guard matchesMarket(deal) else { return false }
            return true
        }
    }

    // All deals in market (geocoded or not) — matches Figma "N ASSETS IN MARKET"
    private var assetsInMarketCount: Int {
        guard let filter = marketFilterId, !filter.isEmpty else { return deals.count }
        return deals.filter { deal in
            let dm = deal.marketId
            if dm == filter { return true }
            if let parent = MarketFeedRegistry.market(id: dm)?.parentId, parent == filter { return true }
            if MarketFeedRegistry.countryId(for: dm) == filter { return true }
            // Fallback: infer from city if marketId not set
            if dm.isEmpty,
               let inferred = MarketFeedRegistry.resolveMarketId(city: deal.locationCity),
               (inferred == filter || MarketFeedRegistry.countryId(for: inferred) == filter) {
                return true
            }
            return false
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
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
                .onMapCameraChange(frequency: .onEnd) { context in
                    lastRegion = context.region
                }

                if showGeocodeOverlay {
                    Color.black.opacity(0.45)
                    GeoGeocodePendingOverlay(pendingDeals: pendingGeocodeDeals) {
                        GeocodingService.shared.scheduleGeocodeAllPending(
                            deals: pendingGeocodeDeals,
                            context: modelContext
                        )
                    }
                }

                if let _ = marketFilterId {
                    assetsInMarketChip
                        .padding(8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            mapChromeBar
        }
        .onAppear { fitCamera() }
        .onChange(of: marketFilterId) { _, _ in fitCamera() }
        .onChange(of: selectedDeal?.geocodeStatusRaw) { _, status in
            guard status == GeocodeStatus.ok.rawValue,
                  let deal = selectedDeal,
                  let lat = deal.latitude, let lon = deal.longitude else { return }
            centerOnCoordinate(latitude: lat, longitude: lon)
        }
    }

    private var assetsInMarketChip: some View {
        HStack(spacing: 5) {
            Rectangle()
                .fill(accent)
                .frame(width: 8, height: 8)
            Text("\(assetsInMarketCount) ASSETS IN MARKET")
                .porteosMeta()
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(accent)
    }

    private var mapChromeBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                pinLegend
            }
            HStack(spacing: 4) {
                Spacer(minLength: 0)
                if let deal = selectedDeal, deal.hasPlottableCoordinates,
                   let lat = deal.latitude, let lon = deal.longitude {
                    mapControlButton("[ CENTER DEAL ]", accent: accent) {
                        centerOnCoordinate(latitude: lat, longitude: lon)
                    }
                }
                mapControlButton("[ + ]") { zoom(by: 0.72) }
                mapControlButton("[ - ]") { zoom(by: 1.38) }
                mapControlButton("[ FIT ALL ]") { fitCamera() }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.surfacePanel)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(height: DesignTokens.dividerWidth)
        }
    }

    private var pinLegend: some View {
        HStack(spacing: 8) {
            Text("// PIN_STATUS")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .fixedSize()
            legendItem("PIPELINE", DealStatus.pipeline.tokenColor)
            legendItem("REVIEW", DealStatus.review.tokenColor)
            legendItem("VIABLE", DealStatus.viable.tokenColor)
            legendItem("ACQUIRED", DealStatus.acquired.tokenColor)
        }
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
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
                if deal.hasPlottableCoordinates,
                   let lat = deal.latitude, let lon = deal.longitude {
                    centerOnCoordinate(latitude: lat, longitude: lon)
                }
            } label: {
                GeoMapPin(isSelected: isSelected, status: deal.status, accent: accent)
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

    private func mapControlButton(
        _ label: String,
        accent: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(accent ?? DesignTokens.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignTokens.surfacePanel.opacity(0.92))
                .overlay { Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private func centerOnCoordinate(latitude: Double, longitude: Double) {
        lastRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: dealCenterSpan, longitudeDelta: dealCenterSpan)
        )
        camera = .region(lastRegion)
    }

    private func zoom(by factor: Double) {
        var region = lastRegion
        region.span.latitudeDelta  = min(120, max(0.05, region.span.latitudeDelta * factor))
        region.span.longitudeDelta = min(120, max(0.05, region.span.longitudeDelta * factor))
        lastRegion = region
        camera = .region(region)
    }

    private func matchesMarket(_ deal: PropertyDeal) -> Bool {
        guard let filter = marketFilterId, !filter.isEmpty else { return true }
        let dealMarket = effectiveMarketId(for: deal)
        guard !dealMarket.isEmpty else {
            return inferCountryFromCity(deal.locationCity) == filter
        }
        if dealMarket == filter { return true }
        if let parent = MarketFeedRegistry.market(id: dealMarket)?.parentId, parent == filter { return true }
        if MarketFeedRegistry.countryId(for: dealMarket) == filter { return true }
        return false
    }

    private func effectiveMarketId(for deal: PropertyDeal) -> String {
        if !deal.marketId.isEmpty { return deal.marketId }
        return MarketFeedRegistry.resolveMarketId(city: deal.locationCity) ?? ""
    }

    private func inferCountryFromCity(_ city: String) -> String? {
        guard let metro = MarketFeedRegistry.resolveMarketId(city: city) else { return nil }
        return MarketFeedRegistry.countryId(for: metro)
    }

    private func fitCamera() {
        if let marketId = marketFilterId, let market = MarketFeedRegistry.market(id: marketId) {
            fitToMarket(market)
            return
        }
        let coords = mappableDeals.compactMap { deal -> CLLocationCoordinate2D? in
            guard let lat = deal.latitude, let lon = deal.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !coords.isEmpty else {
            applyRegion(center: .init(latitude: 39.5, longitude: -8.0), spanDelta: 6.0)
            return
        }
        if coords.count == 1, let c = coords.first {
            centerOnCoordinate(latitude: c.latitude, longitude: c.longitude)
            return
        }
        var rect = MKMapRect.null
        for c in coords {
            let point = MKMapPoint(c)
            let r = MKMapRect(x: point.x, y: point.y, width: 1, height: 1)
            rect = rect.isNull ? r : rect.union(r)
        }
        let inset = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
        lastRegion = MKCoordinateRegion(inset)
        camera = .region(lastRegion)
    }

    /// Country/market chip active — frame the full market (e.g. all of Portugal for PT).
    private func fitToMarket(_ market: MarketDefinition) {
        let span = market.parentId == nil ? max(market.mapSpanDelta, 5.5) : market.mapSpanDelta
        applyRegion(center: market.mapCenter, spanDelta: span)
    }

    private func applyRegion(center: CLLocationCoordinate2D, spanDelta: Double) {
        lastRegion = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
        )
        camera = .region(lastRegion)
    }

    private func zoomToMarket(_ market: MarketDefinition) {
        fitToMarket(market)
    }
}
