import type { ViewMode } from '../types/demo'
import './ProfileDashboard.css'

interface Props {
  profile: ViewMode
  dealName?: string
  dealScore?: number
  dealGrade?: string
}

const CLI = 'porteos@system ~ %'

const PROFILE_CONFIG: Record<ViewMode, {
  label: string
  cmd: string
  accent: string
  modules: { cmd: string; metrics: { label: string; value: string; state?: 'go' | 'warn' | 'critical' }[] }[]
}> = {
  'command-center': {
    label: 'CMD_CENTER',
    cmd: './dashboard',
    accent: 'var(--color-accent-cmd-center)',
    modules: [],
  },
  'real-estate': {
    label: 'REAL_ESTATE',
    cmd: './profile --type=real_estate',
    accent: 'var(--color-accent-rust)',
    modules: [
      {
        cmd: '01 // MARKET_TRENDS',
        metrics: [
          { label: 'DEAL FLOW YOY', value: '+8.2 %', state: 'go' },
          { label: 'AVG DEAL SIZE', value: '€ 42M' },
          { label: 'BASE RATE', value: '↑ 340bps', state: 'warn' },
          { label: 'MARKET HEAT', value: 'WARM', state: 'warn' },
        ],
      },
      {
        cmd: '02 // DEAL_METRICS',
        metrics: [
          { label: 'CAP RATE', value: '5.8 %', state: 'go' },
          { label: 'LTV RATIO', value: '68.0 %' },
          { label: 'DSCR', value: '1.34', state: 'go' },
          { label: 'NOI', value: '€ 2.1M' },
        ],
      },
      {
        cmd: '03 // LOCATION_ANALYSIS',
        metrics: [
          { label: 'WALK SCORE', value: '92', state: 'go' },
          { label: 'TRANSIT SCORE', value: '78', state: 'go' },
          { label: 'POP GROWTH', value: '+1.8 %', state: 'go' },
          { label: 'VACANCY RATE', value: '4.2 %', state: 'go' },
        ],
      },
    ],
  },
  hospitality: {
    label: 'HOSPITALITY',
    cmd: './profile --type=hospitality',
    accent: 'var(--color-accent-hospitality)',
    modules: [
      {
        cmd: '01 // MARKET_TRENDS',
        metrics: [
          { label: 'REVPAR', value: '€ 187', state: 'go' },
          { label: 'ADR', value: '€ 224' },
          { label: 'OCCUPANCY', value: '83.4 %', state: 'go' },
          { label: 'MARKET HEAT', value: 'HOT', state: 'warn' },
        ],
      },
      {
        cmd: '02 // OPERATIONS',
        metrics: [
          { label: 'GOP MARGIN', value: '42.1 %', state: 'go' },
          { label: 'EBITDA', value: '€ 5.2M' },
          { label: 'ROOMS', value: '184' },
          { label: 'RATING', value: '4.7 / 5', state: 'go' },
        ],
      },
      {
        cmd: '03 // COMPETITIVE_SET',
        metrics: [
          { label: 'MKT SHARE', value: '18.2 %' },
          { label: 'REVPAR INDEX', value: '112.4', state: 'go' },
          { label: 'FAIR SHARE', value: '14.8 %' },
          { label: 'PENETRATION', value: '1.23', state: 'go' },
        ],
      },
    ],
  },
  design: {
    label: 'DESIGN',
    cmd: './profile --type=design',
    accent: 'var(--color-accent-design)',
    modules: [
      {
        cmd: '01 // CREATIVE_METRICS',
        metrics: [
          { label: 'BRAND SCORE', value: '8.4 / 10', state: 'go' },
          { label: 'NPS', value: '72', state: 'go' },
          { label: 'DESIGN RATE', value: '+22 %', state: 'go' },
          { label: 'IP VALUE', value: '€ 1.8M' },
        ],
      },
      {
        cmd: '02 // MARKET_POSITION',
        metrics: [
          { label: 'MKT SHARE', value: '12.4 %' },
          { label: 'GROWTH YOY', value: '+34 %', state: 'go' },
          { label: 'REVENUE', value: '€ 8.6M' },
          { label: 'MARGIN', value: '38.0 %', state: 'go' },
        ],
      },
    ],
  },
  circular: {
    label: 'CIRCULAR_ECONOMY',
    cmd: './profile --type=circular_economy',
    accent: 'var(--color-accent-circular)',
    modules: [
      {
        cmd: '01 // SUSTAINABILITY_METRICS',
        metrics: [
          { label: 'ESG SCORE', value: '74 / 100', state: 'go' },
          { label: 'CARBON KG/M²', value: '38.2', state: 'go' },
          { label: 'WASTE DIVERTED', value: '91.4 %', state: 'go' },
          { label: 'ENERGY EFF', value: 'A+', state: 'go' },
        ],
      },
      {
        cmd: '02 // CIRCULAR_FLOWS',
        metrics: [
          { label: 'RECYCLED INPUT', value: '68.0 %', state: 'go' },
          { label: 'REUSE RATE', value: '44.2 %' },
          { label: 'LIFETIME EXT', value: '+8 YRS' },
          { label: 'CERT LEVEL', value: 'GOLD', state: 'go' },
        ],
      },
    ],
  },
  'global-intel': {
    label: 'GLOBAL_INTELLIGENCE',
    cmd: './global_intelligence --map=true',
    accent: 'var(--color-accent-circular)',
    modules: [
      {
        cmd: '01 // MACRO_INDICATORS',
        metrics: [
          { label: 'GLOBAL GDP', value: '+2.8 %', state: 'go' },
          { label: 'INFLATION', value: '3.1 %', state: 'warn' },
          { label: 'BASE RATE', value: '4.0 %', state: 'warn' },
          { label: 'CREDIT SPREAD', value: '185bps' },
        ],
      },
      {
        cmd: '02 // REGIONAL_OVERVIEW',
        metrics: [
          { label: 'EU SENTIMENT', value: 'STABLE' },
          { label: 'US SENTIMENT', value: 'POSITIVE', state: 'go' },
          { label: 'APAC OUTLOOK', value: 'WATCH', state: 'warn' },
          { label: 'RISK INDEX', value: '42 / 100' },
        ],
      },
    ],
  },
}

