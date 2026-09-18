import type { AppState } from '../types/demo'

export const initialAppState: AppState = {
  viewMode: 'command-center',
  selectedDealId: null,
  inspectorTab: 'latest',
  showDealModal: false,
  showPdfPreview: false,
  searchQuery: '',
  statusFilter: 'ALL',
}
