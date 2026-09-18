import './TopHeaderBar.css'
import type { ViewMode } from '../types/demo'

interface Props {
  viewMode: ViewMode
  selectedDealName?: string
}

const VIEW_PATHS: Record<ViewMode, string> = {
  'command-center': './dashboard --portfolio=overview --profiles=6',
  'real-estate': './profile --type=real_estate',
  hospitality: './profile --type=hospitality',
  design: './profile --type=design',
  circular: './profile --type=circular_economy',
  'global-intel': './global_intelligence --map=true',
}

export function TopHeaderBar({ viewMode, selectedDealName }: Props) {
  const path = VIEW_PATHS[viewMode]

  return (
    <div className="top-header-bar">
      <div className="header-left">
        <span className="header-system">porteos@system ~ %</span>
        <span className="header-path">{path}</span>
        {selectedDealName && (
          <span className="header-asset">--asset=&ldquo;{selectedDealName}&rdquo;</span>
        )}
      </div>
      <div className="header-right">
        <span className="header-http go">● HTTP:0 200</span>
        <span className="header-bracket">[ ! ]</span>
        <span className="header-bracket">[ ? ]</span>
      </div>
    </div>
  )
}
