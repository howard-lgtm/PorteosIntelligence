import type { DemoState } from '../types/demo'

export const initialDemoState: DemoState = {
  phase: 'prepare',
  selectedProperty: null,
  importedFiles: [],
  processingProgress: null,
  activeProfile: 'real-estate',
  evaluationResult: null,
  reportState: {
    generated: false,
    format: null,
  },
  isComplete: false,
}
