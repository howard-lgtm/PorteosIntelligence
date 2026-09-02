import SwiftUI
import SwiftData

// MARK: - CompsTabContent

/// COMPS tab content for Global Intelligence.
/// Shows comparable properties for the selected deal in a structured table format.
struct CompsTabContent: View {
    
    let deal: PropertyDeal?
    
    @State private var showManualEntry = false
    @State private var showAISearch = false
    @State private var isSearching = false
    @State private var aiSearchError: String?
    
    private let accent = ProfileType.globalIntelligence.accentColor
    
    var body: some View {
        if let deal = deal {
            dealCompsView(for: deal)
        } else {
            noDealView
        }
    }
    
    // MARK: - No Deal Selected
    
    private var noDealView: some View {
        VStack(spacing: 12) {
            Text("// NO_DEAL_SELECTED")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text("Select a deal from the portfolio to view comparable properties.")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
    }
    
    // MARK: - Deal Comps View
    
    private func dealCompsView(for deal: PropertyDeal) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.blockGutter) {
                header(for: deal)
                
                if deal.comparables.isEmpty {
                    emptyState
                } else {
                    comparisonTable(for: deal)
                }
            }
            .padding(DesignTokens.blockGutter)
        }
        .background(DesignTokens.canvasBase)
        .sheet(isPresented: $showManualEntry) {
            ManualCompEntrySheet(deal: deal)
        }
        .sheet(isPresented: $showAISearch) {
            AICompSearchSheet(deal: deal, isSearching: $isSearching, error: $aiSearchError)
        }
    }
    
    // MARK: - Header
    
    private func header(for deal: PropertyDeal) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("// COMPARABLE_PROPERTIES")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            
            Spacer()
            
            Button {
                showAISearch = true
            } label: {
                HStack(spacing: 6) {
                    Text("[ + AI SEARCH ]")
                        .porteosMeta()
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DesignTokens.surfacePanel)
                .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isSearching)
            
            Button {
                showManualEntry = true
            } label: {
                HStack(spacing: 6) {
                    Text("[ + MANUAL ]")
                        .porteosMeta()
                }
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DesignTokens.surfacePanel)
                .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("// NO_COMPARABLES_ADDED")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            
            Text("Add comparable properties to benchmark this deal against similar properties in the market.")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
            
            HStack(spacing: 12) {
                Button {
                    showAISearch = true
                } label: {
                    Text("[ AI SEARCH ]")
                        .porteosMeta()
                        .foregroundStyle(accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignTokens.surfacePanel)
                        .overlay(Rectangle().strokeBorder(accent, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Button {
                    showManualEntry = true
                } label: {
                    Text("[ MANUAL ENTRY ]")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignTokens.surfacePanel)
                        .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Comparison Table
    
    private func comparisonTable(for deal: PropertyDeal) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                tableHeaderCell("PROPERTY", width: 180)
                tableHeaderCell("LOCATION", width: 140)
                tableHeaderCell("PRICE", width: 100, alignment: .trailing)
                tableHeaderCell("AREA", width: 80, alignment: .trailing)
                tableHeaderCell("€/M²", width: 90, alignment: .trailing)
                tableHeaderCell("DIST", width: 70, alignment: .trailing)
                tableHeaderCell("SRC", width: 60)
                Spacer(minLength: 40) // space for delete button
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DesignTokens.surfacePanel)
            
            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(height: 1)
            
            // Subject property row (the deal being evaluated)
            subjectRow(for: deal)
            
            Rectangle()
                .fill(DesignTokens.dividerStructural)
                .frame(height: 1)
            
            // Comparable rows
            ForEach(deal.comparables) { comp in
                compRow(comp, deal: deal)
                Rectangle()
                    .fill(DesignTokens.dividerStructural)
                    .frame(height: 1)
            }
        }
        .background(DesignTokens.canvasBase)
        .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
    }
    
    private func tableHeaderCell(_ text: String, width: CGFloat, alignment: Alignment = .leading) -> some View {
        Text(text)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
            .frame(width: width, alignment: alignment)
    }
    
    private func subjectRow(for deal: PropertyDeal) -> some View {
        HStack(spacing: 0) {
            Text(deal.propertyName.isEmpty ? "Subject Property" : deal.propertyName)
                .porteosRowValue()
                .foregroundStyle(accent)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(deal.locationCity.isEmpty ? "—" : deal.locationCity)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)
            
            Text(deal.purchasePrice > 0 ? formatPrice(deal.purchasePrice, symbol: deal.currencySymbol) : "—")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .frame(width: 100, alignment: .trailing)
            
            Text(deal.totalArea > 0 ? "\(Int(deal.totalArea))m²" : "—")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 80, alignment: .trailing)
            
            Text(deal.totalArea > 0 && deal.purchasePrice > 0 ? formatPrice(deal.purchasePrice / deal.totalArea, symbol: deal.currencySymbol) : "—")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 90, alignment: .trailing)
            
            Text("—")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 70, alignment: .trailing)
            
            Text("SUBJ")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 60, alignment: .leading)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DesignTokens.surfacePanel.opacity(0.3))
    }
    
    private func compRow(_ comp: Comparable, deal: PropertyDeal) -> some View {
        HStack(spacing: 0) {
            Text(comp.name)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Text(comp.location.isEmpty ? "—" : comp.location)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)
            
            Text(formatPrice(comp.price, symbol: deal.currencySymbol))
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .frame(width: 100, alignment: .trailing)
            
            Text("\(Int(comp.area))m²")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 80, alignment: .trailing)
            
            Text(formatPrice(comp.pricePerArea, symbol: deal.currencySymbol))
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 90, alignment: .trailing)
            
            if let dist = comp.distance {
                Text("\(String(format: "%.1f", dist))km")
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text("—")
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: 70, alignment: .trailing)
            }
            
            Text(comp.source.uppercased())
                .porteosMeta()
                .foregroundStyle(sourceColor(comp.source))
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Button {
                deal.removeComparable(id: comp.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.statusCritical)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Helpers
    
    private func formatPrice(_ value: Double, symbol: String) -> String {
        if value >= 1_000_000 {
            return "\(symbol)\(String(format: "%.1f", value / 1_000_000))M"
        } else if value >= 1_000 {
            return "\(symbol)\(String(format: "%.0f", value / 1_000))k"
        } else {
            return "\(symbol)\(Int(value))"
        }
    }
    
    private func sourceColor(_ source: String) -> Color {
        switch source.lowercased() {
        case "ai": return DesignTokens.statusGo
        case "manual": return DesignTokens.textSecondary
        default: return DesignTokens.textDim
        }
    }
}

