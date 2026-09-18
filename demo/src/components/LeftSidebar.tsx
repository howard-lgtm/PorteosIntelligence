import { type ViewMode, type Deal } from '../types/demo'
import './LeftSidebar.css'

interface Props {
  viewMode: ViewMode
  selectedDealId: string | null
  deals: Deal[]
  searchQuery: string
  statusFilter: string
  onViewChange: (view: ViewMode) => void
  onDealSelect: (id: string) => void
  onSearchChange: (query: string) => void
  onStatusFilter: (status: string) => void
  onNewDeal: () => void
}

export function LeftSidebar({
  viewMode,
  selectedDealId,
  deals,
  searchQuery,
  statusFilter,
  onViewChange,
  onDealSelect,
  onSearchChange,
  onStatusFilter,
  onNewDeal,
}: Props) {
  const navItems: { id: ViewMode; label: string; indicator: string }[] = [
    { id: 'command-center', label: 'CMD CENTER', indicator: '' },
    { id: 'real-estate', label: 'REAL ESTATE', indicator: '[ A ]' },
    { id: 'hospitality', label: 'HOSPITALITY', indicator: '[ A ]' },
    { id: 'design', label: 'DESIGN', indicator: '[ A ]' },
    { id: 'circular', label: 'CIRCULAR', indicator: '[ A ]' },
    { id: 'global-intel', label: 'GLOBAL INTELLIGENCE', indicator: '' },
  ]

  const statusFilters = ['ALL', 'PIPELINE', 'REVIEW', 'VIABLE', 'REJECTED']

  const filteredDeals = deals.filter((d) => {
    const matchesSearch = d.name.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesStatus =
      statusFilter === 'ALL' || d.status.toUpperCase() === statusFilter
    return matchesSearch && matchesStatus
  })

  return (
    <aside className="left-sidebar">
      {/* Wordmark */}
      <div className="porteos-header">
        <span className="header-icon">[ * ]</span>
        <span className="header-title">PORTEOS@SYSTEM</span>
        <span className="header-icon">[ * ]</span>
      </div>

      {/* Profile Nav */}
      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <button
            key={item.id}
            className={`nav-item ${viewMode === item.id ? 'active' : ''}`}
            onClick={() => { onViewChange(item.id) }}
          >
            <span className="nav-label">{item.label}</span>
            {item.indicator && (
              <span className="nav-indicator">{item.indicator}</span>
            )}
          </button>
        ))}
      </nav>

      {/* Action Buttons */}
      <div className="nav-actions">
        <button className="nav-action-btn">[ FILTER ]</button>
        <button className="nav-action-btn">[ TRIAGE ]</button>
        <button className="nav-action-btn">[ CMP ]</button>
      </div>

      {/* Status Filter Tabs */}
      <div className="status-tabs">
        {statusFilters.map((s) => (
          <button
            key={s}
            className={`status-tab ${statusFilter === s ? 'active' : ''}`}
            onClick={() => { onStatusFilter(s) }}
          >
            {s}
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="search-row">
        <span className="search-prompt">/</span>
        <input
          type="text"
          className="search-input"
          placeholder="search deals..."
          value={searchQuery}
          onChange={(e) => { onSearchChange(e.target.value) }}
        />
      </div>

      {/* Deals List */}
      <div className="deals-list">
        {filteredDeals.map((deal) => (
          <button
            key={deal.id}
            className={`deal-item ${selectedDealId === deal.id ? 'selected' : ''}`}
            onClick={() => { onDealSelect(deal.id) }}
          >
            <div className="deal-name">{deal.name}</div>
            <div className="deal-meta">
              <span className="deal-value">
                ${(deal.value / 1000000).toFixed(1)}M
              </span>
              <span
                className="deal-score"
                style={{ color: deal.score >= 80 ? 'var(--color-status-go)' : deal.score >= 50 ? 'var(--color-status-warn)' : 'var(--color-status-critical)' }}
              >
                {deal.score.toFixed(1)}%
              </span>
            </div>
          </button>
        ))}
      </div>

      {/* Bottom Command Bar */}
      <div className="sidebar-footer">
        <div className="footer-actions">
          <button className="btn-footer-sm">./BULK_EXPORT…</button>
          <button className="btn-footer-sm">./BULK_DELETE…</button>
        </div>
        <button className="btn-footer-sm">./IMPORT_DEALS</button>
        <button className="btn-new-deal" onClick={onNewDeal}>
          [ ./NEW_DEAL ]
        </button>
        <div className="cli-prompt">porteos@system ~ %</div>
      </div>
    </aside>
  )
}
