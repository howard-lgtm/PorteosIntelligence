import { describe, it, expect } from 'vitest'
import { demoReducer } from './demoReducer'
import { initialDemoState } from './demoState'
import type { DemoState } from '../types/demo'

describe('demoReducer', () => {
  it('should start demo and transition to import phase', () => {
    const state = demoReducer(initialDemoState, { type: 'START_DEMO' })
    expect(state.phase).toBe('import')
  })

  it('should handle property selection', () => {
    const property = {
      id: 'test-1',
      name: 'Test Property',
      location: 'Test Location',
      type: 'Test Type',
      value: 1000000,
    }
    const state = demoReducer(initialDemoState, {
      type: 'SELECT_PROPERTY',
      payload: property,
    })
    expect(state.selectedProperty).toEqual(property)
  })

  it('should transition through all phases correctly', () => {
    let state: DemoState = initialDemoState

    state = demoReducer(state, { type: 'START_DEMO' })
    expect(state.phase).toBe('import')

    state = demoReducer(state, { type: 'START_PROCESSING' })
    expect(state.phase).toBe('processing')

    state = demoReducer(state, {
      type: 'COMPLETE_PROCESSING',
      payload: {
        score: 85,
        grade: 'B',
        verdict: 'STRONG',
        signals: { location: 90, timing: 80, cashFlow: 85, risk: 80, esg: 85 },
      },
    })
    expect(state.phase).toBe('evaluate')

    state = demoReducer(state, { type: 'GENERATE_REPORT', payload: 'pdf' })
    expect(state.phase).toBe('report')

    state = demoReducer(state, { type: 'COMPLETE_DEMO' })
    expect(state.phase).toBe('complete')
    expect(state.isComplete).toBe(true)
  })

  it('should reset demo to initial state', () => {
    const modifiedState: DemoState = {
      ...initialDemoState,
      phase: 'evaluate',
      isComplete: true,
    }
    const state = demoReducer(modifiedState, { type: 'RESET_DEMO' })
    expect(state).toEqual(initialDemoState)
  })

  it('should handle profile switching', () => {
    const state = demoReducer(initialDemoState, {
      type: 'SWITCH_PROFILE',
      payload: 'hospitality',
    })
    expect(state.activeProfile).toBe('hospitality')
  })
})
