import { test, expect } from '@playwright/test'

test.describe('Demo Scaffold Smoke Test', () => {
  test('should load without console errors', async ({ page }) => {
    const consoleErrors: string[] = []
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text())
      }
    })

    await page.goto('/')
    await page.waitForLoadState('networkidle')

    expect(consoleErrors).toHaveLength(0)
  })

  test('should render scaffold heading', async ({ page }) => {
    await page.goto('/')
    const heading = page.getByRole('heading', { name: /porteos intelligence/i })
    await expect(heading).toBeVisible()
  })

  test('should have functional reset button', async ({ page }) => {
    await page.goto('/')
    const resetButton = page.getByRole('button', { name: /reset demo state/i })
    await expect(resetButton).toBeVisible()
    await expect(resetButton).toBeEnabled()
    await resetButton.click()
  })

  test('should display current phase', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByText('prepare')).toBeVisible()
  })

  test('should be keyboard navigable', async ({ page }) => {
    await page.goto('/')
    await page.keyboard.press('Tab')
    const resetButton = page.getByRole('button', { name: /reset demo state/i })
    await expect(resetButton).toBeFocused()
  })
})
