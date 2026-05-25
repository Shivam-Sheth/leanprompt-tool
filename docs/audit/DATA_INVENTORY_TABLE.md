# Data Inventory — LeanPrompt

> Generated: 2026-05-25. Requires lawyer review.

| Data Type | Collected? | Where Collected | Required? | Stored Where | Retention | Shared With | Used for Training? | User Can Delete? | Disclosed? |
|---|---|---|---|---|---|---|---|---|---|
| Raw prompt text (original) | Yes | Content script reads textarea value on button press | Optional (only on feedback) | `prompt_feedback.original_text`, `teacher_compressions.original_prompt`, local feedback queue | Indefinite (no policy) | Google Gemini (compression), OpenAI (rule extraction) | Yes (with consent issues) | No endpoint exists | No |
| Compressed prompt text | Yes | Produced by offline engine / Gemini | Optional | `prompt_feedback.optimized_text`, `teacher_compressions.gemini_output` | Indefinite | OpenAI (rule extraction) | Yes | No endpoint | No |
| User-edited prompt | Yes | User edits textarea in overlay | Optional | `prompt_feedback.edited_text`, `teacher_compressions.user_edited_output` | Indefinite | None | Yes | No endpoint | No |
| Accept/reject feedback | Yes | User clicks Apply/Reject | Optional | `prompt_feedback.action`, `teacher_compressions.user_action` | Indefinite | OpenAI (analysis) | Yes | No endpoint | No |
| Intent classification | Yes | Offline classifier | Functional | DB with feedback rows | Indefinite | None | Yes | No endpoint | No |
| Site/domain | Yes | `window.location.hostname` | Functional | `prompt_feedback.site` | Indefinite | None | No | No endpoint | No |
| User email / ID | Yes, if signed in | Supabase auth | Optional | `auth.users`, `user_profiles` | Until deletion | Supabase | No | No user-facing flow | No |
| IP address | Implicit | Supabase / Vercel server logs | Server-level | Hosting provider logs | Provider retention | Supabase, Vercel | No | No | No |
| Device/browser metadata | Minimal | `chrome.runtime` | No | Not stored | N/A | None | No | N/A | No |
| Auth tokens | Yes | Supabase JWT | Functional | `chrome.storage.local` (via Supabase SDK), `chrome.storage.sync` (optional override) | Until sign-out / expiry | Supabase | No | On sign-out | No |
| Usage stats (compressions/month) | Yes | Local + server-side counter | Functional | `chrome.storage.local`, `user_profiles` | Indefinite | None | No | Via account deletion | No |
| File attachment metadata (name, size, MIME) | Yes | FormData.append patch | Functional | RAM only (not persisted) | Session only | None | No | N/A | No |
| Extension UI position/size | Yes | localStorage of target sites | Functional | Target site localStorage | Until cleared by user | None | No | Manual | No |
| Token stats per session | Yes | sessionStorage of target sites | Functional | Target site sessionStorage | Session only | None | No | N/A | No |
| API keys (Gemini, OpenAI) | No (server only) | Edge function environment | Functional | Supabase secrets | While deployed | None | No | N/A | Yes (partially) |
| Supabase anon key | Yes | Extension bundle (build-time) | Functional | Extension JS bundle | Until rebuild | Any bundle inspector | No | N/A | No |
| Rejection reason/category | Yes | User selects from chips | Optional | `prompt_feedback.rejection_category` | Indefinite | OpenAI | Yes | No endpoint | No |
| Compression rule ID | Yes | Offline engine attribution | Functional | `prompt_feedback.matched_rule_id` | Indefinite | None | Yes | No endpoint | No |
| Model output (Gemini response) | Yes | Edge function response | Optional | `teacher_compressions.gemini_output` | Indefinite | None | Yes | No endpoint | No |

---

## High-Risk Data Categories Users May Paste

The following sensitive categories may appear in prompts. LeanPrompt currently has **no detection or warning** for any of these:

- Health information (symptoms, medications, diagnoses)
- Financial data (account numbers, transactions)
- Legal documents (contracts, immigration, criminal)
- Passwords or API keys
- Personal communications (emails, messages)
- Social Security / national ID numbers
- Credit card numbers
- Children's information
- Workplace confidential data
