# UX Failure Modes — LeanPrompt

> Generated: 2026-05-25.

---

## Failure Mode Matrix

| Scenario | Current behavior | Acceptable? | Fix needed |
|---|---|---|---|
| Gemini API times out (10s) | Falls back to offline compression silently; shows "✕ Gemini failed" badge | ✅ Good | None |
| Gemini returns non-shorter result | Falls back to offline; shows "✕ Gemini failed" badge | ✅ Good | None |
| Supabase offline / unreachable | Auth error shown in popup; compression still works offline | ✅ Good | None |
| Extension context invalidated (after reload) | `isExtensionContextInvalidated` guard in place; errors suppressed | ✅ Good | None |
| User not signed in | "Sign in" nudge shown in panel after compression | ✅ Good | None |
| Email not verified | Gate in `checkOptimizeGate`; friendly error shown | ✅ Good | None |
| Quota exceeded (80 free/month) | `enforcePlanLimit` blocks; upgrade URL shown | ✅ Good | None |
| User enters empty prompt | Toast shown: "Empty prompt" | ✅ Good | None |
| Prompt > 50k chars | **No limit enforced** — may be slow/freeze | ❌ | Add 50k char limit |
| Prompt > 12k chars | Gemini rejected; offline only | ✅ Acceptable | None |
| Model returns invalid compressed text | Validation fails; offline result shown | ✅ Good | None |
| Double-submit (click Optimize twice fast) | Second click shows "already compressed" toast | ✅ Good | None |
| Slow internet (compression takes > 3s) | No loading indicator for offline compression | ⚠️ | Add loading spinner |
| Network error during feedback upload | Enqueued in local storage for retry | ✅ Good | None |
| Chrome extension update | Context invalidation handled gracefully | ✅ Good | None |
| User pastes 4000 emoji | May produce garbled compression output | ⚠️ | Add char limit |
| RTL text layout | Text shows correctly in overlay; compression may rearrange | ⚠️ | Test on Arabic/Hebrew sites |
| Keyboard navigation in overlay | Buttons have `type="button"`; tab order not tested | ⚠️ | Manual QA needed |
| Screen reader / accessibility | `aria-label` on textarea; limited ARIA elsewhere | ⚠️ | Add role/aria-live |
| Content script fails to find input element | No optimization button appears | ✅ Silent fail | None |
| Mobile viewport | `window.innerWidth < 640` handled with mobile layout | ✅ Good | None |

---

## Privacy-Specific UX Issues

| Issue | Status |
|---|---|
| No disclosure banner before first cloud compression | ❌ Not implemented |
| No "you're in offline mode" indicator | ❌ Missing |
| No onboarding screen explaining data handling | ❌ Not implemented |
| API Assist on by default without consent | ❌ Should be off-by-default until consent given |
| No way to opt out of feedback upload from UI | ❌ `historyOptIn` setting not clearly labeled |

---

## Recommended UX Fixes (P1)

1. **First-use consent notice:** On first compression attempt with API Assist enabled, show a one-time modal: "To get the best compression, LeanPrompt sends your prompt to Google's Gemini API via our server. [Enable cloud compression] [Use offline only]". Store choice in `chrome.storage.sync`.

2. **Loading state for offline compression:** Add a brief "Optimizing…" state (100ms delay before showing result) so users know something happened.

3. **Sensitive data warning:** Add a pre-flight check for obvious sensitive patterns (API keys, SSNs) and show a non-blocking warning before cloud submission.

4. **Prompt length limit UI:** Show character counter and soft-warn at 10k chars, hard-block at 50k.

5. **Privacy footer in options page:** Link to privacy policy and "Delete my data" button.
