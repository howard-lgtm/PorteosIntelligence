# Porteos Intelligence - Data, Metrics & Logic Specification
**Purpose:** Comprehensive list of ALL metrics, functions, data models, and AI features.
**Context:** All UI rendering for these metrics MUST strictly follow `01_TERMINAL_DESIGN_SYSTEM.md`.

## 1. DATA PERSISTENCE (SwiftData Models)
### 1.1 Primary Model: PropertyDeal
```swift
@Model
final class PropertyDeal {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // Base Data
    var baseData: BaseData
    var realEstateModel: RealEstateModel
    
    // Profile Inputs
    var hospitalityInputs: HospitalityInputs?
    var designInputs: DesignInputs?
    var circularEconomyInputs: CircularEconomyInputs?
    
    // Weights & Scoring
    var profileWeights: ProfileWeights
    var porteosScore: Double?
    var investorScore: InvestorScore?
    
    // Metadata
    var notes: String
    var tags: [String]
    var isFavorite: Bool
    var status: DealStatus // viable, review, rejected, acquired, pipeline
    
    // AI Analysis
    var aiAnalysis: AIAnalysis?
    var chatHistory: [ChatMessage]
}