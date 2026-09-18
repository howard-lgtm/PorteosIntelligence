import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { App } from './App'

describe('App', () => {
  it('should render scaffold heading', () => {
    render(<App />)
    expect(screen.getByText('Porteos Intelligence')).toBeInTheDocument()
  })

  it('should render reset button', () => {
    render(<App />)
    expect(screen.getByRole('button', { name: /reset demo state/i })).toBeInTheDocument()
  })

  it('should display initial phase as prepare', () => {
    render(<App />)
    expect(screen.getByText('prepare')).toBeInTheDocument()
  })

  it('should display implementation pending message', () => {
    render(<App />)
    expect(screen.getByText(/UI implementation is pending/i)).toBeInTheDocument()
  })
})
