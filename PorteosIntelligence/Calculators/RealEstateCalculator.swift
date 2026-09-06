import Foundation

struct RealEstateCalculator {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Legacy API (used by PropertyDealViewModel / PorteosScoreCalculator)
    // ─────────────────────────────────────────────────────────────────────────

    struct RealEstateInputs {
        var grossPotentialIncome: Double
        var vacancyRate:          Double
        var operatingExpenses:    Double
        var purchasePrice:        Double
        var loanAmount:           Double
        var interestRate:         Double
        var amortizationMonths:   Int
    }

    struct RealEstateMetrics {
        var effectiveGrossIncome:      Double
        var netOperatingIncome:        Double
        var capRate:                   Double
        var loanToValue:               Double
        var debtServiceCoverageRatio:  Double
    }

    @available(*, deprecated, message: "Use calculateFull(inputs:) — legacy path omits otherIncome and OpEx line items, producing a different NOI.")
    static func calculate(inputs: RealEstateInputs) -> RealEstateMetrics {
        let egi  = inputs.grossPotentialIncome * (1 - inputs.vacancyRate / 100)
        let noi  = egi - inputs.operatingExpenses
        let capR = safeDivide(noi, by: inputs.purchasePrice) * 100
        let ltv  = safeDivide(inputs.loanAmount, by: inputs.purchasePrice) * 100
        let ads  = monthlyPayment(
            principal:  inputs.loanAmount,
            annualRate: inputs.interestRate,
            months:     inputs.amortizationMonths
        ) * 12
        let dscr = safeDivide(noi, by: ads)
        return RealEstateMetrics(
            effectiveGrossIncome:     egi,
            netOperatingIncome:       noi,
            capRate:                  capR,
            loanToValue:              ltv,
            debtServiceCoverageRatio: dscr
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Full API (used by RealEstateDashboardView – all 5 modules)
    // ─────────────────────────────────────────────────────────────────────────

    struct FullInputs {
        // Revenue
        var grossPotentialIncome:   Double
        var vacancyRate:            Double   // e.g. 5 = 5 %
        var otherIncome:            Double   // ancillary / other income

        // OpEx – summary field (used when line items are all zero)
        var operatingExpenses:      Double

        // OpEx – individual line items (sum used when any > 0)
        var opexPropertyManagement: Double
        var opexPropertyTax:        Double
        var opexInsurance:          Double
        var opexUtilities:          Double
        var opexMaintenance:        Double
        var opexCapitalReserves:    Double

        // Acquisition
        var purchasePrice:          Double
        var closingCosts:           Double
        var renovationBudget:       Double

        // Debt
        var loanAmount:             Double
        var interestRate:           Double   // e.g. 4.5 = 4.5 %
        var amortizationMonths:     Int

        // Exit
        var exitCapRate:            Double   // percentage (0 → use entry cap rate)
    }

    // MARK: FullMetrics

    struct FullMetrics {
        // Module 01 – Revenue
        var grossPotentialIncome:   Double
        var vacancyLoss:            Double
        var effectiveGrossIncome:   Double
        var otherIncome:            Double
        var totalRevenue:           Double   // EGI + otherIncome

        // Module 02 – OpEx
        var opexPropertyManagement: Double
        var opexPropertyTax:        Double
        var opexInsurance:          Double
        var opexUtilities:          Double
        var opexMaintenance:        Double
        var opexCapitalReserves:    Double
        var totalOpEx:              Double
        var opExRatio:              Double   // % of EGI

        // Module 03 – Profitability
        var netOperatingIncome:     Double
        var ebitda:                 Double
        var capRate:                Double   // %
        var cashFlowBeforeTax:      Double
        var cashFlowAfterTax:       Double

        // Module 04 – Leverage
        var loanAmount:             Double
        var loanToValue:            Double   // %
        var loanToCost:             Double   // %
        var annualInterestRate:     Double
        var amortizationMonths:     Int
        var annualDebtService:      Double
        var debtServiceCoverageRatio: Double
        var debtYield:              Double   // %

        // Module 05 – Returns (5-year hold)
        var totalEquityInvested:    Double
        var cashOnCashReturn:       Double   // %
        var equityMultiple5Y:       Double   // multiplier
        var unleveredIRR:           Double   // %
        var leveredIRR:             Double   // %
    }

    // MARK: calculateFull

    static func calculateFull(inputs: FullInputs) -> FullMetrics {

        // ── Module 01 – Revenue ──────────────────────────────────────────────
        let gpi         = inputs.grossPotentialIncome
        let vacancyLoss = gpi * (inputs.vacancyRate / 100)
        let egi         = gpi - vacancyLoss
        let otherInc    = inputs.otherIncome
        let totalRev    = egi + otherInc

        // ── Module 02 – OpEx ─────────────────────────────────────────────────
        let lineSum = inputs.opexPropertyManagement + inputs.opexPropertyTax
                    + inputs.opexInsurance + inputs.opexUtilities
                    + inputs.opexMaintenance + inputs.opexCapitalReserves
        let totalOpEx = lineSum > 0 ? lineSum : inputs.operatingExpenses
        // OpEx ratio is expressed as % of EGI (not total revenue) per standard
        // real estate convention. Using totalRev inflated this toward 240% when
        // otherIncome was zero but operatingExpenses was entered as a large sum.
        let opExRatio = safeDivide(totalOpEx, by: egi) * 100

        // ── Module 03 – Profitability ─────────────────────────────────────────
        let noi         = totalRev - totalOpEx
        let depreciation = inputs.purchasePrice * 0.80 / 39.0  // commercial straight-line
        let ebitda      = noi + depreciation
        let capRate     = safeDivide(noi, by: inputs.purchasePrice) * 100

        let ads = monthlyPayment(
            principal:  inputs.loanAmount,
            annualRate: inputs.interestRate,
            months:     inputs.amortizationMonths
        ) * 12

        let cfbt        = noi - ads
        let taxableInc  = cfbt - depreciation
        let incomeTax   = max(0, taxableInc * 0.25)
        let cfat        = cfbt - incomeTax

        // ── Module 04 – Leverage ──────────────────────────────────────────────
        let ltv       = safeDivide(inputs.loanAmount, by: inputs.purchasePrice) * 100
        let totalCost = inputs.purchasePrice + inputs.closingCosts + inputs.renovationBudget
        let ltc       = safeDivide(inputs.loanAmount, by: totalCost) * 100
        let dscr      = safeDivide(noi, by: ads)
        let debtYield = safeDivide(noi, by: inputs.loanAmount) * 100

        // ── Module 05 – Returns (5-year hold) ─────────────────────────────────
        let equity      = max(totalCost - inputs.loanAmount, 0)
        let cocReturn   = safeDivide(cfbt, by: equity) * 100

        let exitCapUsed = inputs.exitCapRate > 0 ? inputs.exitCapRate
                        : (capRate > 0 ? capRate : 5.0)
        let exitValue   = safeDivide(noi, by: exitCapUsed / 100)

        let paidMonths  = min(60, inputs.amortizationMonths)
        let loanBal5Y   = remainingBalance(
            principal:   inputs.loanAmount,
            annualRate:  inputs.interestRate,
            totalMonths: inputs.amortizationMonths,
            paidMonths:  paidMonths
        )
        let equityAtExit   = exitValue - loanBal5Y
        let totalReturn5Y  = equityAtExit + (cfbt * 5)
        let equityMultiple = equity > 0 ? totalReturn5Y / equity : 0

        let unlevCFs: [Double] = [-totalCost] + Array(repeating: noi,  count: 4) + [noi  + exitValue]
        let levCFs:   [Double] = equity > 0
            ? [-equity] + Array(repeating: cfbt, count: 4) + [cfbt + equityAtExit]
            : Array(repeating: 0, count: 6)

        let uIRR = totalCost > 0 ? irr(cashFlows: unlevCFs) : 0
        let lIRR = equity    > 0 ? irr(cashFlows: levCFs)   : 0

        // ── Sanity guards ─────────────────────────────────────────────────────
        // Values outside these ranges indicate bad input data or diverged
        // iteration. Return 0 so the UI shows "—" rather than a nonsense number.
        let safeCapRate  = sanityCheck(capRate,   min: -50,   max:  50,  label: "capRate")
        let safeLTV      = sanityCheck(ltv,        min:   0,   max: 150,  label: "LTV")
        let safeLTC      = sanityCheck(ltc,        min:   0,   max: 150,  label: "LTC")
        let safeCoC      = sanityCheck(cocReturn,  min: -500,  max: 500,  label: "CoCReturn")
        let safeULevIRR  = sanityCheck(uIRR,       min: -100,  max: 500,  label: "unleveredIRR")
        let safeLevIRR   = sanityCheck(lIRR,       min: -100,  max: 500,  label: "leveredIRR")

        return FullMetrics(
            grossPotentialIncome:     gpi,
            vacancyLoss:              vacancyLoss,
            effectiveGrossIncome:     egi,
            otherIncome:              otherInc,
            totalRevenue:             totalRev,
            opexPropertyManagement:   inputs.opexPropertyManagement,
            opexPropertyTax:          inputs.opexPropertyTax,
            opexInsurance:            inputs.opexInsurance,
            opexUtilities:            inputs.opexUtilities,
            opexMaintenance:          inputs.opexMaintenance,
            opexCapitalReserves:      inputs.opexCapitalReserves,
            totalOpEx:                totalOpEx,
            opExRatio:                opExRatio,
            netOperatingIncome:       noi,
            ebitda:                   ebitda,
            capRate:                  safeCapRate,
            cashFlowBeforeTax:        cfbt,
            cashFlowAfterTax:         cfat,
            loanAmount:               inputs.loanAmount,
            loanToValue:              safeLTV,
            loanToCost:               safeLTC,
            annualInterestRate:       inputs.interestRate,
            amortizationMonths:       inputs.amortizationMonths,
            annualDebtService:        ads,
            debtServiceCoverageRatio: dscr,
            debtYield:                debtYield,
            totalEquityInvested:      equity,
            cashOnCashReturn:         safeCoC,
            equityMultiple5Y:         equityMultiple,
            unleveredIRR:             safeULevIRR,
            leveredIRR:               safeLevIRR
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Unit Price
    // ─────────────────────────────────────────────────────────────────────────

    /// Calculate price per square foot
    /// - Parameters:
    ///   - purchasePrice: Total purchase price
    ///   - totalArea: Total area in square feet/meters
    /// - Returns: Price per unit area
    static func pricePerSqft(purchasePrice: Double, totalArea: Double) -> Double {
        guard totalArea > 0 else { return 0 }
        return purchasePrice / totalArea
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Shared Helpers (internal for ViewModel legacy path)
    // ─────────────────────────────────────────────────────────────────────────

    static func safeDivide(_ a: Double, by b: Double) -> Double {
        guard b != 0 else { return 0 }
        return a / b
    }

    static func monthlyPayment(principal: Double, annualRate: Double, months: Int) -> Double {
        guard principal > 0, months > 0 else { return 0 }
        let r = annualRate / 100 / 12
        let n = Double(months)
        if r == 0 { return principal / n }
        let cf = pow(1 + r, n)
        guard cf - 1 != 0 else { return 0 }
        return principal * (r * cf) / (cf - 1)
    }

    private static func remainingBalance(
        principal: Double,
        annualRate: Double,
        totalMonths: Int,
        paidMonths: Int
    ) -> Double {
        guard principal > 0, totalMonths > 0, paidMonths >= 0 else { return principal }
        let r = annualRate / 100 / 12
        if r == 0 {
            return principal * (1.0 - Double(paidMonths) / Double(totalMonths))
        }
        let n = Double(totalMonths)
        let k = Double(paidMonths)
        let totalFactor = pow(1 + r, n)
        let paidFactor  = pow(1 + r, k)
        guard totalFactor - 1 != 0 else { return principal }
        return principal * (totalFactor - paidFactor) / (totalFactor - 1)
    }

    private static func irr(cashFlows: [Double], guess: Double = 0.10) -> Double {
        guard cashFlows.count >= 2 else { return 0 }

        // Require at least one sign change — without it IRR is undefined
        let hasPositive = cashFlows.contains { $0 > 0 }
        let hasNegative = cashFlows.contains { $0 < 0 }
        guard hasPositive && hasNegative else { return 0 }

        var rate = guess
        for _ in 0..<150 {
            // Guard against rate collapsing to -1 (log(0) territory)
            if rate <= -1 { rate = -0.9999 }

            var npv  = 0.0
            var dNpv = 0.0
            for (i, cf) in cashFlows.enumerated() {
                let t      = Double(i)
                let base   = 1 + rate
                guard base > 0 else { return 0 }
                let factor = pow(base, t)
                guard factor.isFinite, factor > 0 else { return 0 }
                npv  +=  cf / factor
                dNpv -= t * cf / (factor * base)
            }

            guard abs(dNpv) > 1e-12 else { break }
            let delta = npv / dNpv
            rate -= delta

            // Divergence guard — if rate has escaped plausible range, bail
            guard rate.isFinite, rate > -1, rate < 50 else { return 0 }
            if abs(delta) < 1e-9 { break }
        }

        // Final convergence check: NPV should be near zero
        var finalNPV = 0.0
        for (i, cf) in cashFlows.enumerated() {
            let base = 1 + rate
            guard base > 0 else { return 0 }
            finalNPV += cf / pow(base, Double(i))
        }
        // If NPV is still material (>0.1% of first cash flow), iteration diverged
        let threshold = abs(cashFlows[0]) * 0.001
        if abs(finalNPV) > threshold { return 0 }

        return rate * 100
    }

    /// Returns `value` if it is within [min, max]; otherwise logs a warning and
    /// returns 0. Prevents nonsense display values from bad data or diverged IRR.
    private static func sanityCheck(
        _ value: Double,
        min minVal: Double,
        max maxVal: Double,
        label: String
    ) -> Double {
        guard value.isFinite else {
            print("[RealEstateCalculator] \(label) is NaN/Inf — returning 0")
            return 0
        }
        if value < minVal || value > maxVal {
            print("[RealEstateCalculator] \(label) = \(value) outside [\(minVal), \(maxVal)] — returning 0")
            return 0
        }
        return value
    }
}
