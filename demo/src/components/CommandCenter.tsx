import { PORTFOLIO_TOTAL, AVG_PORTFOLIO_SCORE, DEALS } from '../data/demoData'
import './CommandCenter.css'

const CLI = 'porteos@system ~ %'

export function CommandCenter() {
  return (
    <div className="command-center">
      {/* CLI breadcrumb */}
      <div className="cli-breadcrumb">
        <span className="cli-path">{CLI} ./dashboard --portfolio=overview --profiles=6</span>
      </div>

      {/* Hero Row: Portfolio Value | Deals + Score */}
      <div className="cc-hero-row">
        <div className="cc-hero-box cc-hero-main">
          <div className="hero-label">TOTAL PORTFOLIO VALUE</div>
          <div className="hero-value">€{(PORTFOLIO_TOTAL / 1000000).toFixed(0)}&nbsp;000&nbsp;000</div>
        </div>
        <div className="cc-hero-box cc-hero-stats">
          <div className="cc-hero-stat">
            <div className="hero-stat-number">{DEALS.length}</div>
            <div className="hero-stat-label">TOTAL DEALS</div>
            <div className="hero-stat-sub">IN PORTFOLIO</div>
          </div>
          <div className="cc-hero-divider" />
          <div className="cc-hero-stat cc-hero-stat-right">
            <div className="hero-stat-number">{AVG_PORTFOLIO_SCORE}</div>
            <div className="hero-stat-label">AVG PORTEOS SCORE</div>
            <div className="hero-stat-grade">GRADE A</div>
          </div>
        </div>
      </div>

      {/* 01 // MARKET_TRENDS */}
      <div className="terminal-block">
        <div className="terminal-block-header">
          <span className="cli-dim">{CLI}</span>
          <span className="cli-cmd"> MKT // MARKET_TRENDS</span>
        </div>
        <div className="metrics-grid-4">
          <div className="metric-cell">
            <div className="metric-cell-value go">+8.2 %</div>
            <div className="metric-cell-label">DEAL FLOW YOY</div>
          </div>
          <div className="metric-cell">
            <div className="metric-cell-value">€ 42M</div>
            <div className="metric-cell-label">AVG DEAL SIZE</div>
          </div>
          <div className="metric-cell">
            <div className="metric-cell-value warn">↑ 340bps</div>
            <div className="metric-cell-label">BASE RATE</div>
          </div>
          <div className="metric-cell">
            <div className="metric-cell-value warn">WARM</div>
            <div className="metric-cell-label">PORTFOLIO HEAT</div>
          </div>
        </div>
      </div>

      {/* 01 // DEAL_PIPELINE */}
      <div className="terminal-block">
        <div className="terminal-block-header">
          <span className="cli-dim">{CLI}</span>
          <span className="cli-cmd"> 01 // DEAL_PIPELINE</span>
        </div>
        <div className="pipeline-grid">
          <div className="pipeline-cell">
            <div className="pipeline-number">1</div>
            <div className="pipeline-label">PIPELINE</div>
          </div>
          <div className="pipeline-cell">
            <div className="pipeline-number">1</div>
            <div className="pipeline-label">UNDER REVIEW</div>
          </div>
          <div className="pipeline-cell">
            <div className="pipeline-number">0</div>
            <div className="pipeline-label">VIABLE</div>
          </div>
          <div className="pipeline-cell">
            <div className="pipeline-number">0</div>
            <div className="pipeline-label">ACQUIRED</div>
          </div>
          <div className="pipeline-cell">
            <div className="pipeline-number">0</div>
            <div className="pipeline-label">REJECTED</div>
          </div>
        </div>
      </div>

      {/* 02 // PROFILE_HEALTH */}
      <div className="terminal-block">
        <div className="terminal-block-header">
          <span className="cli-dim">{CLI}</span>
          <span className="cli-cmd"> 02 // PROFILE_HEALTH</span>
          <span className="cli-meta"> [avg score per profile]</span>
        </div>
        <div className="profile-health">
          {[
            { label: 'REAL ESTATE', score: 0, color: 'var(--color-accent-rust)', numColor: 'var(--color-status-critical)' },
            { label: 'HOSPITALITY', score: 96.4, color: 'var(--color-accent-hospitality)', numColor: 'var(--color-status-go)' },
            { label: 'DESIGN', score: 59, color: 'var(--color-accent-design)', numColor: 'var(--color-status-warn)' },
            { label: 'CIRCULAR', score: 48, color: 'var(--color-accent-circular)', numColor: 'var(--color-status-critical)' },
          ].map(({ label, score, color, numColor }) => (
            <div className="health-row" key={label}>
              <div className="health-label">{label}</div>
              <div className="health-sub">
                <span className="health-deals">2 DEALS · /100</span>
              </div>
              <div className="health-bar-track">
                <div className="health-bar-fill" style={{ width: `${score}%`, backgroundColor: color }} />
              </div>
              <div className="health-value" style={{ color: numColor }}>{score.toFixed(1)}</div>
            </div>
          ))}
        </div>
      </div>

      {/* 03 // PROFILE_DISTRIBUTION */}
      <div className="terminal-block">
        <div className="terminal-block-header">
          <span className="cli-dim">{CLI}</span>
          <span className="cli-cmd"> 03 // PROFILE_DISTRIBUTION</span>
        </div>
        <div className="distribution">
          {[
            { label: 'REAL ESTATE', pct: 27.5, color: 'var(--color-accent-rust)' },
            { label: 'HOSPITALITY', pct: 35.0, color: 'var(--color-accent-hospitality)' },
          ].map(({ label, pct, color }) => (
            <div className="dist-row" key={label}>
              <div className="dist-label">{label}</div>
              <div className="dist-bar-track">
                <div className="dist-bar-fill" style={{ width: `${pct}%`, backgroundColor: color }} />
              </div>
              <div className="dist-value" style={{ color }}>{pct.toFixed(1).replace('.', ',')}%</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
