# hotTake.it Handoff Instructions

**Porteos Intelligence Usability Demo**  
**Target platform:** hotTake.it (single-file HTML upload)

---

## Prerequisites

- Node.js 20+ installed
- npm dependencies installed (`npm install`)
- All implementation complete and tested

---

## Build & Verification Steps

### 1. Run Full Check Suite

```bash
cd demo
npm run check
```

This script runs:

- Type checking (`tsc --noEmit`)
- Linting (`eslint`)
- Format validation (`prettier --check`)
- Unit tests (`vitest run`)
- Production build (`vite build`)
- E2E smoke tests (`playwright test`)

**All checks must pass** before proceeding.

---

### 2. Verify Build Output

```bash
ls -lh dist/index.html
```

**Expected result:**

- File exists: `dist/index.html`
- File size: ~100KB–500KB (depends on implementation complexity)
- Single file (no separate CSS/JS files in `dist/`)

**Verify self-containment:**

```bash
cat dist/index.html | grep -E '<link|<script src' | grep -v 'type="module"'
```

**Expected result:** No output (no external stylesheet or script references)

---

### 3. Test Locally via HTTP Server

```bash
npm run preview
```

Opens local server at `http://localhost:4173/`

**Manual verification checklist:**

- [ ] Page loads without errors (check browser console: `Cmd+Option+J`)
- [ ] All phases render correctly
- [ ] Reset button works
- [ ] Keyboard navigation works (Tab through interactive elements)
- [ ] No network requests after initial load (check Network tab in DevTools)

**To check network isolation:**

1. Open DevTools Network tab
2. Reload page
3. After initial `index.html` load, **disable network** (Offline mode in DevTools)
4. Interact with demo — all features should still work

---

### 4. Check for Secrets/Leaks

**CRITICAL:** Ensure no sensitive data is embedded.

```bash
# Check for common secret patterns
grep -r 'sk-' dist/
grep -r 'api_key' dist/
grep -r 'password' dist/
grep -r 'token' dist/
```

**Expected result:** No matches (or only harmless occurrences in comments)

**Also verify:**

- No `.env` file exists in `dist/`
- No source maps included (check for `.map` files)
- No real property data, client names, or deal specifics

---

### 5. Upload to hotTake.it

**Steps:**

1. Go to [hotTake.it](https://hottake.it) (or wherever the demo will be hosted)
2. Create new project or upload
3. Select `dist/index.html` as the file to upload
4. Publish demo

**Post-upload verification:**

- Open published URL
- Test full workflow (Prepare → Import → Processing → Evaluate → Report → Complete)
- Verify reset functionality
- Check browser console for errors
- Test on different browsers (Chrome, Safari, Firefox)
- Test on mobile viewport (responsive behavior)

---

## Troubleshooting

### Build Fails

**Symptom:** `npm run build` exits with errors

**Common causes:**

- TypeScript errors — fix types
- Missing dependencies — run `npm install`
- Linting errors — run `npm run format` then retry

---

### File Size Too Large

**Symptom:** `dist/index.html` > 5MB

**Possible causes:**

- Embedded images — ensure no large PNGs inlined
- Bloated dependencies — check `package.json` for unnecessary packages
- Source maps accidentally included — check `vite.config.ts` (should have `sourcemap: false` in production)

**Solution:**

```bash
# Check what's taking space
npm run build -- --debug
```

---

### Network Requests After Load

**Symptom:** DevTools Network tab shows requests after initial load

**Common causes:**

- External font CDN — ensure `font-family` uses system fallbacks only
- Remote images — all images must be inlined or removed
- Analytics scripts — remove if present

**Fix:** Review `index.html` and all components for external resource references.

---

### Console Errors on hotTake.it

**Symptom:** Errors appear in browser console on published demo

**Common causes:**

- Absolute paths instead of relative paths
- Missing assets (though single-file build should prevent this)
- CORS issues (shouldn't occur with inlined assets)

**Debug:**

1. Download published HTML from hotTake.it
2. Test locally: `open dist/index.html` (via file:// protocol)
3. Reproduce error, inspect in DevTools

---

## Privacy & Security Checklist

Before upload, confirm:

- [ ] No real property addresses or deal details
- [ ] No client names or private information
- [ ] No API keys or authentication tokens
- [ ] No production system URLs or endpoints
- [ ] All data is clearly fictional/placeholder
- [ ] Source maps not included (`*.map` files)
- [ ] No `.env` or config files in dist
- [ ] No console.log statements with sensitive data

---

## Post-Upload Tasks

After successful hotTake.it deployment:

1. **Share URL** — Provide link to stakeholders for usability testing
2. **Monitor feedback** — Check for bug reports, UX issues
3. **Iterate** — Make updates in `demo/` codebase, rebuild, re-upload
4. **Archive** — Save final `dist/index.html` with version tag

---

## Emergency Rollback

If critical issue discovered after upload:

1. Take down published demo (remove from hotTake.it)
2. Fix issue locally
3. Re-run `npm run check` to verify
4. Rebuild and re-upload

**Never patch directly on hotTake.it** — always rebuild from source.

---

## Contact

For questions about this demo:

- Check `docs/architecture.md` for technical details
- Check `docs/interaction-contract.md` for UX specs
- Reach out to Porteos Intelligence project lead
