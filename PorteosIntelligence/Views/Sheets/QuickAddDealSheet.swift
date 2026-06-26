import SwiftUI
import SwiftData

// MARK: - QuickAddDealSheet

struct QuickAddDealSheet: View {

    var onSave: ((UUID) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: State

    @State private var name:         String    = ""
    @State private var location:     String    = ""
    @State private var propertyType: String    = "Commercial"
    @State private var purchasePrice: String   = ""
    @State private var totalArea:    String    = ""
    @State private var status:       DealStatus = .pipeline
    @State private var notes:        String    = ""

    private let propertyTypes: [String] = [
        "Residential", "Commercial", "Mixed-Use", "Hospitality", "Industrial", "Other"
    ]

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TerminalInputField(label: "Property Name", placeholder: "Asset Name",    prefix: nil, suffix: nil, text: $name)
                    TerminalInputField(label: "Location",      placeholder: "City, Country", prefix: nil, suffix: nil, text: $location)
                    pickerField(label: "Property Type") {
                        Picker("", selection: $propertyType) {
                            ForEach(propertyTypes, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    TerminalInputField(label: "Purchase Price", placeholder: "0", prefix: "€", suffix: nil, text: $purchasePrice)
                    TerminalInputField(label: "Total Area",     placeholder: "0", prefix: nil, suffix: "m²", text: $totalArea)
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
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
            Text("deal --create")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(accentRust)
            Spacer()
            Button { dismiss() } label: {
                Text("✕")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
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
                .font(.custom("Inter", size: 11).weight(.bold))
                .tracking(0.05)
                .foregroundStyle(textTertiary)

            content()
                .font(.custom("JetBrains Mono", size: 14))
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
                .font(.custom("Inter", size: 11).weight(.bold))
                .tracking(0.05)
                .foregroundStyle(textTertiary)

            TextField("Optional notes…", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 14))
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
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textSecondary)
                    .frame(height: 28)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { saveDeal() } label: {
                Text("[ DEPLOY_DEAL ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .foregroundStyle(Color(hex: "#0F1115"))
                    .padding(.horizontal, 16)
                    .frame(height: 28)
                    .background(canSave ? accentRust : Color(hex: "#2E333F"))
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
        let deal = PropertyDeal(
            propertyName:   name.trimmingCharacters(in: .whitespaces),
            propertyType:   propertyType,
            totalArea:      Double(totalArea.filter    { $0.isNumber || $0 == "." }) ?? 0,
            locationCity:   location,
            purchasePrice:  Double(purchasePrice.filter { $0.isNumber || $0 == "." }) ?? 0,
            notes:          notes,
            status:         status
        )
        modelContext.insert(deal)
        onSave?(deal.id)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    QuickAddDealSheet()
        .background(Color(hex: "#0F1115"))
}