// MARK: - Manual Entry Sheet

struct ManualCompEntrySheet: View {
    
    let deal: PropertyDeal
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var priceText = ""
    @State private var areaText = ""
    @State private var distanceText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            TerminalStructuralDivider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    formField(label: "PROPERTY NAME", text: $name, placeholder: "e.g., Rio Art Hotel")
                    formField(label: "LOCATION", text: $location, placeholder: "e.g., Setúbal")
                    formField(label: "PRICE (\(deal.currencySymbol))", text: $priceText, placeholder: "780000")
                    formField(label: "AREA (M²)", text: $areaText, placeholder: "260")
                    formField(label: "DISTANCE (KM)", text: $distanceText, placeholder: "12 (optional)")
                }
                .padding(DesignTokens.blockGutter)
            }
            
            TerminalStructuralDivider()
            actionBar
        }
        .frame(width: 500, height: 400)
        .background(DesignTokens.canvasBase)
    }
    
    private var sheetHeader: some View {
        HStack {
            Text("ADD COMPARABLE — MANUAL ENTRY")
                .porteosModuleCmd()
                .foregroundStyle(DesignTokens.textPrimary)
            Spacer()
        }
        .padding(DesignTokens.blockGutter)
        .background(DesignTokens.surfacePanel)
    }
    
    private func formField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(8)
                .background(DesignTokens.surfacePanel)
                .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
        }
    }
    
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("[ CANCEL ]") { dismiss() }
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                saveComparable()
            } label: {
                Text("[ SAVE ]")
                    .porteosMeta()
                    .foregroundStyle(isValid ? DesignTokens.statusGo : DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
        }
        .padding(DesignTokens.blockGutter)
        .background(DesignTokens.surfacePanel)
    }
    
    private var isValid: Bool {
        !name.isEmpty && !location.isEmpty && Double(priceText) != nil && Double(areaText) != nil
    }
    
    private func saveComparable() {
        guard let price = Double(priceText), let area = Double(areaText) else { return }
        let distance = Double(distanceText)
        
        let comp = Comparable(
            name: name,
            location: location,
            price: price,
            area: area,
            distance: distance,
            source: "Manual"
        )
        
        deal.addComparable(comp)
        dismiss()
    }
}

