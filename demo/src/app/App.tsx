import { useReducer } from 'react'
import { appReducer } from './appReducer'
import { initialAppState } from './appState'
import { LeftSidebar } from '../components/LeftSidebar'
import { RightInspector } from '../components/RightInspector'
import { CommandCenter } from '../components/CommandCenter'
import { ProfileDashboard } from '../components/ProfileDashboard'
import { DEALS } from '../data/demoData'
import './App.css'

export function App() {
  const [state, dispatch] = useReducer(appReducer, initialAppState)

  const selectedDeal = state.selectedDealId
    ? DEALS.find((d) => d.id === state.selectedDealId)
    : null

  return (
    <div className="app-container">
      <LeftSidebar
        viewMode={state.viewMode}
        selectedDealId={state.selectedDealId}
        deals={DEALS}
        searchQuery={state.searchQuery}
        onViewChange={(view) => {
          dispatch({ type: 'SET_VIEW_MODE', payload: view })
        }}
        onDealSelect={(id) => {
          dispatch({ type: 'SELECT_DEAL', payload: id })
        }}
        onSearchChange={(query) => {
          dispatch({ type: 'SET_SEARCH', payload: query })
        }}
        onNewDeal={() => {
          dispatch({ type: 'TOGGLE_DEAL_MODAL', payload: true })
        }}
      />

      <main className="main-workspace">
        {state.viewMode === 'command-center' && <CommandCenter />}
        {state.viewMode !== 'command-center' && (
          <ProfileDashboard profile={state.viewMode} dealName={selectedDeal?.name} />
        )}
      </main>

      <RightInspector
        activeTab={state.inspectorTab}
        onTabChange={(tab) => {
          dispatch({ type: 'SET_INSPECTOR_TAB', payload: tab })
        }}
        onEditData={() => {
          dispatch({ type: 'TOGGLE_DEAL_MODAL', payload: true })
        }}
        onGeneratePdf={() => {
          dispatch({ type: 'TOGGLE_PDF_PREVIEW', payload: true })
        }}
      />

      {state.showDealModal && (
        <div
          className="modal-overlay"
          onClick={() => {
            dispatch({ type: 'TOGGLE_DEAL_MODAL', payload: false })
          }}
        >
          <div
            className="modal-content"
            onClick={(e) => {
              e.stopPropagation()
            }}
          >
            <div className="modal-header">
              <h2>Edit Deal Data</h2>
              <button
                className="modal-close"
                onClick={() => {
                  dispatch({ type: 'TOGGLE_DEAL_MODAL', payload: false })
                }}
              >
                ×
              </button>
            </div>
            <div className="modal-body">
              <p>Deal editing interface placeholder</p>
            </div>
          </div>
        </div>
      )}

      {state.showPdfPreview && (
        <div
          className="modal-overlay"
          onClick={() => {
            dispatch({ type: 'TOGGLE_PDF_PREVIEW', payload: false })
          }}
        >
          <div
            className="modal-content large"
            onClick={(e) => {
              e.stopPropagation()
            }}
          >
            <div className="modal-header">
              <h2>PDF Preview</h2>
              <button
                className="modal-close"
                onClick={() => {
                  dispatch({ type: 'TOGGLE_PDF_PREVIEW', payload: false })
                }}
              >
                ×
              </button>
            </div>
            <div className="modal-body">
              <div className="pdf-preview">
                <p>PDF report preview placeholder</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
