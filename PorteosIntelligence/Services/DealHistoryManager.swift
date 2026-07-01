import Foundation
import Observation

// MARK: - DealSnapshot
//
// A fully-typed, value-type capture of all user-editable PropertyDeal fields.
// Intentionally excludes id, createdAt, and aiAnalysisText (derived output).

struct DealSnapshot {

    // MARK: Context
    let dealID:    UUID
    let timestamp: Date
    let label:     String   // e.g. "Benchmark: Interest Rate", "Deal Edit"

    // MARK: Base
    let propertyName:    String
    let address:         String
    let propertyType:    String
    let totalArea:       Double
    let locationCity:    String

    // MARK: Real Estate
    let purchasePrice:        Double
    let closingCosts:         Double
    let renovationBudget:     Double
    let grossPotentialIncome: Double
    let vacancyRate:          Double
    let otherIncome:          Double
    let operatingExpenses:    Double
    let loanAmount:           Double
    let interestRate:         Double
    let amortizationMonths:   Int
    let exitCapRate:          Double

    // MARK: Real Estate OpEx
    let opexPropertyManagement: Double
    let opexPropertyTax:        Double
    let opexInsurance:          Double
    let opexUtilities:          Double
    let opexMaintenance:        Double
    let opexCapitalReserves:    Double

    // MARK: Hospitality
    let hospitalityRoomCount:        Int
    let hospitalityADR:              Double
    let hospitalityOccupancyRate:    Double
    let hospitalityFBRevenue:        Double
    let hospitalitySpaRevenue:       Double
    let hospitalityMeetingRevenue:   Double
    let hospitalityOtherRevenue:     Double
    let hospitalityOpExRatio:        Double
    let hospitalityDirectBookingPct: Double
    let hospitalityOTABookingPct:    Double
    let hospitalityDistributionCost: Double

    // MARK: Circular Economy
    let circularTotalConstructionCost:  Double
    let circularRepurposedMaterialCost: Double
    let circularCO2Embodied:            Double
    let circularKgMaterialsUsed:        Double
    let circularKgMaterialsReturned:    Double
    let circularKgMaterialsDisposed:    Double
    let circularRecycledContentPct:     Double
    let circularRenewableContentPct:    Double
    let circularWasteGenerated:         Double
    let circularOperationalCarbon:      Double
    let circularBuildingAreaM2:         Double
    let circularWaterRecyclingRate:     Double

    // MARK: Design
    let designGFA:                 Double
    let designNIA:                 Double
    let designCirculationPct:      Double
    let designSpaceUtilization:    Double
    let designDaylighting:         Double
    let designCO2ppm:              Double
    let designACH:                 Double
    let designThermalComfort:      Double
    let designAcousticComfort:     Double
    let designBiophilicCount:      Int
    let designGreenWallM2:         Double
    let designViewsToNaturePct:    Double
    let designNaturalMaterialsPct: Double
    let designMovablePartitionPct: Double
    let designMultiUseSpaces:      Int
    let designAdaptabilityScore:   Double

    // MARK: Weights & Score
    let weightRealEstate:  Double
    let weightHospitality: Double
    let weightDesign:      Double
    let weightCircular:    Double
    let porteosScore:      Double?

    // MARK: Metadata
    let notes:      String
    let tags:       [String]
    let isFavorite: Bool
    let status:     DealStatus

    // MARK: Init from PropertyDeal

