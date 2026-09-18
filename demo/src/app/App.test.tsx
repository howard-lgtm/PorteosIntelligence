import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { App } from './App'

describe('App', () => {
  it('should render Porteos Intelligence UI', () => {
    render(<App />)
    expect(screen.getByText(/PORTEOSINTELLIGENCE/i)).toBeInTheDocument()
  })

  it('should render command center by default', () => {
    render(<App />)
    expect(screen.getByText(/TOTAL PORTFOLIO VALUE/i)).toBeInTheDocument()
  })

  it('should render navigation items', () => {
    render(<App />)
    expect(screen.getByText(/CMD CENTER/i)).toBeInTheDocument()
    expect(screen.getByText(/REAL ESTATE/i)).toBeInTheDocument()
    expect(screen.getByText(/HOSPITALITY/i)).toBeInTheDocument()
  })

  it('should render inspector tabs', () => {
    render(<App />)
    expect(screen.getByText(/LATEST/i)).toBeInTheDocument()
    expect(screen.getByText(/INTEL/i)).toBeInTheDocument()
  })
})
