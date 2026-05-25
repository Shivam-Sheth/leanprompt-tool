# LeanPrompt Production Hardening Report

> Audit date: 2026-05-25. Auditor: Claude (automated security review).

---

## Executive Summary

**LeanPrompt is NOT ready for public launch in its current state.** The product has a functional core (offline compression, Gemini integration, auth, feedback loop) but has several P0 security and privacy issues that were present before this audit. The most critical of these — XSS vulnerabilities in the content script — have been **fixed in this audit**. However, significant privacy gaps (no consent before cloud API use, no data deletion flow, user prompts sent to OpenAI without consent, no privacy policy) remain and must be addressed before public launch.

**Private beta with consenting testers is acceptable** after the privacy disclosures are added and API Assist is made opt-in rather than opt-out.

---

## Top 10 Launch Blockers

| # | Issue | Category | Severity |
|---|---|---|---|
| 1 | XSS via `innerHTML` in content script (fileNames, geminiErr, optimizedText) | Security | Critical |
| 2 | User prompts sent to OpenAI (`process-prompt-feedback`) without user knowledge or consent | Privacy | Critical |
| 3 | No privacy policy — required for Chrome Web Store and legally | Privacy/Legal | Critical |
| 4 | No consent screen before first cloud compression (API Assist on by default) | Privacy | Critical |
| 5 | Prompts stored in database indefinitely with no retention policy enforced | Privacy | High |
| 6 | No user data deletion flow (no endpoint, no UI) | Privacy/Legal | High |
| 7 | No server-side rate limiting on `gemini-compress` — API credit drain possible | Security | High |
| 8 | Raw prompts stored in `chrome.storage.local` feedback queue regardless of `historyOptIn` | Privacy | High |
| 9 | `tabs` permission broader than needed for stated purpose | Chrome Store | Medium |
| 10 | Extension writes to target site's `localStorage` (chatgpt.com, etc.) instead of extension storage | Privacy | Medium |

---

## Fixed Issues

| Issue | Severity | Files Changed | Tests Added | Status |
|---|---|---|---|---|
| XSS: `fileNames` in context window panel innerHTML | Critical | `src/content/index.ts` | Needed | ✅ Fixed |
| XSS: `geminiErr` in model label innerHTML | Critical | `src/content/index.ts` | Needed | ✅ Fixed |
| XSS: `optimizedText` in textarea via innerHTML | Critical | `src/content/index.ts` | Needed | ✅ Fixed |
| XSS: `fileUploadState.names` in panel innerHTML | High | `src/content/index.ts` | Needed | ✅ Fixed |
| Missing `escapeHtml` utility | Critical (prerequisite) | `src/content/index.ts` | — | ✅ Fixed |
| No input length limit on `gemini-compress` | High | `supabase/functions/gemini-compress/index.ts` | Needed | ✅ Fixed |
| No client-side prompt length guard for Gemini | Medium | `src/lib/compression/apiAssist.ts` | — | ✅ Fixed |
| No message sender validation in background | Medium | `src/background/index.ts` | Needed | ✅ Fixed |
| Unvalidated CustomEvent data from MAIN world | High | `src/content/index.ts` | Needed | ✅ Fixed |

---

## Remaining Issues

| Issue | Severity | Reason Not Fixed | Next Step |
|---|---|---|---|
| No privacy policy | Critical | Requires lawyer review and product decisions | Draft in `docs/compliance/PRIVACY_POLICY_DRAFT.md`; get legal review |
| User prompts sent to OpenAI without consent | Critical | Requires product decision: add consent gate or opt-in toggle | Add `training_consent` field; filter in `process-prompt-feedback` |
| No consent screen before first cloud compression | Critical | Requires UI change | Add first-use modal in `content/index.ts` |
| API Assist enabled by default | High | Product decision needed | Change `apiAssistEnabled: false` default; enable after consent |
| No data retention enforcement | High | Requires DB migration + Supabase cron | Add `pg_cron` job per `DATA_RETENTION_POLICY.md` |
| No user data deletion UI | High | Requires edge function + options UI | Add `delete_user_data` RPC + button in options page |
| No server-side rate limiting | High | Requires architecture work | Add per-user hourly limit in `gemini-compress` or middleware |
| Raw prompts in local feedback queue | High | Privacy decision needed | Strip `original_text`/`optimized_text` when `historyOptIn=false` |
| `tabs` permission | Medium | Needs testing without it | Remove `tabs`; verify context menu still works with only `activeTab` |
| Extension writes to target site localStorage | Medium | Refactor work (~15 call sites) | Migrate to `chrome.storage.local` with site-keyed namespacing |
| No sensitive data detection/warning | Medium | Feature work | Add detection patterns + pre-flight warning in `apiAssist.ts` |
| Anonymous feedback allows prompt flooding | Medium | Policy + DB change | Remove anon INSERT policy or add application-level rate limit |
| `process-prompt-feedback` callable by authenticated users | Medium | Requires cron secret | Add `x-cron-secret` header check |
| ReDoS in `promote-learned-rules` regex evaluation | Low-Medium | Needs safe regex wrapper | Add timeout-wrapped regex compilation |
| No deletion of anonymous feedback rows | Medium | Policy decision | Either require auth for feedback, or TTL on anon rows |
| Supabase anon key hardcoded in web app frontend | Low | By design (anon key is public) | Verify RLS policies cover all anon-accessible tables |
| Google Fonts loaded from CDN in content script | Low-Privacy | Feature change | Self-host fonts or use system-ui only |

