import type { ViewMode } from '../types/demo'
import './ProfileDashboard.css'

interface Props {
  profile: ViewMode
  dealName?: string
  dealScore?: number
  dealGrade?: string
}

export function ProfileDashboard({ profile, dealName, dealScore = 80, dealGrade = 'B' }: Props) {
  const titles: Record<ViewMode, string> = {
    'command-center': 'Command Center',
    'real-estate': 'Real Estate Dashboard',
    hospitality: 'Hospitality Dashboard',
    design: 'Design Dashboard',
    circular: 'Circular Economy Dashboard',
    'global-intel': 'Global Intelligence',
  }

  const colors: Record<ViewMode, string> = {
    'command-center': '#ff6b35',
    'real-estate': '#4895ef',
    hospitality: '#00d4aa',
    design: '#9d4edd',
    circular: '#06d6a0',
    'global-intel': '#00b4d8',
  }

  const accentColor = colors[profile]

  return (
    <div className="profile-dashboard">
      {dealName && (
        <div className="pd-hero">
          <div className="score-display">
            <div className="score-number">{dealScore}</div>
            <div className="score-max">/ 100</div>
          </div>
          <div className="deal-header">
            <div className="deal-name">{dealName}</div>
            <div className="grade-box" style={{ borderColor: accentColor, color: accentColor }}>
              {dealGrade}
            </div>
          </div>
        </div>
      )}

      <div className="dashboard-header" style={{ color: accentColor }}>
        {titles[profile]}
      </div>

      <div className="pd-section">
        <div className="pd-section-title">porteoSSystem → 01 // MARKET_TRENDS</div>
        <div className="pd-metrics">
          <div className="pd-metric">
            <div className="pd-metric-label">LOCATION SCORE</div>
            <div className="pd-metric-value green">+22 %</div>
          </div>
          <div className="pd-metric">
            <div className="pd-metric-label">MARKET TIMING</div>
            <div className="pd-metric-value">–</div>
          </div>
          <div className="pd-metric">
            <div className="pd-metric-label">CASH FLOW</div>
            <div className="pd-metric-value green">+ 34%</div>
          </div>
          <div className="pd-metric">
            <div className="pd-metric-label">RISK MEASURE</div>
            <div className="pd-metric-value orange">↑ HIGH</div>
          </div>
        </div>
      </div>

      <div className="pd-section">
        <div className="pd-section-title">porteoSSystem → 02 // KEY_METRICS</div>
        <div className="pd-metrics-grid">
          <div className="pd-metric-card">
            <div className="pd-card-value">85.0%</div>
            <div className="pd-card-label">PRIMARY METRIC</div>
          </div>
          <div className="pd-metric-card">
            <div className="pd-card-value">42.5</div>
            <div className="pd-card-label">SECONDARY METRIC</div>
          </div>
          <div className="pd-metric-card">
            <div className="pd-card-value green">+12.3%</div>
            <div className="pd-card-label">TERTIARY METRIC</div>
          </div>
        </div>
      </div>
    </div>
  )
}
