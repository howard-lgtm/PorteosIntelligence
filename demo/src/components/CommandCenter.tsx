import { PORTFOLIO_TOTAL, AVG_PORTFOLIO_SCORE, DEALS } from '../data/demoData'
import './CommandCenter.css'

export function CommandCenter() {
  return (
    <div className="command-center">
      <div className="cc-hero">
        <div className="hero-label">TOTAL PORTFOLIO VALUE</div>
        <div className="hero-value">€{(PORTFOLIO_TOTAL / 1000000).toFixed(0)} 000 000</div>
      </div>

      <div className="cc-cards">
        <div className="cc-card">
          <div className="card-value-large">{DEALS.length}</div>
          <div className="card-label-large">TOTAL DEALS</div>
          <div className="card-sublabel">IN PORTFOLIO</div>
        </div>

        <div className="cc-card">
          <div className="card-value-large">{AVG_PORTFOLIO_SCORE}</div>
          <div className="card-label-large">AVG PORTEOS SCORE</div>
          <div className="card-grade">GRADE A</div>
        </div>
      </div>

      <div className="cc-section">
        <div className="section-title">porteoSSystem → 01 // MARKET_TRENDS</div>
        <div className="metrics-grid">
          <div className="metric-card">
            <div className="metric-value green">+8.2 %</div>
            <div className="metric-label">REAL FIRM YOY</div>
          </div>
          <div className="metric-card">
            <div className="metric-value">€ 42M</div>
            <div className="metric-label">AVG DEAL SIZE</div>
          </div>
          <div className="metric-card">
            <div className="metric-value orange">+ 346bps</div>
            <div className="metric-label">DEAL WISE</div>
          </div>
          <div className="metric-card">
            <div className="metric-value yellow">↑ HIGH</div>
            <div className="metric-label">ADC MEASURE</div>
          </div>
        </div>
      </div>

      <div className="cc-section">
        <div className="section-title">porteoSSystem → 02 // REAL_PIPELINE</div>
        <div className="pipeline-grid">
          <div className="pipeline-card">
            <div className="pipeline-number">1</div>
            <div className="pipeline-label">PIPELINE</div>
          </div>
          <div className="pipeline-card">
            <div className="pipeline-number">0</div>
            <div className="pipeline-label">VIABLE</div>
          </div>
          <div className="pipeline-card">
            <div className="pipeline-number">0</div>
            <div className="pipeline-label">REJECTED</div>
          </div>
        </div>
      </div>

      <div className="cc-section">
        <div className="section-title">
          porteoSSystem → 02 // PROFILE_HEALTH [avg score per profile]
        </div>
        <div className="profile-health">
          <div className="health-row">
            <div className="health-label">REAL ESTATE</div>
            <div className="health-bar-container">
              <div className="health-bar" style={{ width: '0%', backgroundColor: '#ef476f' }} />
            </div>
            <div className="health-value red">0.0</div>
          </div>
          <div className="health-row">
            <div className="health-label">HOSPITALITY</div>
            <div className="health-bar-container">
              <div className="health-bar" style={{ width: '96.4%', backgroundColor: '#06d6a0' }} />
            </div>
            <div className="health-value green">96.4</div>
          </div>
          <div className="health-row">
            <div className="health-label">DESIGN</div>
            <div className="health-bar-container">
              <div className="health-bar" style={{ width: '59%', backgroundColor: '#9d4edd' }} />
            </div>
            <div className="health-value orange">59.0</div>
          </div>
          <div className="health-row">
            <div className="health-label">CIRCULAR</div>
            <div className="health-bar-container">
              <div className="health-bar" style={{ width: '48%', backgroundColor: '#ef476f' }} />
            </div>
            <div className="health-value red">48.0</div>
          </div>
        </div>
      </div>

      <div className="cc-section">
        <div className="section-title">porteoSSystem → 03 // PROFILE_DISTRIBUTION</div>
        <div className="distribution">
          <div className="dist-row">
            <div className="dist-label">REAL ESTATE</div>
            <div className="dist-bar-container">
              <div className="dist-bar" style={{ width: '27.5%', backgroundColor: '#ff6b35' }} />
            </div>
            <div className="dist-value">27,5%</div>
          </div>
          <div className="dist-row">
            <div className="dist-label">HOSPITALITY</div>
            <div className="dist-bar-container">
              <div className="dist-bar" style={{ width: '35%', backgroundColor: '#00d4aa' }} />
            </div>
            <div className="dist-value">35,0%</div>
          </div>
        </div>
      </div>
    </div>
  )
}
