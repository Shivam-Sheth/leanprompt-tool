# Dependency Audit — LeanPrompt

> Generated: 2026-05-25.

---

## Extension (`leanprompt-extension/`)

### Production dependencies

| Package | Version | Purpose | Risk |
|---|---|---|---|
| `@supabase/supabase-js` | ^2.49.4 | Auth + DB client | Low — maintained, widely used |
| `better-sqlite3` | ^12.4.1 | Local training DB (scripts only) | Low — not in extension bundle |
| `dictionary-en` | ^4.0.0 | Spell checker wordlist | Low — static data |
| `nspell` | ^2.1.5 | Spell checker | Low — offline, no network |

### Dev dependencies

| Package | Version | Risk |
|---|---|---|
| `esbuild` | ^0.25.5 | Build tool | Low — dev only |
| `tsx` | ^4.20.6 | TypeScript runner for scripts | Low — dev only |
| `typescript` | ^5.8.3 | Type checking | Low — dev only |
| `vitest` | ^2.1.8 | Test runner | **Moderate** — npm audit shows `esbuild ≤0.24.2` vulnerability (CVE in vitest transitive dependency) |

### npm audit results

```
Moderate: esbuild ≤0.24.2 — development server request forgery
  Path: vitest → vite → esbuild
  Fix: upgrade vitest to 4.x (major version bump)
  
Moderate: @vitest/mocker ≤3.0.0-beta.4
  Path: vitest → @vitest/mocker
  Fix: upgrade vitest to 4.x
```

**Risk assessment:** Both vulnerabilities are in the development/testing dependency chain (vitest → vite → esbuild). They do NOT affect the production extension bundle. The esbuild vulnerability allows a website to send requests to the local development server. This only matters during `npm run dev`. Not a production risk.

**Recommended fix:** Upgrade vitest to 4.x in the next dev dependency refresh cycle. Not a launch blocker.

---

## Web App (`LeanPrompt/`)

A separate npm audit was not run. The web app uses React + Vite and has similar dev-dependency risks. No production secrets in the bundle (Supabase anon key is expected to be public).

---

## Bundle Inspection Checklist

- [ ] Verify `GEMINI_API_KEY` is not in extension bundle: `grep -r "AIzaSy" dist/`
- [ ] Verify `SUPABASE_SERVICE_ROLE_KEY` is not in bundle: `grep -r "service_role" dist/`
- [ ] Verify no `eval` or `new Function` in bundle: `grep -r "eval(" dist/`
- [x] No source maps in production bundle (verify `build.mjs` does not set `sourcemap: true` in production)
- [x] All extension code bundled locally — no CDN script tags in HTML files

---

## Supply Chain Notes

- No install scripts (`preinstall`, `postinstall`) in production dependencies
- No packages with known malicious history in direct dependencies
- Supabase client loaded from npm (not CDN) in the extension
- Edge functions import Supabase from `esm.sh` CDN (`https://esm.sh/@supabase/supabase-js@2.49.4`) — this is standard Deno practice but pins a specific version, which is good