// MARK: - AI Search Sheet

struct AICompSearchSheet: View {
    
    let deal: PropertyDeal
    @Binding var isSearching: Bool
    @Binding var error: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var results: [Comparable] = []
    
    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            TerminalStructuralDivider()
            
            if isSearching {
                searchingView
            } else if let error = error {
                errorView(error)
            } else if results.isEmpty {
                promptView
            } else {
                resultsView
            }
        }
        .frame(width: 700, height: 500)
        .background(DesignTokens.canvasBase)
    }
    
    private var sheetHeader: some View {
        HStack {
            Text("AI COMPARABLE SEARCH")
                .porteosModuleCmd()
                .foregroundStyle(DesignTokens.textPrimary)
            Spacer()
            Button("[ CLOSE ]") { dismiss() }
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .buttonStyle(.plain)
        }
        .padding(DesignTokens.blockGutter)
        .background(DesignTokens.surfacePanel)
    }
    
    private var promptView: some View {
        VStack(spacing: 20) {
            Text("// AI_SEARCH_PROMPT")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            
            Text("The AI will search for 3-5 comparable properties similar to:")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("\(deal.locationCity), \(deal.propertyType)")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.surfacePanel)
            .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
            
            Button {
                runAISearch()
            } label: {
                Text("[ START SEARCH ]")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.statusGo)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(DesignTokens.surfacePanel)
                    .overlay(Rectangle().strokeBorder(DesignTokens.statusGo, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.blockGutter)
        .frame(maxHeight: .infinity)
    }
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            Text("// SEARCHING_FOR_COMPARABLES")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("// ERROR")
                .porteosMeta()
                .foregroundStyle(DesignTokens.statusCritical)
            Text(message)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            Button("[ TRY AGAIN ]") {
                error = nil
                results = []
            }
            .porteosMeta()
            .foregroundStyle(DesignTokens.textPrimary)
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.blockGutter)
        .frame(maxHeight: .infinity)
    }
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            Text("// \(results.count) COMPARABLE(S) FOUND")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignTokens.blockGutter)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(results) { comp in
                        resultCard(comp)
                    }
                }
                .padding(DesignTokens.blockGutter)
            }
            
            TerminalStructuralDivider()
            
            HStack(spacing: 12) {
                Button("[ CANCEL ]") { dismiss() }
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    for comp in results {
                        deal.addComparable(comp)
                    }
                    dismiss()
                } label: {
                    Text("[ ADD ALL \(results.count) ]")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusGo)
                }
                .buttonStyle(.plain)
            }
            .padding(DesignTokens.blockGutter)
            .background(DesignTokens.surfacePanel)
        }
    }
    
    private func resultCard(_ comp: Comparable) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(comp.name)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                HStack(spacing: 8) {
                    Text(comp.location)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Text("•")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Text("\(Int(comp.area))m²")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    if let dist = comp.distance {
                        Text("•")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                        Text("\(String(format: "%.1f", dist))km")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                    }
                }
            }
            Spacer()
            Text("\(deal.currencySymbol)\(String(format: "%.0f", comp.price / 1000))k")
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .padding(12)
        .background(DesignTokens.surfacePanel)
        .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
    }
    
    private func runAISearch() {
        isSearching = true
        error = nil
        
        Task {
            do {
                let foundComps = try await LLMAnalysisService.shared.findComparables(for: deal)
                await MainActor.run {
                    results = foundComps
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }
}