    init(deal: PropertyDeal, label: String) {
        self.dealID    = deal.id
        self.timestamp = Date()
        self.label     = label

        self.propertyName    = deal.propertyName
        self.address         = deal.address
        self.propertyType    = deal.propertyType
        self.totalArea       = deal.totalArea
        self.locationCity    = deal.locationCity

        self.purchasePrice        = deal.purchasePrice
        self.closingCosts         = deal.closingCosts
        self.renovationBudget     = deal.renovationBudget
        self.grossPotentialIncome = deal.grossPotentialIncome
        self.vacancyRate          = deal.vacancyRate
        self.otherIncome          = deal.otherIncome
        self.operatingExpenses    = deal.operatingExpenses
        self.loanAmount           = deal.loanAmount
        self.interestRate         = deal.interestRate
        self.amortizationMonths   = deal.amortizationMonths
        self.exitCapRate          = deal.exitCapRate

        self.opexPropertyManagement = deal.opexPropertyManagement
        self.opexPropertyTax        = deal.opexPropertyTax
        self.opexInsurance          = deal.opexInsurance
        self.opexUtilities          = deal.opexUtilities
        self.opexMaintenance        = deal.opexMaintenance
        self.opexCapitalReserves    = deal.opexCapitalReserves

        self.hospitalityRoomCount        = deal.hospitalityRoomCount
        self.hospitalityADR              = deal.hospitalityADR
        self.hospitalityOccupancyRate    = deal.hospitalityOccupancyRate
        self.hospitalityFBRevenue        = deal.hospitalityFBRevenue
        self.hospitalitySpaRevenue       = deal.hospitalitySpaRevenue
        self.hospitalityMeetingRevenue   = deal.hospitalityMeetingRevenue
        self.hospitalityOtherRevenue     = deal.hospitalityOtherRevenue
        self.hospitalityOpExRatio        = deal.hospitalityOpExRatio
        self.hospitalityDirectBookingPct = deal.hospitalityDirectBookingPct
        self.hospitalityOTABookingPct    = deal.hospitalityOTABookingPct
        self.hospitalityDistributionCost = deal.hospitalityDistributionCost

        self.circularTotalConstructionCost  = deal.circularTotalConstructionCost
        self.circularRepurposedMaterialCost = deal.circularRepurposedMaterialCost
        self.circularCO2Embodied            = deal.circularCO2Embodied
        self.circularKgMaterialsUsed        = deal.circularKgMaterialsUsed
        self.circularKgMaterialsReturned    = deal.circularKgMaterialsReturned
        self.circularKgMaterialsDisposed    = deal.circularKgMaterialsDisposed
        self.circularRecycledContentPct     = deal.circularRecycledContentPct
        self.circularRenewableContentPct    = deal.circularRenewableContentPct
        self.circularWasteGenerated         = deal.circularWasteGenerated
        self.circularOperationalCarbon      = deal.circularOperationalCarbon
        self.circularBuildingAreaM2         = deal.circularBuildingAreaM2
        self.circularWaterRecyclingRate     = deal.circularWaterRecyclingRate

        self.designGFA                 = deal.designGFA
        self.designNIA                 = deal.designNIA
        self.designCirculationPct      = deal.designCirculationPct
        self.designSpaceUtilization    = deal.designSpaceUtilization
        self.designDaylighting         = deal.designDaylighting
        self.designCO2ppm              = deal.designCO2ppm
        self.designACH                 = deal.designACH
        self.designThermalComfort      = deal.designThermalComfort
        self.designAcousticComfort     = deal.designAcousticComfort
        self.designBiophilicCount      = deal.designBiophilicCount
        self.designGreenWallM2         = deal.designGreenWallM2
        self.designViewsToNaturePct    = deal.designViewsToNaturePct
        self.designNaturalMaterialsPct = deal.designNaturalMaterialsPct
        self.designMovablePartitionPct = deal.designMovablePartitionPct
        self.designMultiUseSpaces      = deal.designMultiUseSpaces
        self.designAdaptabilityScore   = deal.designAdaptabilityScore

        self.weightRealEstate  = deal.weightRealEstate
        self.weightHospitality = deal.weightHospitality
        self.weightDesign      = deal.weightDesign
        self.weightCircular    = deal.weightCircular
        self.porteosScore      = deal.porteosScore

        self.notes      = deal.notes
        self.tags       = deal.tags
        self.isFavorite = deal.isFavorite
        self.status     = deal.status
    }
}

// MARK: - DealHistoryManager
//
// Per-session, in-memory undo/redo for PropertyDeal mutations.
// Named DealHistoryManager to avoid conflict with Foundation.UndoManager.
//
// Usage pattern (caller must push BEFORE mutating the deal):
//   DealHistoryManager.shared.push(deal: deal, label: "Benchmark: Interest Rate")
//   deal.interestRate = newValue   // mutate after push

@Observable
final class DealHistoryManager {

    static let shared = DealHistoryManager()
    private init() {}

    // MARK: Published State

    private(set) var canUndo   = false
    private(set) var canRedo   = false
    private(set) var undoLabel = ""
    private(set) var redoLabel = ""

    // MARK: Stacks

    private var undoStack: [DealSnapshot] = []
    private var redoStack: [DealSnapshot] = []
    private let maxStackSize = 50

    // MARK: API

    /// Push the current deal state onto the undo stack BEFORE making changes.
    func push(deal: PropertyDeal, label: String = "Edit") {
        let snap = DealSnapshot(deal: deal, label: label)
        undoStack.append(snap)
        if undoStack.count > maxStackSize { undoStack.removeFirst() }
        redoStack.removeAll()
        refresh()
    }

    /// Pop the most-recent snapshot, saving current state for redo.
    /// Returns the snapshot to apply, or nil if stack is empty.
    func undo(currentState deal: PropertyDeal) -> DealSnapshot? {
        guard let snap = undoStack.popLast() else { return nil }
        redoStack.append(DealSnapshot(deal: deal, label: snap.label))
        refresh()
        return snap
    }

    /// Reapply the most-recently undone snapshot, saving current state for undo.
    func redo(currentState deal: PropertyDeal) -> DealSnapshot? {
        guard let snap = redoStack.popLast() else { return nil }
        undoStack.append(DealSnapshot(deal: deal, label: snap.label))
        refresh()
        return snap
    }

    // MARK: Apply