---

## Privacy and Compliance Status

| Area | Status |
|---|---|
| Privacy policy accuracy | ❌ No privacy policy exists |
| Data collection summary | ✅ Documented in `DATA_INVENTORY_TABLE.md` |
| Third-party data sharing | ❌ Not disclosed to users (Gemini known; OpenAI undisclosed) |
| GDPR-style risk | HIGH — no consent, no deletion, no retention policy |
| Chrome Web Store disclosure readiness | ❌ Privacy policy required; consent not implemented |
| Training data consent | ❌ All feedback used for training regardless of opt-in setting |

---

## Security Status

| Area | Status |
|---|---|
| Auth | ✅ Supabase JWT with RLS; email verification required |
| Rate limiting | ❌ No server-side rate limit on Gemini function |
| Injection protection — SQL | ✅ ORM only, no string-concatenated queries |
| Injection protection — XSS | ✅ Fixed in this audit |
| Extension message safety | ✅ Fixed — sender.id validation added |
| Secrets handling | ✅ Gemini/OpenAI keys server-side only |
| Logging redaction | ✅ No raw prompt content in console logs (feedback errors log metadata only) |
| Input length limits | ✅ Gemini: 12,000 chars; client: no hard limit yet |
| Prompt injection to Gemini | Partial — structural separation exists; explicit delimiters not used |

---

## Testing Status

| Test category | Tests exist | Gap |
|---|---|---|
| Offline compression unit tests | ✅ (vitest) | — |
| Gemini compress integration | ✅ (geminiCompress.test.ts) | — |
| Validation accuracy | ✅ (semantic-quality.test.ts) | — |
| XSS via HTML injection | ❌ | Add test: `</textarea><img onerror=...>` as prompt |
| XSS via malicious CustomEvent | ❌ | Add test: dispatch forged lp-file-attached |
| Prompt injection resistance | ❌ | Add test: "ignore previous instructions" variations |
| Unicode/emoji input | ❌ | Add test: emoji, RTL, zero-width chars |
| Empty/whitespace input | Partial | Extend existing edge case tests |
| Large input (>12k chars) | ❌ | Add test: verify rejection at server + client |
| Message sender validation | ❌ | Add test: external sender rejected |
| Auth required for feedback | ❌ | Add test: unauth feedback insert rejected |
| Data deletion flow | ❌ | Add test: delete_user_data RPC works correctly |

---

## Files Created

| File | Purpose |
|---|---|
| `docs/audit/PRODUCTION_AUDIT.md` | Complete system architecture map |
| `docs/audit/THREAT_MODEL.md` | Threat actors, attack surfaces, mitigations |
| `docs/audit/PRIVACY_GAPS.md` | Privacy gaps vs. expected behavior |
| `docs/audit/DATA_INVENTORY_TABLE.md` | Data flow and storage inventory |
| `docs/audit/API_SECURITY_AUDIT.md` | Edge function security review |
| `docs/audit/EXTENSION_SECURITY_AUDIT.md` | Extension-specific security review |
| `docs/audit/LLM_SAFETY_AUDIT.md` | Prompt injection and output safety |
| `docs/audit/INPUT_HARDENING.md` | Input validation and XSS prevention |
| `docs/audit/DATA_RETENTION_POLICY.md` | Retention targets and implementation plan |
| `docs/audit/DEPENDENCY_AUDIT.md` | npm audit and supply chain review |
| `docs/audit/UX_FAILURE_MODES.md` | UI failure scenarios and privacy UX gaps |
| `docs/compliance/PRIVACY_POLICY_DRAFT.md` | Privacy policy draft (not reviewed) |
| `docs/compliance/TERMS_OF_SERVICE_DRAFT.md` | Terms of service draft (not reviewed) |
| `docs/compliance/SECURITY_OVERVIEW.md` | Security overview for public consumption |
| `docs/compliance/SUBPROCESSORS.md` | List of third-party data processors |
| `docs/compliance/CHROME_WEB_STORE_PRIVACY_DISCLOSURE.md` | Chrome Store privacy form answers |

---

## Files Modified

| File | Change |
|---|---|
| `src/content/index.ts` | Added `escapeHtml()`, fixed 4 XSS vectors, validated CustomEvent data |
| `src/background/index.ts` | Added `sender.id` validation on all messages |
| `supabase/functions/gemini-compress/index.ts` | Added `MAX_INPUT_CHARS = 12000` limit |
| `src/lib/compression/apiAssist.ts` | Added client-side 12,000 char guard before Gemini call |

---

## Launch Recommendation

### ⚠️ PRIVATE BETA ONLY

The product can enter private beta with consenting testers after:
1. ✅ XSS vulnerabilities fixed (done in this audit)
2. ⬜ Add first-use disclosure notice before cloud compression
3. ⬜ Change API Assist default to `false`; require explicit opt-in
4. ⬜ Publish a privacy policy (draft provided; needs legal review)
5. ⬜ Add OpenAI training consent gate (or disable process-prompt-feedback temporarily)

**DO NOT LAUNCH PUBLICLY** until items 2–5 above are complete.

The privacy policy gap alone would cause Chrome Web Store rejection. The missing consent gate and undisclosed OpenAI data sharing are legal risks regardless of jurisdiction.
