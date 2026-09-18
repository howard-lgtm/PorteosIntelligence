import type { ViewMode } from '../types/demo'
import './ProfileDashboard.css'

interface Props {
  profile: ViewMode
  dealName?: string
}

export function ProfileDashboard({ profile, dealName }: Props) {
  const titles: Record<ViewMode, string> = {
    'command-center': 'Command Center',
    'real-estate': 'Real Estate Dashboard',
    hospitality: 'Hospitality Dashboard',
    design: 'Design Dashboard',
    circular: 'Circular Economy Dashboard',
    'global-intel': 'Global Intelligence',
  }

  const colors: Record<ViewMode, string> = {
    'command-center': 'var(--color-orange-primary)',
    'real-estate': 'var(--color-blue)',
    hospitality: 'var(--color-teal)',
    design: 'var(--color-purple)',
    circular: 'var(--color-green)',
    'global-intel': 'var(--color-cyan)',
  }

  return (
    <div className="profile-dashboard">
      {dealName && (
        <div className="profile-header">
          <div className="score-hero">
            <div className="score-value">80</div>
            <div className="score-label">/ 100</div>
          </div>
          <div className="deal-info">
            <div className="deal-title">{dealName}</div>
            <div className="grade-badge" style={{ borderColor: colors[profile] }}>
              B
            </div>
          </div>
        </div>
      )}

      <div className="dashboard-title" style={{ color: colors[profile] }}>
        {titles[profile]}
      </div>

      <div className="dashboard-grid">
        <div className="dashboard-section">
          <div className="section-label">01 // MARKET_TRENDS</div>
          <div className="section-content">
            <div className="metric-row">
              <span className="metric-key">LOCATION SCORE</span>
              <span className="metric-val positive">+22 %</span>
            </div>
            <div className="metric-row">
              <span className="metric-key">MARKET TIMING</span>
              <span className="metric-val">–</span>
            </div>
            <div className="metric-row">
              <span className="metric-key">CASH FLOW</span>
              <span className="metric-val positive">+ 34%</span>
            </div>
            <div className="metric-row">
              <span className="metric-key">RISK MEASURE</span>
              <span className="metric-val warning">↑ HIGH</span>
            </div>
          </div>
        </div>

        <div className="dashboard-section">
          <div className="section-label">02 // KEY_METRICS</div>
          <div className="section-content">
            <div className="metric-row">
              <span className="metric-key">PRIMARY METRIC</span>
              <span className="metric-val">85.0%</span>
            </div>
            <div className="metric-row">
              <span className="metric-key">SECONDARY METRIC</span>
              <span className="metric-val">42.5</span>
            </div>
            <div className="metric-row">
              <span className="metric-key">TERTIARY METRIC</span>
              <span className="metric-val positive">+12.3%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
