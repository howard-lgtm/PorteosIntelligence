import { test, expect } from '@playwright/test'

test.describe('Porteos Intelligence Demo', () => {
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

  test('should render Porteos UI', async ({ page }) => {
    await page.goto('/')
    const header = page.getByText(/PORTEOSINTELLIGENCE/i)
    await expect(header).toBeVisible()
  })

  test('should not show scaffold text', async ({ page }) => {
    await page.goto('/')
    const scaffoldText = page.getByText(/Usability Demo Scaffold/i)
    await expect(scaffoldText).not.toBeVisible()
  })

  test('should have functional navigation', async ({ page }) => {
    await page.goto('/')
    const cmdCenterBtn = page.getByRole('button', { name: /CMD CENTER/i })
    await expect(cmdCenterBtn).toBeVisible()
    await cmdCenterBtn.click()
  })

  test('should display command center by default', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByText(/TOTAL PORTFOLIO VALUE/i)).toBeVisible()
  })
})
