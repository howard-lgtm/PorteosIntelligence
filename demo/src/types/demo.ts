export type ViewMode =
  'command-center' | 'real-estate' | 'hospitality' | 'design' | 'circular' | 'global-intel'

export type InspectorTab = 'latest' | 'intel' | 'media' | 'research'

export interface Deal {
  id: string
  name: string
  location: string
  type: string
  value: number
  score: number
  grade: string
  status: 'pipeline' | 'viable' | 'rejected'
}

export interface AppState {
  viewMode: ViewMode
  selectedDealId: string | null
  inspectorTab: InspectorTab
  showDealModal: boolean
  showPdfPreview: boolean
  searchQuery: string
  statusFilter: string
}

export type AppAction =
  | { type: 'SET_VIEW_MODE'; payload: ViewMode }
  | { type: 'SELECT_DEAL'; payload: string | null }
  | { type: 'SET_INSPECTOR_TAB'; payload: InspectorTab }
  | { type: 'TOGGLE_DEAL_MODAL'; payload: boolean }
  | { type: 'TOGGLE_PDF_PREVIEW'; payload: boolean }
  | { type: 'SET_SEARCH'; payload: string }
  | { type: 'SET_STATUS_FILTER'; payload: string }
