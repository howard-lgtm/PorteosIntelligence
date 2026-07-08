import SwiftUI
import SwiftData

// MARK: - QuickAddDealSheet
// Handles both create (deal == nil) and edit (deal != nil) modes.

struct QuickAddDealSheet: View {

    private let editingDeal: PropertyDeal?
    var onSave: ((UUID) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: Tokens

    private let shellBg       = DesignTokens.canvasBase
    private let shellSurface  = DesignTokens.surfacePanel
    private let shellBorder   = DesignTokens.dividerStructural
    private let accentRust    = DesignTokens.accentRust
    private let textPrimary   = DesignTokens.textPrimary
    private let textSecondary = DesignTokens.textSecondary
    private let textTertiary  = DesignTokens.textDim

    // MARK: State — initialised from deal if editing

    @State private var name:          String
    @State private var location:      String
    @State private var propertyType:  String
    @State private var purchasePrice: String
    @State private var totalArea:     String
    @State private var status:        DealStatus
    @State private var notes:         String

    private let propertyTypes: [String] = DealPropertyTypes.defaults

    private var isEditing: Bool { editingDeal != nil }
    private var canSave:   Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: Init

    init(deal: PropertyDeal? = nil, onSave: ((UUID) -> Void)? = nil) {
        self.editingDeal = deal
        self.onSave      = onSave
        _name          = State(initialValue: deal?.propertyName ?? "")
        _location      = State(initialValue: deal?.locationCity ?? "")
        _propertyType  = State(initialValue: deal?.propertyType.isEmpty == false ? deal!.propertyType : "Commercial")
        _purchasePrice = State(initialValue: deal.map { $0.purchasePrice > 0 ? "\(Int($0.purchasePrice))" : "" } ?? "")
        _totalArea     = State(initialValue: deal.map { $0.totalArea     > 0 ? "\(Int($0.totalArea))"     : "" } ?? "")
        _status        = State(initialValue: deal?.status ?? .pipeline)
        _notes         = State(initialValue: deal?.notes ?? "")
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TerminalInputField(label: "Property Name",  placeholder: "Asset Name",    prefix: nil, suffix: nil,  text: $name)
                    TerminalInputField(label: "Location",       placeholder: "City, Country", prefix: nil, suffix: nil,  text: $location)
                    pickerField(label: "Property Type") {
                        Picker("", selection: $propertyType) {
                            ForEach(propertyTypes, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    TerminalInputField(label: "Purchase Price", placeholder: "0",             prefix: "€", suffix: nil,  text: $purchasePrice)
                    TerminalInputField(label: "Total Area",     placeholder: "0",             prefix: nil, suffix: "m²", text: $totalArea)
                    pickerField(label: "Status") {
                        Picker("", selection: $status) {
                            ForEach(DealStatus.allCases, id: \.self) {
                                Text($0.rawValue.capitalized).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    notesField
                }
                .padding(16)
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            footer
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 480)
    }

    // MARK: Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosRowLabel()
                .foregroundStyle(textTertiary)
            Text(isEditing
                 ? "deal --edit --asset=\"\(editingDeal?.propertyName.isEmpty == false ? editingDeal!.propertyName : "Untitled")\""
                 : "deal --create")
                .porteosButtonPrimary()
                .foregroundStyle(accentRust)
                .lineLimit(1)
            Spacer()
            Button { dismiss() } label: {
                Text("✕")
                    .porteosScoreGrade()
                    .foregroundStyle(textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(shellSurface)
    }

    // MARK: Picker Field

    private func pickerField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .porteosMeta()
                .foregroundStyle(textTertiary)

            content()
                .porteosScoreGrade()
                .foregroundStyle(textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 28)
                .padding(.horizontal, 8)
                .background(shellBg)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: 1))
                .clipShape(Rectangle())
        }
    }

    // MARK: Notes Field

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .porteosMeta()
                .foregroundStyle(textTertiary)

            TextField("Optional notes…", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .porteosScoreGrade()
                .foregroundStyle(textPrimary)
                .lineLimit(3...6)
                .padding(8)
                .background(shellBg)
                .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: 1))
                .clipShape(Rectangle())
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .porteosRowLabel()
                    .foregroundStyle(textSecondary)
                    .frame(height: 28)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { saveDeal() } label: {
                Text(isEditing ? "[ UPDATE_DEAL ]" : "[ DEPLOY_DEAL ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.canvasBase)
                    .padding(.horizontal, 16)
                    .frame(height: 28)
                    .background(canSave ? accentRust : shellBorder)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(shellSurface)
    }

    // MARK: Save

    private func saveDeal() {
        guard canSave else { return }
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let price     = Double(purchasePrice.filter { $0.isNumber || $0 == "." }) ?? 0
        let area      = Double(totalArea.filter     { $0.isNumber || $0 == "." }) ?? 0

        if let deal = editingDeal {
            deal.propertyName  = cleanName
            deal.locationCity  = location
            deal.propertyType  = propertyType
            deal.purchasePrice = price
            deal.totalArea     = area
            deal.status        = status
            deal.notes         = notes
            deal.updatedAt     = Date()
            deal.porteosScore  = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        } else {
            let deal = PropertyDeal(
                propertyName:  cleanName,
                propertyType:  propertyType,
                totalArea:     area,
                locationCity:  location,
                purchasePrice: price,
                notes:         notes,
                status:        status
            )
            deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
            modelContext.insert(deal)
            onSave?(deal.id)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("Create") {
    QuickAddDealSheet()
        .background(DesignTokens.canvasBase)
}

#Preview("Edit") {
    let deal = PropertyDeal(
        propertyName: "Lisbon Office Block A",
        propertyType: "Commercial",
        locationCity: "Lisbon",
        purchasePrice: 1_250_000,
        status: .viable
    )
    return QuickAddDealSheet(deal: deal)
        .background(DesignTokens.canvasBase)
}
