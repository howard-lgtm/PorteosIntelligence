import { type InspectorTab } from '../types/demo'
import './RightInspector.css'

interface Props {
  activeTab: InspectorTab
  onTabChange: (tab: InspectorTab) => void
  onEditData: () => void
  onGeneratePdf: () => void
}

export function RightInspector({ activeTab, onTabChange, onEditData, onGeneratePdf }: Props) {
  const tabs: { id: InspectorTab; label: string }[] = [
    { id: 'latest', label: 'LATEST' },
    { id: 'intel', label: 'INTEL' },
    { id: 'media', label: 'MEDIA' },
    { id: 'research', label: 'RESEARCH…' },
  ]

  return (
    <aside className="right-inspector">
      <div className="inspector-header">
        <div className="inspector-tabs">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={`inspector-tab ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => {
                onTabChange(tab.id)
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="inspector-content">
        {activeTab === 'latest' && (
          <div className="inspector-section">
            <button className="btn-action" onClick={onEditData}>
              [ EDIT DEAL DATA ]
            </button>
            <button className="btn-action" onClick={onGeneratePdf}>
              [ PDF ]
            </button>

            <div className="section-divider" />

            <div className="profile-weights">
              <div className="section-title">[ APPLY WEIGHTS FOR HOTEL ]</div>
              <div className="weight-item">
                <span className="weight-label">REAL ESTATE</span>
                <span className="weight-value">25 %</span>
              </div>
              <div className="weight-item">
                <span className="weight-label">HOSPITALITY</span>
                <span className="weight-value">25 %</span>
              </div>
              <div className="weight-item">
                <span className="weight-label">DESIGN</span>
                <span className="weight-value">25 %</span>
              </div>
              <div className="weight-item">
                <span className="weight-label">CIRCULAR ECONOMY</span>
                <span className="weight-value">25 %</span>
              </div>
              <div className="weight-item total">
                <span className="weight-label">TOTAL</span>
                <span className="weight-value">100,0%</span>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'intel' && (
          <div className="inspector-section">
            <div className="intel-placeholder">
              <p>Intelligence feed placeholder</p>
            </div>
          </div>
        )}

        {activeTab === 'media' && (
          <div className="inspector-section">
            <div className="media-placeholder">
              <p>Media gallery placeholder</p>
            </div>
          </div>
        )}

        {activeTab === 'research' && (
          <div className="inspector-section">
            <div className="research-placeholder">
              <p>Research links placeholder</p>
            </div>
          </div>
        )}
      </div>
    </aside>
  )
}
