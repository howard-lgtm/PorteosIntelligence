import type { AppState, AppAction } from '../types/demo'

export function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_VIEW_MODE':
      return { ...state, viewMode: action.payload }

    case 'SELECT_DEAL':
      return { ...state, selectedDealId: action.payload }

    case 'SET_INSPECTOR_TAB':
      return { ...state, inspectorTab: action.payload }

    case 'TOGGLE_DEAL_MODAL':
      return { ...state, showDealModal: action.payload }

    case 'TOGGLE_PDF_PREVIEW':
      return { ...state, showPdfPreview: action.payload }

    case 'SET_SEARCH':
      return { ...state, searchQuery: action.payload }

    default:
      return state
  }
}