export function ProfileDashboard({ profile, dealName, dealScore, dealGrade }: Props) {
  const config = PROFILE_CONFIG[profile]

  return (
    <div className="profile-dashboard">
      {/* CLI Breadcrumb */}
      <div className="cli-breadcrumb">
        <span className="cli-path">{CLI} {config.cmd}</span>
        {dealName && (
          <span className="cli-asset">--asset=&ldquo;{dealName}&rdquo;</span>
        )}
      </div>

      {/* Score Hero (when a deal is selected) */}
      {dealName && dealScore !== undefined && (
        <div className="pd-hero-row">
          <div className="pd-score-box">
            <div className="pd-score-number" style={{ color: config.accent }}>
              {dealScore}
            </div>
            <div className="pd-score-label">PORTEOS SCORE</div>
            {dealGrade && (
              <div className="pd-score-grade" style={{ color: config.accent }}>
                GRADE {dealGrade}
              </div>
            )}
          </div>
          <div className="pd-deal-info">
            <div className="pd-deal-name">{dealName}</div>
            <div className="pd-deal-profile" style={{ color: config.accent }}>
              {config.label}
            </div>
          </div>
        </div>
      )}

      {/* No deal selected state */}
      {!dealName && (
        <div className="pd-empty-state">
          <div className="pd-empty-prompt">
            {CLI} {config.cmd}
          </div>
          <div className="pd-empty-hint">
            // Select a deal from the nav panel to load its analysis
          </div>
        </div>
      )}

      {/* TerminalBlock Modules */}
      {config.modules.map((mod) => (
        <div className="terminal-block" key={mod.cmd}>
          <div className="terminal-block-header">
            <span className="cli-dim">{CLI}</span>
            <span className="cli-cmd" style={{ color: config.accent }}> {mod.cmd}</span>
          </div>
          <div className="metrics-grid-4">
            {mod.metrics.map((m) => (
              <div className="metric-cell" key={m.label}>
                <div className={`metric-cell-value ${m.state ?? ''}`}>
                  {m.value}
                </div>
                <div className="metric-cell-label">{m.label}</div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
