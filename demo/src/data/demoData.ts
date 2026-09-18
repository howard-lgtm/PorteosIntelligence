import type { PropertyData, EvaluationResult } from '../types/demo'

export const DEMO_PROPERTIES: PropertyData[] = [
  {
    id: 'prop-001',
    name: 'Riverside Plaza',
    location: 'Portland, OR',
    type: 'Commercial Mixed-Use',
    value: 8500000,
  },
  {
    id: 'prop-002',
    name: 'Marina Heights Hotel',
    location: 'San Diego, CA',
    type: 'Hospitality',
    value: 12300000,
  },
  {
    id: 'prop-003',
    name: 'Greenfield Commons',
    location: 'Austin, TX',
    type: 'Residential Multi-family',
    value: 6200000,
  },
]

export const DEMO_EVALUATION: EvaluationResult = {
  score: 87,
  grade: 'B+',
  verdict: 'STRONG',
  signals: {
    location: 92,
    timing: 78,
    cashFlow: 85,
    risk: 81,
    esg: 89,
  },
}
