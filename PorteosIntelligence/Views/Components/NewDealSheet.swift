import SwiftUI
import SwiftData

// MARK: - NewDealSheet

struct NewDealSheet: View {

    var onSave: ((UUID) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentGold    = Color(hex: "#D4AF37")

    // MARK: Base Data State

    @State private var propertyName: String = ""
    @State private var purchasePrice: String = ""

    // MARK: Income & Expenses State

    @State private var grossPotentialIncome: String = ""
    @State private var vacancyRate: String = ""
    @State private var operatingExpenses: String = ""

    // MARK: Leverage State

    @State private var loanAmount: String = ""
    @State private var interestRate: String = ""
    @State private var amortizationMonths: String = "360"

    // MARK: Hospitality State

    @State private var hospitalityRoomCount: String = "50"
    @State private var hospitalityADR: String = ""
    @State private var hospitalityOccupancyRate: String = ""
    @State private var hospitalityFBRevenue: String = ""
    @State private var hospitalitySpaRevenue: String = ""

    // MARK: Circular Economy State

    @State private var circularTotalConstructionCost: String = "0"
    @State private var circularRepurposedMaterialCost: String = "0"
    @State private var circularCO2Embodied: String = "0"
    @State private var circularKgMaterialsUsed: String = "0"
    @State private var circularKgMaterialsReturned: String = "0"
    @State private var circularKgMaterialsDisposed: String = "0"

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    inputGroup(title: "BASE DATA") {
                        TerminalInputField(
                            label: "Property Name",
                            placeholder: "e.g. Lisbon Office Block A",
                            prefix: nil,
                            suffix: nil,
                            text: $propertyName
                        )
                        TerminalInputField(
                            label: "Purchase Price",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $purchasePrice
                        )
                    }

                    groupDivider

                    inputGroup(title: "INCOME & EXPENSES") {
                        TerminalInputField(
                            label: "Gross Potential Income",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $grossPotentialIncome
                        )
                        TerminalInputField(
                            label: "Vacancy Rate",
                            placeholder: "0.0",
                            prefix: nil,
                            suffix: "%",
                            text: $vacancyRate
                        )
                        TerminalInputField(
                            label: "Operating Expenses",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $operatingExpenses
                        )
                    }

                    groupDivider

                    inputGroup(title: "LEVERAGE") {
                        TerminalInputField(
                            label: "Loan Amount",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $loanAmount
                        )
                        TerminalInputField(
                            label: "Interest Rate",
                            placeholder: "0.0",
                            prefix: nil,
                            suffix: "%",
                            text: $interestRate
                        )
                        TerminalInputField(
                            label: "Amortization Months",
                            placeholder: "360",
                            prefix: nil,
                            suffix: nil,
                            text: $amortizationMonths
                        )
                    }

                    groupDivider

                    inputGroup(title: "HOSPITALITY DATA") {
                        TerminalInputField(
                            label: "Room Count",
                            placeholder: "50",
                            prefix: nil,
                            suffix: nil,
                            text: $hospitalityRoomCount
                        )
                        TerminalInputField(
                            label: "ADR",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $hospitalityADR
                        )
                        TerminalInputField(
                            label: "Occupancy Rate",
                            placeholder: "0.0",
                            prefix: nil,
                            suffix: "%",
                            text: $hospitalityOccupancyRate
                        )
                        TerminalInputField(
                            label: "F&B Revenue",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $hospitalityFBRevenue
                        )
                        TerminalInputField(
                            label: "Spa Revenue",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $hospitalitySpaRevenue
                        )
                    }

                    groupDivider

                    inputGroup(title: "CIRCULAR ECONOMY (MVP)") {
                        TerminalInputField(
                            label: "Total Construction Cost",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $circularTotalConstructionCost
                        )
                        TerminalInputField(
                            label: "Repurposed Material Cost",
                            placeholder: "0.00",
                            prefix: "€",
                            suffix: nil,
                            text: $circularRepurposedMaterialCost
                        )
                        TerminalInputField(
                            label: "CO2 Embodied",
                            placeholder: "0",
                            prefix: nil,
                            suffix: "kg",
                            text: $circularCO2Embodied
                        )
                        TerminalInputField(
                            label: "Kg Materials Used",
                            placeholder: "0",
                            prefix: nil,
                            suffix: "kg",
                            text: $circularKgMaterialsUsed
                        )
                        TerminalInputField(
                            label: "Kg Materials Returned",
                            placeholder: "0",
                            prefix: nil,
                            suffix: "kg",
                            text: $circularKgMaterialsReturned
                        )
                        TerminalInputField(
                            label: "Kg Materials Disposed",
                            placeholder: "0",
                            prefix: nil,
                            suffix: "kg",
                            text: $circularKgMaterialsDisposed
                        )
                    }
                }
                .padding(16)
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            footer
        }
        .background(shellBg)
        .cornerRadius(0)
        .frame(width: 480)
    }

    // MARK: Sheet Header

    private var sheetHeader: some View {
        HStack {
            Text("NEW DEAL")
                .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(textPrimary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("✕")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .foregroundStyle(textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(shellSurface)
    }

    // MARK: Input Group

    private func inputGroup(title: String, @ViewBuilder fields: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .textCase(.uppercase)
                .padding(.bottom, 4)

            fields()
        }
        .padding(.vertical, 16)
    }

    // MARK: Group Divider

    private var groupDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(height: 1)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            // Cancel
            Button {
                dismiss()
            } label: {
                Text("[ CANCEL ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.regular))
                    .foregroundStyle(textSecondary)
                    .frame(height: 28)
            }
            .buttonStyle(.plain)
            .cornerRadius(0)

            Spacer()

            // Save
            Button {
                saveDeal()
            } label: {
                Text("[ SAVE DEAL ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "#0F1115"))
                    .padding(.horizontal, 16)
                    .frame(height: 28)
                    .background(accentGold)
                    .cornerRadius(0)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(shellSurface)
    }

    // MARK: Save Logic

    private func saveDeal() {
        let deal = PropertyDeal(
            propertyName:                propertyName,
            purchasePrice:               Double(purchasePrice)             ?? 0,
            grossPotentialIncome:        Double(grossPotentialIncome)      ?? 0,
            vacancyRate:                 Double(vacancyRate)               ?? 0,
            operatingExpenses:           Double(operatingExpenses)         ?? 0,
            loanAmount:                  Double(loanAmount)                ?? 0,
            interestRate:                Double(interestRate)              ?? 0,
            amortizationMonths:          Int(amortizationMonths)           ?? 360,
            hospitalityRoomCount:        Int(hospitalityRoomCount)         ?? 0,
            hospitalityADR:              Double(hospitalityADR)            ?? 0,
            hospitalityOccupancyRate:    Double(hospitalityOccupancyRate)  ?? 0,
            hospitalityFBRevenue:        Double(hospitalityFBRevenue)      ?? 0,
            hospitalitySpaRevenue:       Double(hospitalitySpaRevenue)     ?? 0,
            circularTotalConstructionCost:  Double(circularTotalConstructionCost)  ?? 0,
            circularRepurposedMaterialCost: Double(circularRepurposedMaterialCost) ?? 0,
            circularCO2Embodied:            Double(circularCO2Embodied)            ?? 0,
            circularKgMaterialsUsed:        Double(circularKgMaterialsUsed)        ?? 0,
            circularKgMaterialsReturned:    Double(circularKgMaterialsReturned)    ?? 0,
            circularKgMaterialsDisposed:    Double(circularKgMaterialsDisposed)    ?? 0
        )
        modelContext.insert(deal)
        onSave?(deal.id)
        dismiss()
    }
}

// TerminalInputField is defined in Views/Components/TerminalInputField.swift

// MARK: - Preview

#Preview {
    NewDealSheet()
        .background(Color(hex: "#0F1115"))
}
