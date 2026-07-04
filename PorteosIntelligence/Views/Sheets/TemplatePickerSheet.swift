import SwiftUI
import SwiftData

// MARK: - TemplatePickerSheet
// Figma img_00_10 — select template, then confirm via footer.

struct TemplatePickerSheet: View {

    private static let blankID = "__blank__"
    private static let templateCount = 12

    var onSave: ((UUID) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var selectedCategory = "all"
    @State private var selectedID: String?

    private let categories: [(id: String, label: String, color: Color)] = [
        ("all",         "ALL",         DesignTokens.textPrimary),
        ("realEstate",  "RE",          ProfileType.realEstate.accentColor),
        ("hospitality", "HOSPITALITY", ProfileType.hospitality.accentColor),
        ("design",      "DESIGN",      ProfileType.design.accentColor),
        ("circular",    "CIRCULAR",    ProfileType.circular.accentColor),
        ("mixedUse",    "MIXED",       DesignTokens.statusWarn),
    ]

    private var filteredTemplates: [DealTemplate] {
        DealTemplates.templates(for: selectedCategory)
    }

    private var canConfirm: Bool { selectedID != nil }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            TerminalStructuralDivider()
            TerminalCategoryTabBar(categories: categories, selectedID: $selectedCategory)
            TerminalStructuralDivider()
            templateGrid
            TerminalStructuralDivider()
            footerBar
        }
        .frame(width: 640)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
        .onAppear { syncDefaultSelection() }
        .onChange(of: selectedCategory) { _, _ in syncDefaultSelection() }
    }

    // MARK: Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(DesignTokens.textDim)
            Text("template --picker")
                .porteosModuleCmd()
                .foregroundStyle(DesignTokens.accentRust)
            Spacer()
            Text("[ \(Self.templateCount) TEMPLATES ]")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .padding(.trailing, 12)
            Button { dismiss() } label: {
                Text("[ × ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Grid

    private var templateGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(filteredTemplates) { template in
                    templateCard(template)
                }
                blankDealCard
            }
            .padding(DesignTokens.blockGutter)
        }
        .frame(maxHeight: 480)
    }

    // MARK: Cards

    private func templateCard(_ template: DealTemplate) -> some View {
        let isSelected = selectedID == template.id

        return Button { selectedID = template.id } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(template.accentColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(template.name.uppercased())
                            .porteosButtonPrimary()
                            .foregroundStyle(DesignTokens.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if isSelected {
                            Text("SELECTED")
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.accentRust)
                        }
                    }

                    Text(template.description)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 4)

                    Text(template.shortCategoryLabel)
                        .porteosMeta()
                        .foregroundStyle(template.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(DesignTokens.surfacePanel)
            .overlay {
                Rectangle().stroke(
                    isSelected ? DesignTokens.accentRust : DesignTokens.dividerStructural,
                    lineWidth: DesignTokens.dividerWidth
                )
            }
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var blankDealCard: some View {
        let isSelected = selectedID == Self.blankID

        return Button { selectedID = Self.blankID } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DesignTokens.dividerStructural)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("+ NEW BLANK DEAL")
                            .porteosButtonPrimary()
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if isSelected {
                            Text("SELECTED")
                                .porteosMeta()
                                .foregroundStyle(DesignTokens.accentRust)
                        }
                    }

                    Text("Start from scratch")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(DesignTokens.surfacePanel)
            .overlay {
                Rectangle().stroke(
                    isSelected ? DesignTokens.accentRust : DesignTokens.dividerStructural,
                    lineWidth: DesignTokens.dividerWidth
                )
            }
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: Footer

    private var footerBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { confirmSelection() } label: {
                Text("[ USE TEMPLATE ]")
            }
            .buttonStyle(TerminalButtonStyle(color: canConfirm ? .rust : .muted))
            .disabled(!canConfirm)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Actions

    private func syncDefaultSelection() {
        if let id = selectedID,
           id == Self.blankID || filteredTemplates.contains(where: { $0.id == id }) {
            return
        }
        selectedID = filteredTemplates.first?.id
    }

    private func confirmSelection() {
        guard let id = selectedID else { return }
        if id == Self.blankID {
            createBlankDeal()
        } else if let template = DealTemplates.template(id: id) {
            createFromTemplate(template)
        }
    }

    private func createBlankDeal() {
        let deal = PropertyDeal()
        deal.propertyName = ""
        modelContext.insert(deal)
        try? modelContext.save()
        onSave?(deal.id)
        dismiss()
    }

    private func createFromTemplate(_ template: DealTemplate) {
        let deal = template.makePropertyDeal()
        modelContext.insert(deal)
        try? modelContext.save()
        onSave?(deal.id)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)

    return TemplatePickerSheet()
        .modelContainer(container)
        .background(DesignTokens.canvasBase)
}
