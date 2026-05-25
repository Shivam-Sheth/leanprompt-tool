# LeanPrompt Security Overview

> Updated: 2026-05-25.

---

## Encryption in Transit

All communication between the extension, Supabase, and third-party APIs uses HTTPS. The extension's `host_permissions` only include `https://` origins.

## Storage

- User settings and feedback queue are stored in Chrome's extension storage (`chrome.storage.local/sync`), which is isolated per extension ID.
- Prompt feedback and user profiles are stored in Supabase (PostgreSQL), protected by Row Level Security policies.
- No sensitive data is stored in unprotected `window.localStorage` (UI position preferences only — remediation in progress).

## Secrets Handling

- The Gemini API key is stored as a Supabase secret and never included in the extension bundle or client-side code.
- The Supabase service role key lives only in Supabase edge function environment variables.
- The Supabase anon key is included in the extension bundle and is designed to be public. It only permits RLS-protected operations.
- API keys are not logged.

## Rate Limits

- Free plan: 80 compressions per month (enforced client-side; server-side enforcement in progress).
- Gemini API input capped at 12,000 characters per request.
- Server-side per-user rate limiting is planned but not yet implemented.

## Abuse Prevention

- Authentication is required before feedback is stored with a user ID.
- Row Level Security ensures users can only read/write their own data.
- Admin-only functions (promote-learned-rules, process-prompt-feedback) use service role keys and should not be directly accessible to end users.

## Vulnerability Reporting

To report a security vulnerability, please email: **[INSERT SECURITY EMAIL]**

We aim to respond within 72 hours and will not pursue legal action against researchers who follow responsible disclosure.
