# LeanPrompt Production Audit — System Architecture Map

> Generated: 2026-05-25. Based on code inspection of all source files.

---

## 1. Browser Extension Architecture

### Manifest (MV3) — `leanprompt-extension/public/manifest.json`

| Field | Value | Risk Note |
|---|---|---|
| version | 0.1.0 | Pre-release |
| manifest_version | 3 | Correct |
| permissions | storage, activeTab, scripting, identity, alarms, contextMenus, **tabs** | `tabs` gives URL access to ALL tabs, not just active |
| host_permissions | 35 AI-tool domains | Very broad; each domain gets full content-script injection |

### Content Scripts
| File | World | Run-at | Risk |
|---|---|---|---|
| `content/fileIntercept.js` | **MAIN** | document_start | Patches FormData.prototype.append in page JS context; dispatches CustomEvent |
| `content/index.js` | ISOLATED (default) | document_idle | Full UI overlay; reads prompt textarea value |

### Background Service Worker — `src/background/index.ts`
- Handles auth (Supabase), session refresh, Gemini compress proxy, feedback recording
- Message listener accepts 15 message types with no sender origin validation

### Popup & Options
- `popup.html` / `src/popup/index.ts` — Login/signup UI, usage stats
- `options.html` / `src/options/index.ts` — Settings, Supabase credential override

### Storage Usage
| Storage | Keys | Data Stored | Risk |
|---|---|---|---|
| chrome.storage.sync | `leanprompt_settings`, `leanprompt_supabase_url`, `leanprompt_supabase_anon_key` | User settings, optional Supabase credentials | Synced across devices |
| chrome.storage.local | `leanprompt_feedback_queue_v1`, `leanprompt_teacher_queue_v1`, `leanprompt_disabled_sites`, `usage_{userId}` | Queued feedback (includes raw prompts), disabled sites, usage counter | Raw prompts queued locally |
| **window.localStorage** (target page) | `leanprompt_overlay_position_v1`, `leanprompt_overlay_size_v1`, `leanprompt_opt_button_position_v1_*`, `leanprompt_concise_toggle_v1`, `leanprompt_token_stats_v1_*`, `leanprompt_token_filter_v1_*` | UI position/state per site, token usage stats | Writes to TARGET SITE's localStorage, not extension storage |
| window.sessionStorage (target page) | `leanprompt_response_style_injected_v1_*`, `leanprompt_token_stats_session_*` | Per-session state | Writes to TARGET SITE's sessionStorage |

### Permissions Justification (Current — Unaudited)
- `storage` — needed for settings, feedback queue
- `activeTab` — needed to inject on active tab
- `scripting` — needed for content script injection
- `identity` — needed for Google OAuth
- `alarms` — needed for 50-minute session refresh
- `contextMenus` — needed for "Disable on this site" right-click menu
- **`tabs`** — used to read tab URL for context menu title; `activeTab` alone cannot do this → LOW NECESSITY (see Phase 6)

### web_accessible_resources
Only icon images, scoped to the 35 AI-tool domains. Acceptable.

---

## 2. Web App Architecture (`LeanPrompt/`)

| Component | Details |
|---|---|
| Framework | React + Vite |
| Hosting | Vercel (`vercel.json`) |
| Auth/DB | Supabase (URL + anon key **hardcoded** in `src/lib/supabase.js`) |
| Pages | Landing, Download, Login, Dashboard, ResetPassword |
| API routes | None (all DB via Supabase client directly) |
| Analytics | None found |
| Payments | None found |

**Critical:** `LeanPrompt/src/lib/supabase.js` hardcodes the production Supabase URL and anon key in source.

---

## 3. Backend — Supabase Edge Functions

| Function | Auth Required | Description | External APIs |
|---|---|---|---|
| `gemini-compress` | Implicit (Supabase JWT) | Proxies prompt to Gemini API | Google Gemini |
| `validate-session` | Bearer token (explicit check) | Validates session + logs usage stats | None |
| `process-prompt-feedback` | Implicit (Supabase JWT) | Sends rejected feedback to OpenAI; writes learned_rules | **OpenAI** |
| `promote-learned-rules` | Implicit (service role) | Auto-promotes learned rules; triggers GitHub Actions | **GitHub API** |

### CORS
All functions use `"Access-Control-Allow-Origin": "*"` — wildcard CORS.

---

## 4. Database Schema (Supabase PostgreSQL)

| Table | RLS | Contains Raw Prompts? | Anonymous Access |
|---|---|---|---|
| `prompt_feedback` | Yes | **YES** — `original_text`, `optimized_text`, `edited_text`, `ideal_output` | INSERT allowed (user_id IS NULL) |
| `user_profiles` | Yes | No | No |
| `learned_rules` | Yes | Examples derived from prompts | SELECT for all authenticated |
| `gold_compressions` | Yes | `original_text`, `expected_output` — from real user prompts | SELECT for all authenticated |
| `rule_metrics` | Yes | No | SELECT for all authenticated |
| `teacher_compressions` | Yes | **YES** — `original_prompt`, `gemini_output`, `final_output_used` | INSERT/SELECT with user_id=null |
| `prompt_feedback_agent_runs` | Yes (no policies for non-service) | Summary metadata | No |

**No retention policies enforced in any table.** Prompts stored indefinitely.

---

## 5. Data Flow Map

### Raw User Prompts

| Stage | What happens | Where stored | Third party |
|---|---|---|---|
| User types in ChatGPT/Claude/etc. | Content script reads textarea `.value` on button press | Never stored on disk — RAM only | — |
| User clicks Optimize | Offline compression runs locally | Not stored (result in memory) | — |
| API Assist enabled (default) | Prompt sent to Supabase edge → Gemini API | **Supabase `gemini-compress` function receives it** | **Google Gemini** |
| User accepts/rejects | Feedback recorded: original+compressed stored in `chrome.storage.local` queue | Local queue (500 max) | — |
| Background flush | Queue uploaded to `prompt_feedback` table | **Supabase DB permanently** | — |
| `process-prompt-feedback` triggers | Rejected prompts sent to OpenAI for rule extraction | OpenAI API | **OpenAI** |
| Gemini Teacher Mode | Stores original + gemini output in `teacher_compressions` | **Supabase DB permanently** | — |

### User Account Data
- Email, user ID, usage stats stored in Supabase `user_profiles`
- Auth tokens in Supabase auth.users
- No payment data collected

### File Attachment Metadata
- File name, size, MIME type from FormData patch
- Stored in extension memory only (not sent to server)

---

## 6. No-Existing Privacy Policy or Terms of Service Found

The codebase contains no `PRIVACY_POLICY.md`, `TERMS_OF_SERVICE.md`, or links to either in the extension popup/options page. The web app landing page links are not auditable from source.

---

## 7. Summary of High-Risk Areas

1. `src/content/index.ts` — innerHTML XSS vectors (user content + API errors + file names)
2. `.env.local` — contains real production Gemini API key
3. `LeanPrompt/src/lib/supabase.js` — hardcoded credentials
4. `supabase/functions/process-prompt-feedback/index.ts` — sends user prompts to OpenAI without user consent/knowledge
5. `supabase/functions/gemini-compress/index.ts` — no input length limit
6. `src/content/fileIntercept.ts` — MAIN world script; CustomEvents can be forged by any page
7. `chrome.storage.local` — raw prompts queued without opt-in
8. All database tables — no retention limits in code
9. `tabs` permission — broader than needed
10. `window.localStorage` writes on target sites — pollutes site storage