    /// Write all snapshot fields back onto a PropertyDeal in-place.
    /// Caller is responsible for saving the ModelContext afterwards.
    func apply(_ snap: DealSnapshot, to deal: PropertyDeal) {
        guard snap.dealID == deal.id else { return }

        deal.propertyName    = snap.propertyName
        deal.address         = snap.address
        deal.propertyType    = snap.propertyType
        deal.totalArea       = snap.totalArea
        deal.locationCity    = snap.locationCity

        deal.purchasePrice        = snap.purchasePrice
        deal.closingCosts         = snap.closingCosts
        deal.renovationBudget     = snap.renovationBudget
        deal.grossPotentialIncome = snap.grossPotentialIncome
        deal.vacancyRate          = snap.vacancyRate
        deal.otherIncome          = snap.otherIncome
        deal.operatingExpenses    = snap.operatingExpenses
        deal.loanAmount           = snap.loanAmount
        deal.interestRate         = snap.interestRate
        deal.amortizationMonths   = snap.amortizationMonths
        deal.exitCapRate          = snap.exitCapRate

        deal.opexPropertyManagement = snap.opexPropertyManagement
        deal.opexPropertyTax        = snap.opexPropertyTax
        deal.opexInsurance          = snap.opexInsurance
        deal.opexUtilities          = snap.opexUtilities
        deal.opexMaintenance        = snap.opexMaintenance
        deal.opexCapitalReserves    = snap.opexCapitalReserves

        deal.hospitalityRoomCount        = snap.hospitalityRoomCount
        deal.hospitalityADR              = snap.hospitalityADR
        deal.hospitalityOccupancyRate    = snap.hospitalityOccupancyRate
        deal.hospitalityFBRevenue        = snap.hospitalityFBRevenue
        deal.hospitalitySpaRevenue       = snap.hospitalitySpaRevenue
        deal.hospitalityMeetingRevenue   = snap.hospitalityMeetingRevenue
        deal.hospitalityOtherRevenue     = snap.hospitalityOtherRevenue
        deal.hospitalityOpExRatio        = snap.hospitalityOpExRatio
        deal.hospitalityDirectBookingPct = snap.hospitalityDirectBookingPct
        deal.hospitalityOTABookingPct    = snap.hospitalityOTABookingPct
        deal.hospitalityDistributionCost = snap.hospitalityDistributionCost

        deal.circularTotalConstructionCost  = snap.circularTotalConstructionCost
        deal.circularRepurposedMaterialCost = snap.circularRepurposedMaterialCost
        deal.circularCO2Embodied            = snap.circularCO2Embodied
        deal.circularKgMaterialsUsed        = snap.circularKgMaterialsUsed
        deal.circularKgMaterialsReturned    = snap.circularKgMaterialsReturned
        deal.circularKgMaterialsDisposed    = snap.circularKgMaterialsDisposed
        deal.circularRecycledContentPct     = snap.circularRecycledContentPct
        deal.circularRenewableContentPct    = snap.circularRenewableContentPct
        deal.circularWasteGenerated         = snap.circularWasteGenerated
        deal.circularOperationalCarbon      = snap.circularOperationalCarbon
        deal.circularBuildingAreaM2         = snap.circularBuildingAreaM2
        deal.circularWaterRecyclingRate     = snap.circularWaterRecyclingRate

        deal.designGFA                 = snap.designGFA
        deal.designNIA                 = snap.designNIA
        deal.designCirculationPct      = snap.designCirculationPct
        deal.designSpaceUtilization    = snap.designSpaceUtilization
        deal.designDaylighting         = snap.designDaylighting
        deal.designCO2ppm              = snap.designCO2ppm
        deal.designACH                 = snap.designACH
        deal.designThermalComfort      = snap.designThermalComfort
        deal.designAcousticComfort     = snap.designAcousticComfort
        deal.designBiophilicCount      = snap.designBiophilicCount
        deal.designGreenWallM2         = snap.designGreenWallM2
        deal.designViewsToNaturePct    = snap.designViewsToNaturePct
        deal.designNaturalMaterialsPct = snap.designNaturalMaterialsPct
        deal.designMovablePartitionPct = snap.designMovablePartitionPct
        deal.designMultiUseSpaces      = snap.designMultiUseSpaces
        deal.designAdaptabilityScore   = snap.designAdaptabilityScore

        deal.weightRealEstate  = snap.weightRealEstate
        deal.weightHospitality = snap.weightHospitality
        deal.weightDesign      = snap.weightDesign
        deal.weightCircular    = snap.weightCircular
        deal.porteosScore      = snap.porteosScore

        deal.notes      = snap.notes
        deal.tags       = snap.tags
        deal.isFavorite = snap.isFavorite
        deal.status     = snap.status
    }

    // MARK: Private

    private func refresh() {
        canUndo   = !undoStack.isEmpty
        canRedo   = !redoStack.isEmpty
        undoLabel = undoStack.last?.label ?? ""
        redoLabel = redoStack.last?.label ?? ""
    }
}
