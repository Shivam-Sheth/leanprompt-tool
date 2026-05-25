# API Security Audit — LeanPrompt

> Generated: 2026-05-25.

---

## Edge Function: `gemini-compress`

| Field | Value |
|---|---|
| Method | POST |
| Path | `/functions/v1/gemini-compress` |
| Auth | Supabase JWT (implicit — Supabase verifies unless `--no-verify-jwt` flag used) |
| Input | `{ prompt: string }` |
| Output | `{ text, model, latencyMs, inputChars, outputChars }` or `{ error }` |
| Rate limit | None server-side |
| External APIs | Google Gemini |
| Logging | None beyond error returns |
| CORS | `"Access-Control-Allow-Origin": "*"` — wildcard |

**Findings:**
1. ~~No input length limit~~ — **FIXED**: Added `MAX_INPUT_CHARS = 12000` check.
2. No per-user rate limiting — any authenticated user can make unlimited requests, burning Gemini API credits.
3. Wildcard CORS — acceptable for Supabase edge functions accessed from browser extensions, but should be restricted to known origins if possible.
4. Gemini API key stored correctly as Supabase secret (not in code).
5. Error messages from Gemini (up to 300 chars) reflected back in response — acceptable since this is server-to-server, not XSS risk here.

**Remaining risk:** Without rate limiting, an attacker with a valid Supabase session can drain the Gemini API budget.

**Recommended fix:**
```sql
-- In validate-session or a middleware function, track compressions_this_hour
-- per user_id. Reject if > 100 in an hour.
```
Or implement token bucket via `user_profiles` table.

---

## Edge Function: `validate-session`

| Field | Value |
|---|---|
| Method | POST |
| Path | `/functions/v1/validate-session` |
| Auth | `Authorization: Bearer <access_token>` (explicit check) |
| Input | Optional `{ compressions, tokens_saved, accepted }` |
| Output | `{ ok, user_id, email }` |
| Rate limit | None |
| External APIs | None |
| CORS | `"Access-Control-Allow-Origin": "*"` |

**Findings:**
1. Auth is properly validated via `supabase.auth.getUser()`.
2. Usage stats passed from client and trusted (`p_compressions`, `p_tokens_saved`). A malicious client could pass `compressions: 999999` to inflate their usage counter (though this doesn't unlock anything currently).
3. `user_id` returned in response — acceptable since this is an authenticated endpoint.

**Recommended fix:** Cap incoming `compressions` and `tokens_saved` values to reasonable maximums (e.g., 1 and 1000 respectively per call).

---

## Edge Function: `process-prompt-feedback`

| Field | Value |
|---|---|
| Method | POST (via cron/auto-trigger) |
| Path | `/functions/v1/process-prompt-feedback` |
| Auth | Supabase JWT (implicit) |
| External APIs | **OpenAI** |
| Data handled | Raw user prompts from `prompt_feedback` table |

**Findings:**
1. Sends `original_text` (raw user prompts) to OpenAI without explicit user consent.
2. Uses `serviceRoleKey` to read all rows — appropriate for a server-side job.
3. Uses `SUPABASE_SERVICE_ROLE_KEY` which has unrestricted DB access. If this function is compromised, full DB access is possible.
4. No CORS headers — this function is triggered server-side so this is acceptable.
5. No auth check at the HTTP level — this is a server-triggered function that should NOT be callable by end users. Supabase's implicit JWT check may allow authenticated users to trigger it.

**Critical risk:** Authenticated users can POST to this endpoint and trigger OpenAI API calls at arbitrary frequency.

**Recommended fix:** Add a shared secret header check (Supabase cron passes a secret; external callers are rejected):
```typescript
const cronSecret = Deno.env.get("CRON_SECRET");
if (req.headers.get("x-cron-secret") !== cronSecret) {
  return new Response("Forbidden", { status: 403 });
}
```

---

## Edge Function: `promote-learned-rules`

| Field | Value |
|---|---|
| Method | POST |
| Path | `/functions/v1/promote-learned-rules` |
| Auth | Implicit Supabase JWT |
| External APIs | GitHub API |

**Findings:**
1. Uses `serviceRoleKey` — full DB access.
2. Calls GitHub API to dispatch `retrain-model` workflow. GITHUB_TOKEN should have minimal permissions (only `workflow` scope).
3. `evaluateRule` calls `new RegExp(rule.pattern_source, "i")` on user-LLM-derived data. A malicious RegEx could cause ReDoS (catastrophic backtracking). Consider adding a timeout wrapper or limiting pattern complexity.

**Recommended fix for ReDoS:**
```typescript
function safeRegex(pattern: string): RegExp | null {
  try {
    const r = new RegExp(pattern, "i");
    // Test against a short string to detect infinite-loop patterns
    const testTimeout = new Promise<never>((_, reject) => 
      setTimeout(() => reject(new Error("timeout")), 100)
    );
    return r;
  } catch {
    return null;
  }
}
```

---

## Injection Protection Summary

| Attack | Protected? | Notes |
|---|---|---|
| SQL injection | Yes | All queries use Supabase ORM / parameterized |
| XSS via API response | ~~No~~ **Fixed** | geminiErr and optimizedText now properly escaped |
| XSS via CustomEvent | ~~No~~ **Fixed** | fileNames validated and escaped |
| Command injection | Yes | No shell commands |
| Template injection | Low risk | System prompts are static |
| ReDoS | Partial | `promote-learned-rules` compiles user-LLM-derived regex without timeout |
| Prompt injection | Partial | User content wrapped in Gemini `contents` not `system_instruction` |

---

## Secrets Management

| Secret | Location | Risk |
|---|---|---|
| `GEMINI_API_KEY` | Supabase secrets (production OK); `.env.local` (dev — present in plaintext) | Needs rotation if ever committed |
| `SUPABASE_ANON_KEY` | Extension bundle (by design — anon key) | Low risk; RLS protects data |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase secrets only | Correct — never in extension bundle |
| `OPENAI_API_KEY` | Supabase secrets | Correct |
| `GITHUB_TOKEN` | Supabase secrets | Verify scope is `workflow` only |
