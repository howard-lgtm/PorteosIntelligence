import { PORTFOLIO_TOTAL, AVG_PORTFOLIO_SCORE, DEALS } from '../data/demoData'
import './CommandCenter.css'

export function CommandCenter() {
  return (
    <div className="command-center">
      <div className="cc-header">
        <div className="cc-title">TOTAL PORTFOLIO VALUE</div>
        <div className="cc-value">€{(PORTFOLIO_TOTAL / 1000000).toFixed(0)} 000 000</div>
      </div>

      <div className="cc-grid">
        <div className="cc-card">
          <div className="card-label">TOTAL DEALS</div>
          <div className="card-value">{DEALS.length}</div>
          <div className="card-sublabel">IN PORTFOLIO</div>
        </div>

        <div className="cc-card">
          <div className="card-label">AVG PORTEOS SCORE</div>
          <div className="card-value">{AVG_PORTFOLIO_SCORE}</div>
          <div className="card-grade">GRADE A</div>
        </div>
      </div>

      <div className="section">
        <div className="section-header">porteoSSystem → 01 // MARKET_TRENDS</div>
        <div className="metrics-grid">
          <div className="metric">
            <div className="metric-label">REAL FIRM YOY</div>
            <div className="metric-value positive">+8.2 %</div>
          </div>
          <div className="metric">
            <div className="metric-label">AVG DEAL SIZE</div>
            <div className="metric-value">€ 42M</div>
          </div>
          <div className="metric">
            <div className="metric-label">DEAL WISE</div>
            <div className="metric-value positive">+ 346bps</div>
          </div>
          <div className="metric">
            <div className="metric-label">ADC MEASURE</div>
            <div className="metric-value warning">↑ HIGH</div>
          </div>
        </div>
      </div>

      <div className="section">
        <div className="section-header">porteoSSystem → 02 // REAL_PIPELINE</div>
        <div className="pipeline-grid">
          <div className="pipeline-col">
            <div className="pipeline-value">1</div>
            <div className="pipeline-label">PIPELINE</div>
          </div>
          <div className="pipeline-col">
            <div className="pipeline-value">0</div>
            <div className="pipeline-label">VIABLE</div>
          </div>
          <div className="pipeline-col">
            <div className="pipeline-value">0</div>
            <div className="pipeline-label">REJECTED</div>
          </div>
        </div>
      </div>

      <div className="section">
        <div className="section-header">
          porteoSSystem → 03 // PROFILE_HEALTH [avg score per profile]
        </div>
        <div className="profile-bars">
          <div className="profile-bar">
            <div className="bar-label">REAL ESTATE</div>
            <div className="bar-container">
              <div
                className="bar-fill"
                style={{ width: '0%', backgroundColor: 'var(--color-blue)' }}
              />
            </div>
            <div className="bar-value">0.0</div>
          </div>
          <div className="profile-bar">
            <div className="bar-label">HOSPITALITY</div>
            <div className="bar-container">
              <div
                className="bar-fill"
                style={{ width: '96.4%', backgroundColor: 'var(--color-teal)' }}
              />
            </div>
            <div className="bar-value positive">96.4</div>
          </div>
          <div className="profile-bar">
            <div className="bar-label">DESIGN</div>
            <div className="bar-container">
              <div
                className="bar-fill"
                style={{ width: '59%', backgroundColor: 'var(--color-purple)' }}
              />
            </div>
            <div className="bar-value warning">59.0</div>
          </div>
          <div className="profile-bar">
            <div className="bar-label">CIRCULAR</div>
            <div className="bar-container">
              <div
                className="bar-fill"
                style={{ width: '48%', backgroundColor: 'var(--color-green)' }}
              />
            </div>
            <div className="bar-value warning">48.0</div>
          </div>
        </div>
      </div>

      <div className="section">
        <div className="section-header">porteoSSystem → 03 // PROFILE_DISTRIBUTION</div>
        <div className="distribution-bars">
          <div className="dist-bar">
            <div className="dist-label">REAL ESTATE</div>
            <div className="dist-container">
              <div
                className="dist-fill"
                style={{ width: '27.5%', backgroundColor: 'var(--color-blue)' }}
              />
            </div>
            <div className="dist-value">27,5%</div>
          </div>
          <div className="dist-bar">
            <div className="dist-label">HOSPITALITY</div>
            <div className="dist-container">
              <div
                className="dist-fill"
                style={{ width: '35%', backgroundColor: 'var(--color-teal)' }}
              />
            </div>
            <div className="dist-value">35,0%</div>
          </div>
        </div>
      </div>
    </div>
  )
}
