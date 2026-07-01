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

    // ── Design tokens ─────────────────────────────────────────────────────────
    private let shellBg      = Color(hex: "#0F1115")
    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textPrimary  = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentRust   = Color(hex: "#C25E30")

    // ── Category tabs ─────────────────────────────────────────────────────────
    private let categories: [(id: String, label: String, color: Color)] = [
        ("all",         "ALL",         Color(hex: "#94A3B8")),
        ("realEstate",  "REAL ESTATE", Color(hex: "#C25E30")),
        ("hospitality", "HOSPITALITY", Color(hex: "#14B8A6")),
        ("mixedUse",    "MIXED-USE",   Color(hex: "#F59E0B")),
        ("design",      "DESIGN",      Color(hex: "#A855F7")),
        ("circular",    "CIRCULAR",    Color(hex: "#3B82F6")),
    ]

    // ── Filtered data ──────────────────────────────────────────────────────────
    private var filteredTemplates: [DealTemplate] {
        DealTemplates.templates(for: selectedCategory)
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)
            categoryFilter
            Rectangle().fill(shellBorder).frame(height: 1)
            templateGrid
        }
        .frame(width: 720)
        .background(shellBg)
        .clipShape(Rectangle())
    }

    // MARK: – Sheet Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 12))
                .foregroundStyle(textTertiary)
            Text("template_init --mode=new_deal")
                .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                .foregroundStyle(accentRust)

            Spacer()

            Text("[ \(filteredTemplates.count) TEMPLATES ]")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(textTertiary)
                .padding(.trailing, 12)

            Button { dismiss() } label: {
                Text("[ × ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
        .background(shellSurface)
    }

    // MARK: – Category Filter Bar

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(categories, id: \.id) { cat in
                    categoryTab(id: cat.id, label: cat.label, color: cat.color)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 38)
        .background(shellSurface)
    }

    private func categoryTab(id: String, label: String, color: Color) -> some View {
        let isActive = selectedCategory == id
        return Button {
            selectedCategory = id
        } label: {
            VStack(spacing: 0) {
                Spacer()
                Text(label)
                    .font(.custom("JetBrains Mono", size: 11).weight(isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? color : textTertiary)
                    .padding(.horizontal, 10)
                Spacer()
                Rectangle()
                    .fill(isActive ? color : Color.clear)
                    .frame(height: 2)
            }
            .frame(height: 38)
        }
        .buttonStyle(.plain)
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
                        .fill(shellBorder)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("+ BLANK DEAL")
                                .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                                .foregroundStyle(textSecondary)
                            Spacer()
                        }
                        Text("Start from scratch with an empty template")
                            .font(.custom("JetBrains Mono", size: 10))
                            .foregroundStyle(textTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        HStack {
                            Text("// NO PRE-FILLED VALUES")
                                .font(.custom("JetBrains Mono", size: 9))
                                .foregroundStyle(textTertiary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(shellSurface)
            .overlay(
                Rectangle()
                    .stroke(shellBorder, lineWidth: 1)
            )
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
                                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                                .foregroundStyle(textPrimary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(template.categoryLabel)
                                .font(.custom("JetBrains Mono", size: 8).weight(.medium))
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
                            .font(.custom("JetBrains Mono", size: 9.5))
                            .foregroundStyle(textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        // Divider
                        Rectangle()
                            .fill(shellBorder.opacity(0.6))
                            .frame(height: 1)

                        // Key metrics row
                        HStack(spacing: 12) {
                            ForEach(template.keyMetrics, id: \.label) { metric in
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(metric.label)
                                        .font(.custom("JetBrains Mono", size: 7.5))
                                        .foregroundStyle(textTertiary)
                                    Text(metric.value)
                                        .font(.custom("JetBrains Mono", size: 10).weight(.bold))
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
            .background(shellSurface)
            .overlay(
                Rectangle()
                    .stroke(shellBorder, lineWidth: 1)
            )
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
        .background(Color(hex: "#0F1115"))
}
