export type DemoPhase = 'prepare' | 'import' | 'processing' | 'evaluate' | 'report' | 'complete'

export type IntelligenceProfile = 'real-estate' | 'hospitality' | 'design' | 'circular' | 'global'

export interface PropertyData {
  id: string
  name: string
  location: string
  type: string
  value: number
}

export interface ImportedFile {
  id: string
  name: string
  type: string
  size: number
}

export interface ProcessingProgress {
  current: number
  total: number
  message: string
}

export interface EvaluationResult {
  score: number
  grade: string
  verdict: string
  signals: {
    location: number
    timing: number
    cashFlow: number
    risk: number
    esg: number
  }
}

export interface ReportState {
  generated: boolean
  format: 'pdf' | 'json' | null
}

export interface DemoState {
  phase: DemoPhase
  selectedProperty: PropertyData | null
  importedFiles: ImportedFile[]
  processingProgress: ProcessingProgress | null
  activeProfile: IntelligenceProfile
  evaluationResult: EvaluationResult | null
  reportState: ReportState
  isComplete: boolean
}

export type DemoAction =
  | { type: 'START_DEMO' }
  | { type: 'SELECT_PROPERTY'; payload: PropertyData }
  | { type: 'ADD_FILE'; payload: ImportedFile }
  | { type: 'START_PROCESSING' }
  | { type: 'UPDATE_PROGRESS'; payload: ProcessingProgress }
  | { type: 'COMPLETE_PROCESSING'; payload: EvaluationResult }
  | { type: 'SWITCH_PROFILE'; payload: IntelligenceProfile }
  | { type: 'GENERATE_REPORT'; payload: 'pdf' | 'json' }
  | { type: 'COMPLETE_DEMO' }
  | { type: 'RESET_DEMO' }
