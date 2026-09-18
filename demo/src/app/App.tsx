import { useReducer } from 'react'
import { demoReducer } from './demoReducer'
import { initialDemoState } from './demoState'
import './App.css'

export function App() {
  const [state, dispatch] = useReducer(demoReducer, initialDemoState)

  const handleReset = () => {
    dispatch({ type: 'RESET_DEMO' })
  }

  return (
    <main>
      <div className="scaffold-container">
        <div className="scaffold-header">
          <h1 className="scaffold-title">Porteos Intelligence</h1>
          <p className="scaffold-subtitle">Usability Demo Scaffold</p>
        </div>

        <div className="scaffold-status">
          <div className="status-item">
            <span className="status-label">Current Phase:</span>
            <span className="status-value">{state.phase}</span>
          </div>
          <div className="status-item">
            <span className="status-label">Active Profile:</span>
            <span className="status-value" data-profile={state.activeProfile}>
              {state.activeProfile}
            </span>
          </div>
          <div className="status-item">
            <span className="status-label">Status:</span>
            <span className="status-value">
              {state.isComplete ? 'Complete' : 'Ready for Implementation'}
            </span>
          </div>
        </div>

        <div className="scaffold-message">
          <p>Scaffold infrastructure ready.</p>
          <p>State management, types, and token system are in place.</p>
          <p>UI implementation is pending agent build.</p>
        </div>

        <button className="reset-button" onClick={handleReset} type="button">
          Reset Demo State
        </button>
      </div>
    </main>
  )
}
