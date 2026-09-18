import type { Deal } from '../types/demo'

export const DEALS: Deal[] = [
  {
    id: 'deal-001',
    name: 'Marina Bay Resort',
    location: 'San Diego, CA',
    type: 'Hospitality',
    value: 12300000,
    score: 80,
    grade: 'B',
    status: 'viable',
  },
  {
    id: 'deal-002',
    name: 'Riverside Plaza',
    location: 'Portland, OR',
    type: 'Commercial Mixed-Use',
    value: 8500000,
    score: 87,
    grade: 'A',
    status: 'viable',
  },
]

export const PORTFOLIO_TOTAL = 22000000
export const AVG_PORTFOLIO_SCORE = 87
