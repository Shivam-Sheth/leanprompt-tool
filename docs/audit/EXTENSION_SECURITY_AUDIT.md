# Extension Security Audit — LeanPrompt

> Generated: 2026-05-25.

---

## 1. Permissions

| Permission | Needed? | Risk |
|---|---|---|
| `storage` | Yes | Low — standard extension storage |
| `activeTab` | Yes | Low — grants access to current tab only |
| `scripting` | Yes | Medium — needed to inject overlay but powerful permission |
| `identity` | Yes | Low — Google OAuth |
| `alarms` | Yes | Low — session refresh |
| `contextMenus` | Yes | Low |
| **`tabs`** | **Marginal** | **Medium — grants URL of ALL open tabs** |

**Fix for `tabs`:** Remove it. The background script uses `chrome.tabs.get(tabId)` to read the tab URL for context menu title. `activeTab` does not cover this use case, but the permission can be removed by passing the URL when the context menu fires (the `info` object in `onClicked` does not include tab URL for non-page-action contexts, but `tab.url` IS available in `onClicked` handler which already receives the `tab` parameter — verify if this works without `tabs` permission).

Actually, in MV3, `contextMenus.onClicked` provides the `tab` object which includes `tab.url` when the extension has `activeTab` or `tabs`. Without `tabs`, the `tab.url` may be undefined. A safer approach: use `chrome.tabs.query({active: true, currentWindow: true})` triggered from the popup or options page.

**Verdict:** `tabs` permission can likely be replaced with activeTab-scoped URL reading. Needs testing.

---

## 2. Content Script Safety

### `content/fileIntercept.js` — MAIN world

**Risk:** Runs in the page's JavaScript context. Patches `FormData.prototype.append`.

**Finding:** The patch is read-only (it calls the original `origAppend`). It dispatches a CustomEvent with file metadata. Any page script can observe this event in MAIN world, but the data (filename, size, MIME) is already available to the page via the FileList API anyway.

**Finding (FIXED):** The isolated content script received this event data and used it in innerHTML without validation. Fixed by adding type validation and sanitization on the event handler side.

**Risk mitigation:** The MAIN world script does minimal processing and does not access extension APIs. Risk is contained.

### `content/index.js` — ISOLATED world

**Findings:**
1. ~~XSS via `result.optimizedText` in textarea HTML~~ — **FIXED**
2. ~~XSS via `geminiErr` in model label~~ — **FIXED**
3. ~~XSS via `fileNames` in context window panel~~ — **FIXED**
4. Uses `window.localStorage` and `window.sessionStorage` on target sites — writes to target site's storage namespace.
5. Loads Google Fonts via `@import url('https://fonts.googleapis.com/...')` embedded in a `<style>` tag injected into the page. This makes a network request to Google on any page where LeanPrompt is active.

**Remaining risk:** Google Fonts load reveals to Google that a user is visiting a supported AI tool site (though Google already knows this from browser activity).

**Fix for #4 (localStorage on target sites):** Migrate position/size/stats storage from `window.localStorage` to `chrome.storage.local` with keys scoped by `window.location.hostname`. This requires updating all read/write call sites (~15 references). Not yet implemented — tracked as P1.

---

## 3. Message Passing

### Background (`onMessage`)

**Finding (FIXED):** Added `sender.id !== chrome.runtime.id` check to reject messages from other extensions or unknown sources.

**Finding:** Password is passed in `LEANPROMPT_LOGIN` message as plaintext string from content script to background. This stays within Chrome's internal IPC (not transmitted over network) so risk is low, but it's worth noting the pattern.

**Typed message protocol:** `src/lib/messaging/protocol.ts` defines TypeScript types for all messages. This provides compile-time safety but no runtime validation — a crafted message object could still pass the `msg?.type === "..."` checks.

**Recommended:** Add Zod or manual shape validation for messages that handle sensitive data (LOGIN, SIGNUP, RECORD_FEEDBACK).

---

## 4. Storage

| Storage | Contains | Risk |
|---|---|---|
| `chrome.storage.local` feedback queue | Raw prompt text (up to 500 items) | Sensitive — prompts stored in plaintext |
| `chrome.storage.local` teacher queue | Raw prompts + Gemini outputs | Sensitive |
| `chrome.storage.sync` | Settings, optional Supabase credentials | Medium — if user stores custom credentials |
| Target site `localStorage` | UI position, token stats | Writes to external site — pollutes their storage |

**Recommended:** For feedback queue, when `historyOptIn` is false, strip `original_text` and `optimized_text` from queued items (store only metadata for analytics).

---

## 5. CSP and Remote Code

- Extension bundle: all code is locally bundled. No dynamic imports from remote URLs.
- Google Fonts: loaded via CSS `@import` in injected `<style>` tag — not JavaScript execution, so no CSP concern for scripts.
- Extension manifest does not define a `content_security_policy` field. The default MV3 CSP (`script-src 'self'; object-src 'self'`) applies. This is correct.

---

## 6. UI Trust

| Issue | Status |
|---|---|
| No disclosure before sending to cloud API | Not fixed — P1 |
| No per-site disable with visual indicator | Fixed (context menu) |
| Cloud mode badge visible | Yes — "● Gemini" badge shown in overlay |
| Offline fallback when Gemini fails | Yes — works correctly |

---

## 7. web_accessible_resources

Only icon images are listed. No JavaScript is web-accessible. Correct.
