import type { DemoState, DemoAction } from '../types/demo'
import { initialDemoState } from './demoState'

export function demoReducer(state: DemoState, action: DemoAction): DemoState {
  switch (action.type) {
    case 'START_DEMO':
      return {
        ...state,
        phase: 'import',
      }

    case 'SELECT_PROPERTY':
      return {
        ...state,
        selectedProperty: action.payload,
      }

    case 'ADD_FILE':
      return {
        ...state,
        importedFiles: [...state.importedFiles, action.payload],
      }

    case 'START_PROCESSING':
      return {
        ...state,
        phase: 'processing',
        processingProgress: {
          current: 0,
          total: 100,
          message: 'Initializing analysis...',
        },
      }

    case 'UPDATE_PROGRESS':
      return {
        ...state,
        processingProgress: action.payload,
      }

    case 'COMPLETE_PROCESSING':
      return {
        ...state,
        phase: 'evaluate',
        processingProgress: null,
        evaluationResult: action.payload,
      }

    case 'SWITCH_PROFILE':
      return {
        ...state,
        activeProfile: action.payload,
      }

    case 'GENERATE_REPORT':
      return {
        ...state,
        phase: 'report',
        reportState: {
          generated: true,
          format: action.payload,
        },
      }

    case 'COMPLETE_DEMO':
      return {
        ...state,
        phase: 'complete',
        isComplete: true,
      }

    case 'RESET_DEMO':
      return initialDemoState

    default:
      return state
  }
}
