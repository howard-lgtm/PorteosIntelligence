import { type ViewMode, type Deal } from '../types/demo'
import './LeftSidebar.css'

interface Props {
  viewMode: ViewMode
  selectedDealId: string | null
  deals: Deal[]
  searchQuery: string
  onViewChange: (view: ViewMode) => void
  onDealSelect: (id: string) => void
  onSearchChange: (query: string) => void
  onNewDeal: () => void
}

export function LeftSidebar({
  viewMode,
  selectedDealId,
  deals,
  searchQuery,
  onViewChange,
  onDealSelect,
  onSearchChange,
  onNewDeal,
}: Props) {
  const navItems: { id: ViewMode; label: string }[] = [
    { id: 'command-center', label: 'CMD CENTER' },
    { id: 'real-estate', label: 'REAL ESTATE' },
    { id: 'hospitality', label: 'HOSPITALITY' },
    { id: 'design', label: 'DESIGN' },
    { id: 'circular', label: 'CIRCULAR' },
    { id: 'global-intel', label: 'GLOBAL INTELLIGENCE' },
  ]

  return (
    <aside className="left-sidebar">
      <div className="sidebar-section">
        <div className="porteos-header">PORTEOSINTELLIGENCE</div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <button
            key={item.id}
            className={`nav-item ${viewMode === item.id ? 'active' : ''}`}
            onClick={() => {
              onViewChange(item.id)
            }}
          >
            {item.label}
          </button>
        ))}
      </nav>

      <div className="sidebar-section">
        <div className="section-header">
          <span>ALL</span>
          <button className="btn-icon" onClick={onNewDeal}>
            [ + ]
          </button>
        </div>

        <input
          type="text"
          className="search-input"
          placeholder="MARKET INTEL..."
          value={searchQuery}
          onChange={(e) => {
            onSearchChange(e.target.value)
          }}
        />
      </div>

      <div className="deals-list">
        {deals.map((deal) => (
          <button
            key={deal.id}
            className={`deal-item ${selectedDealId === deal.id ? 'selected' : ''}`}
            onClick={() => {
              onDealSelect(deal.id)
            }}
          >
            <div className="deal-name">{deal.name}</div>
            <div className="deal-value">${(deal.value / 1000000).toFixed(1)}M</div>
          </button>
        ))}
      </div>

      <div className="sidebar-footer">
        <button className="btn-export">[ /BULK_EXPORT… ]</button>
        <button className="btn-deals">[ /IMPORT_DEALS ]</button>
      </div>
    </aside>
  )
}
