import SwiftUI
import SwiftData

// MARK: - TemplatePickerSheet
//
// Entry point for new deal creation. Presents the full template library in a
// 2-column grid with a category filter bar. Selecting any template (or the
// blank deal option) creates a PropertyDeal, inserts it into the model
// context, and calls onSave(deal.id) before dismissing.

struct TemplatePickerSheet: View {

    var onSave: ((UUID) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // ── State ─────────────────────────────────────────────────────────────────
    @State private var selectedCategory = "all"

    private let categories: [(id: String, label: String, color: Color)] = [
        ("all",         "ALL",         DesignTokens.textSecondary),
        ("realEstate",  "REAL ESTATE", ProfileType.realEstate.accentColor),
        ("hospitality", "HOSPITALITY", ProfileType.hospitality.accentColor),
        ("mixedUse",    "MIXED-USE",   DesignTokens.statusWarn),
        ("design",      "DESIGN",      ProfileType.design.accentColor),
        ("circular",    "CIRCULAR",    ProfileType.circular.accentColor),
    ]

    // ── Filtered data ──────────────────────────────────────────────────────────
    private var filteredTemplates: [DealTemplate] {
        DealTemplates.templates(for: selectedCategory)
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            TerminalStructuralDivider()
            TerminalCategoryTabBar(categories: categories, selectedID: $selectedCategory)
            TerminalStructuralDivider()
            templateGrid
        }
        .frame(width: 720)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
    }

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textDim)
            Text("template_init --mode=new_deal")
                .font(DesignTokens.mono(size: 11, weight: .bold))
                .foregroundStyle(DesignTokens.accentRust)
            Spacer()
            Text("[ \(filteredTemplates.count) TEMPLATES ]")
                .font(DesignTokens.mono(size: 10))
                .foregroundStyle(DesignTokens.textDim)
                .padding(.trailing, 12)
            Button { dismiss() } label: {
                Text("[ × ]")
                    .font(DesignTokens.mono(size: 11, weight: .bold))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: – Template Grid

    private var templateGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                // Always-visible blank deal card
                blankDealCard

                // Template cards
                ForEach(filteredTemplates) { template in
                    templateCard(template)
                }
            }
            .padding(20)
        }
        .frame(maxHeight: 520)
    }

    // MARK: – Blank Deal Card

    private var blankDealCard: some View {
        Button {
            createBlankDeal()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    // Left accent bar
                    Rectangle()
                        .fill(DesignTokens.dividerStructural)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("+ BLANK DEAL")
                                .font(DesignTokens.mono(size: 12, weight: .bold))
                                .foregroundStyle(DesignTokens.textSecondary)
                            Spacer()
                        }
                        Text("Start from scratch with an empty template")
                            .font(DesignTokens.mono(size: 10))
                            .foregroundStyle(DesignTokens.textDim)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        HStack {
                            Text("// NO PRE-FILLED VALUES")
                                .font(DesignTokens.mono(size: 9))
                                .foregroundStyle(DesignTokens.textDim)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(DesignTokens.surfacePanel)
            .overlay(Rectangle().stroke(DesignTokens.dividerStructural, lineWidth: 1))
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: – Template Card

    private func templateCard(_ template: DealTemplate) -> some View {
        Button {
            createFromTemplate(template)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    // Left accent bar
                    Rectangle()
                        .fill(template.accentColor)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 6) {
                        // Name + category badge
                        HStack(alignment: .top, spacing: 6) {
                            Text(template.name.uppercased())
                                .font(DesignTokens.mono(size: 11, weight: .bold))
                                .foregroundStyle(DesignTokens.textPrimary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(template.categoryLabel)
                                .font(DesignTokens.mono(size: 8, weight: .medium))
                                .foregroundStyle(template.accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(template.accentColor.opacity(0.10))
                                .overlay(
                                    Rectangle()
                                        .stroke(template.accentColor.opacity(0.30), lineWidth: 1)
                                )
                                .clipShape(Rectangle())
                        }

                        // Description
                        Text(template.description)
                            .font(DesignTokens.mono(size: 10))
                            .foregroundStyle(DesignTokens.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        // Divider
                        Rectangle()
                            .fill(DesignTokens.dividerStructural.opacity(0.6))
                            .frame(height: 1)

                        // Key metrics row
                        HStack(spacing: 12) {
                            ForEach(template.keyMetrics, id: \.label) { metric in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(metric.label)
                                        .font(DesignTokens.mono(size: 8))
                                        .foregroundStyle(DesignTokens.textDim)
                                    Text(metric.value)
                                        .font(DesignTokens.mono(size: 10, weight: .bold))
                                        .foregroundStyle(template.accentColor)
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(DesignTokens.surfacePanel)
            .overlay(Rectangle().stroke(DesignTokens.dividerStructural, lineWidth: 1))
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: – Deal Creation

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
