import SwiftUI

// MARK: - AdvancedFilterPanel

/// Collapsible advanced filter panel embedded in NavigationPane's deals section.
/// Range inputs use local string buffers; committed to `filters` on [ APPLY_FILTERS ].
/// Text search, profile toggles, and location update `filters` in real-time.
struct AdvancedFilterPanel: View {

    @Binding var filters: DealFilters

    // Range string buffers — numeric inputs, parsed to Double? on apply
    @State private var minPriceStr:  String = ""
    @State private var maxPriceStr:  String = ""
    @State private var minCapStr:    String = ""
    @State private var maxCapStr:    String = ""
    @State private var minNOIStr:    String = ""
    @State private var maxNOIStr:    String = ""
    @State private var minScoreStr:  String = ""
    @State private var maxScoreStr:  String = ""

    // MARK: Tokens
    private let shellBg      = DesignTokens.canvasBase
    private let shellSurface = DesignTokens.surfacePanel
    private let shellBorder  = DesignTokens.dividerStructural
    private let textPrimary  = DesignTokens.textPrimary
    private let textTertiary = DesignTokens.textDim
    private let accentRust   = DesignTokens.accentRust

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            VStack(alignment: .leading, spacing: 10) {
                searchSection
                sep
                rangeSection
                sep
                profileSection
                sep
                locationSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Rectangle().fill(shellBorder).frame(height: 1)
            actionRow
        }
        .background(shellBg)
        .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
        .clipShape(Rectangle())
        .onAppear { syncFromFilters() }
    }

    // MARK: Panel Header

    private var panelHeader: some View {
        HStack(spacing: 0) {
            Text("// FILTER_PANEL")
                .porteosMeta()
                .foregroundStyle(textTertiary)
                .padding(.leading, 12)
            Spacer()
            if filters.isActive {
                Text("ACTIVE")
                    .porteosMeta()
                    .foregroundStyle(accentRust)
                    .padding(.trailing, 12)
            }
        }
        .frame(height: 26)
    }

    // MARK: Search

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            rowLabel("NAME / ADDRESS")
            terminalField("search…", text: $filters.searchText, isActive: !filters.searchText.isEmpty)
        }
    }

    // MARK: Range Filters

    private var rangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            rowLabel("// METRIC RANGES")
            rangeRow(label: "PURCHASE PRICE (€)", minBind: $minPriceStr, maxBind: $maxPriceStr)
            rangeRow(label: "CAP RATE (%)",       minBind: $minCapStr,   maxBind: $maxCapStr)
            rangeRow(label: "NOI (€)",            minBind: $minNOIStr,   maxBind: $maxNOIStr)
            rangeRow(label: "PORTEOS SCORE",      minBind: $minScoreStr, maxBind: $maxScoreStr)
        }
    }

    private func rangeRow(
        label:   String,
        minBind: Binding<String>,
        maxBind: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(textTertiary)
            HStack(spacing: 4) {
                Text("≥")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
                    .frame(width: 10, alignment: .center)
                compactNumField(placeholder: "0",  text: minBind)

                Text("≤")
                    .porteosMeta()
                    .foregroundStyle(textTertiary)
                    .frame(width: 10, alignment: .center)
                compactNumField(placeholder: "∞",  text: maxBind)
            }
        }
    }

    private func compactNumField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .porteosRowLabel()
            .foregroundStyle(textPrimary)
            .textFieldStyle(.plain)
            .padding(.horizontal, 6)
            .frame(height: 22)
            .frame(maxWidth: .infinity)
            .background(shellSurface)
            .overlay(Rectangle().stroke(
                text.wrappedValue.isEmpty ? shellBorder : accentRust.opacity(0.6),
                lineWidth: 1
            ))
            .clipShape(Rectangle())
    }

    // MARK: Profile Checkboxes

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            rowLabel("// HAS PROFILE DATA")
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 5
            ) {
                profileCheckbox("REAL_ESTATE",  isOn: $filters.hasRealEstate)
                profileCheckbox("HOSPITALITY",  isOn: $filters.hasHospitality)
                profileCheckbox("DESIGN",       isOn: $filters.hasDesign)
                profileCheckbox("CIRCULAR",     isOn: $filters.hasCircular)
            }
        }
    }

    private func profileCheckbox(_ label: String, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack(spacing: 5) {
                Rectangle()
                    .fill(isOn.wrappedValue ? accentRust : Color.clear)
                    .frame(width: 9, height: 9)
                    .overlay(
                        Rectangle().stroke(isOn.wrappedValue ? accentRust : textTertiary, lineWidth: 1)
                    )
                    .clipShape(Rectangle())
                Text(label)
                    .porteosMeta()
                    .foregroundStyle(isOn.wrappedValue ? textPrimary : textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            rowLabel("LOCATION")
            terminalField("city / country…", text: $filters.locationFilter, isActive: !filters.locationFilter.isEmpty)
        }
    }

    // MARK: Action Row

    private var actionRow: some View {
        HStack(spacing: 0) {
            Button { clearAll() } label: {
                Text("[ CLEAR_ALL ]")
                    .porteosRowLabel()
                    .foregroundStyle(textTertiary)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { applyFilters() } label: {
                Text("[ APPLY_FILTERS ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.canvasBase)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(accentRust)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    // MARK: Reusable subviews

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .porteosMeta()
            .foregroundStyle(textTertiary)
    }

    private func terminalField(
        _ placeholder: String,
        text: Binding<String>,
        isActive: Bool
    ) -> some View {
        TextField(placeholder, text: text)
            .porteosRowLabel()
            .foregroundStyle(textPrimary)
            .textFieldStyle(.plain)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(shellSurface)
            .overlay(Rectangle().stroke(
                isActive ? accentRust : shellBorder,
                lineWidth: 1
            ))
            .clipShape(Rectangle())
    }

    private var sep: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    // MARK: Logic

    private func syncFromFilters() {
        minPriceStr  = filters.minPrice.map   { fmt($0) } ?? ""
        maxPriceStr  = filters.maxPrice.map   { fmt($0) } ?? ""
        minCapStr    = filters.minCapRate.map { fmt($0) } ?? ""
        maxCapStr    = filters.maxCapRate.map { fmt($0) } ?? ""
        minNOIStr    = filters.minNOI.map     { fmt($0) } ?? ""
        maxNOIStr    = filters.maxNOI.map     { fmt($0) } ?? ""
        minScoreStr  = filters.minScore.map   { fmt($0) } ?? ""
        maxScoreStr  = filters.maxScore.map   { fmt($0) } ?? ""
    }

    private func fmt(_ n: Double) -> String {
        n.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(n)) : String(n)
    }

    private func numericOnly(_ s: String) -> String {
        s.filter { $0.isNumber || $0 == "." }
    }

    private func applyFilters() {
        filters.minPrice   = Double(numericOnly(minPriceStr))
        filters.maxPrice   = Double(numericOnly(maxPriceStr))
        filters.minCapRate = Double(numericOnly(minCapStr))
        filters.maxCapRate = Double(numericOnly(maxCapStr))
        filters.minNOI     = Double(numericOnly(minNOIStr))
        filters.maxNOI     = Double(numericOnly(maxNOIStr))
        filters.minScore   = Double(numericOnly(minScoreStr))
        filters.maxScore   = Double(numericOnly(maxScoreStr))
    }

    private func clearAll() {
        minPriceStr = ""; maxPriceStr = ""
        minCapStr   = ""; maxCapStr   = ""
        minNOIStr   = ""; maxNOIStr   = ""
        minScoreStr = ""; maxScoreStr = ""
        filters.clear()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var filters = DealFilters()
    return AdvancedFilterPanel(filters: $filters)
        .frame(width: 256)
        .background(DesignTokens.canvasBase)
}
