import SwiftUI
import SwiftData

struct EditDealSheet: View {

    @Bindable var deal: PropertyDeal

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
    @State private var amortizationMonths: String = ""

    // MARK: Hospitality State

    @State private var hospitalityRoomCount: String = ""
    @State private var hospitalityADR: String = ""
    @State private var hospitalityOccupancyRate: String = ""
    @State private var hospitalityFBRevenue: String = ""
    @State private var hospitalitySpaRevenue: String = ""

    // MARK: Circular Economy State

    @State private var circularTotalConstructionCost: String = ""
    @State private var circularRepurposedMaterialCost: String = ""
    @State private var circularCO2Embodied: String = ""
    @State private var circularKgMaterialsUsed: String = ""
    @State private var circularKgMaterialsReturned: String = ""
    @State private var circularKgMaterialsDisposed: String = ""

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
        .onAppear { populateFields() }
    }

    // MARK: Sheet Header

    private var sheetHeader: some View {
        HStack {
            Text("EDIT DEAL")
                .font(.custom("Inter", size: 14).weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(textPrimary)

            Spacer()

            Button { dismiss() } label: {
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
                .font(.custom("Inter", size: 10).weight(.bold))
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
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.regular))
                    .foregroundStyle(textSecondary)
                    .frame(height: 28)
            }
            .buttonStyle(.plain)
            .cornerRadius(0)

            Spacer()

            Button { saveDeal() } label: {
                Text("[ SAVE CHANGES ]")
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

    // MARK: Populate on Appear

    private func populateFields() {
        propertyName            = deal.propertyName
        purchasePrice           = deal.purchasePrice        == 0 ? "" : String(deal.purchasePrice)
        grossPotentialIncome    = deal.grossPotentialIncome == 0 ? "" : String(deal.grossPotentialIncome)
        vacancyRate             = deal.vacancyRate          == 0 ? "" : String(deal.vacancyRate)
        operatingExpenses       = deal.operatingExpenses    == 0 ? "" : String(deal.operatingExpenses)
        loanAmount              = deal.loanAmount           == 0 ? "" : String(deal.loanAmount)
        interestRate            = deal.interestRate         == 0 ? "" : String(deal.interestRate)
        amortizationMonths      = String(deal.amortizationMonths)
        hospitalityRoomCount    = deal.hospitalityRoomCount == 0 ? "" : String(deal.hospitalityRoomCount)
        hospitalityADR          = deal.hospitalityADR       == 0 ? "" : String(deal.hospitalityADR)
        hospitalityOccupancyRate = deal.hospitalityOccupancyRate == 0 ? "" : String(deal.hospitalityOccupancyRate)
        hospitalityFBRevenue    = deal.hospitalityFBRevenue == 0 ? "" : String(deal.hospitalityFBRevenue)
        hospitalitySpaRevenue   = deal.hospitalitySpaRevenue == 0 ? "" : String(deal.hospitalitySpaRevenue)
        circularTotalConstructionCost  = deal.circularTotalConstructionCost  == 0 ? "" : String(deal.circularTotalConstructionCost)
        circularRepurposedMaterialCost = deal.circularRepurposedMaterialCost == 0 ? "" : String(deal.circularRepurposedMaterialCost)
        circularCO2Embodied            = deal.circularCO2Embodied            == 0 ? "" : String(deal.circularCO2Embodied)
        circularKgMaterialsUsed        = deal.circularKgMaterialsUsed        == 0 ? "" : String(deal.circularKgMaterialsUsed)
        circularKgMaterialsReturned    = deal.circularKgMaterialsReturned    == 0 ? "" : String(deal.circularKgMaterialsReturned)
        circularKgMaterialsDisposed    = deal.circularKgMaterialsDisposed    == 0 ? "" : String(deal.circularKgMaterialsDisposed)
    }

    // MARK: Save Logic

    private func saveDeal() {
        deal.propertyName            = propertyName
        deal.purchasePrice           = Double(purchasePrice)            ?? deal.purchasePrice
        deal.grossPotentialIncome    = Double(grossPotentialIncome)     ?? deal.grossPotentialIncome
        deal.vacancyRate             = Double(vacancyRate)              ?? deal.vacancyRate
        deal.operatingExpenses       = Double(operatingExpenses)        ?? deal.operatingExpenses
        deal.loanAmount              = Double(loanAmount)               ?? deal.loanAmount
        deal.interestRate            = Double(interestRate)             ?? deal.interestRate
        deal.amortizationMonths      = Int(amortizationMonths)          ?? deal.amortizationMonths
        deal.hospitalityRoomCount    = Int(hospitalityRoomCount)        ?? deal.hospitalityRoomCount
        deal.hospitalityADR          = Double(hospitalityADR)           ?? deal.hospitalityADR
        deal.hospitalityOccupancyRate = Double(hospitalityOccupancyRate) ?? deal.hospitalityOccupancyRate
        deal.hospitalityFBRevenue    = Double(hospitalityFBRevenue)     ?? deal.hospitalityFBRevenue
        deal.hospitalitySpaRevenue   = Double(hospitalitySpaRevenue)    ?? deal.hospitalitySpaRevenue
        deal.circularTotalConstructionCost  = Double(circularTotalConstructionCost)  ?? deal.circularTotalConstructionCost
        deal.circularRepurposedMaterialCost = Double(circularRepurposedMaterialCost) ?? deal.circularRepurposedMaterialCost
        deal.circularCO2Embodied            = Double(circularCO2Embodied)            ?? deal.circularCO2Embodied
        deal.circularKgMaterialsUsed        = Double(circularKgMaterialsUsed)        ?? deal.circularKgMaterialsUsed
        deal.circularKgMaterialsReturned    = Double(circularKgMaterialsReturned)    ?? deal.circularKgMaterialsReturned
        deal.circularKgMaterialsDisposed    = Double(circularKgMaterialsDisposed)    ?? deal.circularKgMaterialsDisposed
        deal.updatedAt               = Date()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal = PropertyDeal(
        propertyName:         "Lisbon Office Block A",
        purchasePrice:        2_000_000,
        grossPotentialIncome: 180_000,
        vacancyRate:          5,
        operatingExpenses:    55_000,
        loanAmount:           1_500_000,
        interestRate:         4.5,
        amortizationMonths:   360,
        hospitalityRoomCount: 50,
        hospitalityADR:       120,
        hospitalityOccupancyRate: 75
    )
    container.mainContext.insert(deal)

    return EditDealSheet(deal: deal)
        .modelContainer(container)
        .background(Color(hex: "#0F1115"))
}
