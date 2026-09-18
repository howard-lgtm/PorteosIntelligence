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
    { id: 'latest', label: 'WEIGHT...' },
    { id: 'intel', label: 'VIBE' },
    { id: 'media', label: 'MEDIA' },
    { id: 'research', label: 'RESEAR...' },
  ]

  return (
    <aside className="right-inspector">
      {/* Inspector Path Header */}
      <div className="inspector-path-bar">
        <span className="inspector-path">./INSPECTOR_V2</span>
        <span className="inspector-path-icon">[ * ]</span>
      </div>

      {/* Tab Bar */}
      <div className="inspector-tabs">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            className={`inspector-tab ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => { onTabChange(tab.id) }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="inspector-content">
        {activeTab === 'latest' && (
          <div className="inspector-section">
            {/* Primary Actions */}
            <button className="btn-action-filled" onClick={onEditData}>
              [ EDIT DEAL DATA ]
            </button>
            <button className="btn-action-outlined" onClick={onGeneratePdf}>
              [ PDF ]
            </button>

            <div className="section-divider" />

            {/* Profile Weights */}
            <div className="profile-weights">
              <div className="weights-header">[ APPLY WEIGHTS FOR HOTEL ]</div>
              {[
                { label: 'REAL ESTATE', value: '25 %', color: 'var(--color-accent-rust)' },
                { label: 'HOSPITALITY', value: '25 %', color: 'var(--color-accent-hospitality)' },
                { label: 'DESIGN', value: '25 %', color: 'var(--color-accent-design)' },
                { label: 'CIRCULAR ECONOMY', value: '25 %', color: 'var(--color-accent-circular)' },
              ].map(({ label, value, color }) => (
                <div className="weight-item" key={label}>
                  <div className="weight-row-accent" style={{ backgroundColor: color }} />
                  <span className="weight-label">{label}</span>
                  <span className="weight-value">{value}</span>
                </div>
              ))}
              <div className="weight-item weight-total">
                <div className="weight-row-accent" />
                <span className="weight-label">TOTAL</span>
                <span className="weight-value weight-total-value">100,0%</span>
              </div>
            </div>

            <div className="section-divider" />

            {/* Founder Lens */}
            <div className="founder-lens">
              <div className="founder-lens-label">// FOUNDER_LENS</div>
              <div className="founder-lens-options">
                <button className="lens-option">[ ] LOW</button>
                <button className="lens-option active">(+) MED</button>
                <button className="lens-option">[ ] HIGH</button>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'intel' && (
          <div className="inspector-section">
            <div className="tab-placeholder">// AI_VIBE_ANALYSIS<br />Run analysis to see signals.</div>
          </div>
        )}

        {activeTab === 'media' && (
          <div className="inspector-section">
            <div className="tab-placeholder">// MEDIA_GALLERY<br />No media attached.</div>
          </div>
        )}

        {activeTab === 'research' && (
          <div className="inspector-section">
            <div className="tab-placeholder">// RESEARCH_LINKS<br />No sources linked.</div>
          </div>
        )}
      </div>
    </aside>
  )
}
