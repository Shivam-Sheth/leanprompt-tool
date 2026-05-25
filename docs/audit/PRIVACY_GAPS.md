# Privacy Gaps — LeanPrompt

> Generated: 2026-05-25. Requires lawyer review before shipping.

---

## Gap 1: Prompts Sent to OpenAI Without User Knowledge — CRITICAL

**What happens:** `process-prompt-feedback` edge function batches all rejected prompt-feedback rows and sends `original_text` (the raw user prompt) to OpenAI's `/v1/chat/completions` endpoint for rule extraction.

**What users expect:** Users believe their prompts stay within LeanPrompt and (optionally) Google Gemini. No disclosure exists that OpenAI also receives prompt content.

**Current disclosure:** None found.

**Required action:** Add explicit opt-in consent gate before any feedback is processed by an LLM. Only process rows from users who have consented. Add OpenAI to the subprocessor list. Update privacy policy.

---

## Gap 2: No Privacy Policy Linked or Displayed — CRITICAL

No privacy policy URL is referenced in:
- Extension popup
- Extension options page
- Extension manifest description
- Web app (could not verify from source, but none found in code)

Chrome Web Store **requires** a privacy policy link for any extension that handles user data. This is a store rejection risk.

**Required action:** Write and publish a privacy policy. Add the URL to the manifest description field. Display it in the popup/options footer.

---

## Gap 3: No Consent Before Cloud Compression — HIGH

**What happens:** API Assist is **enabled by default** (`apiAssistEnabled: true` in `defaultSettings`). When the user first clicks "Optimize", their prompt is immediately sent to the Gemini edge function — before any consent notice appears.

**What users expect:** A new user has no way to know that pressing "Optimize" sends their text to Google's Gemini API.

**Required action:** On first use, show a one-time disclosure: "LeanPrompt will send this text to Gemini (via our server) to improve compression. [OK] [Use offline only]". Store consent in `chrome.storage.sync`.

---

## Gap 4: Prompts Stored Indefinitely — HIGH

**What happens:** Every accepted/rejected compression is stored in:
- `prompt_feedback.original_text` / `optimized_text`
- `teacher_compressions.original_prompt`

No retention policy exists in database code or migrations.

**What GDPR-style expectations require:** Data should be deleted when no longer needed for its stated purpose.

**Required action:** Add `created_at` index + a Supabase cron job (pg_cron or edge function) that deletes rows older than 90 days. Alternatively, anonymize (drop original_text after 30 days, keep only metadata).

---

## Gap 5: Anonymous Feedback Stores Prompt Content — HIGH

**What happens:** Migration `005_anon_feedback_ideal_output.sql` allows unauthenticated (anon) users to INSERT rows into `prompt_feedback` with `user_id = NULL`. These rows contain `original_text` (the raw prompt).

**Problem:** There is no way to delete "your" anonymous data since there's no user identifier. GDPR-style deletion rights cannot be fulfilled for anonymous rows.

**Required action:** Either require authentication before recording feedback, or do not store `original_text` for anonymous rows (store only metadata).

---

## Gap 6: localStorage Writes on Target Sites — MEDIUM

**What happens:** LeanPrompt writes to `window.localStorage` of `chatgpt.com`, `claude.ai`, etc. with keys like `leanprompt_overlay_position_v1`.

**Problem:** This is visible to JavaScript running on those sites. It also persists after the extension is uninstalled. The extension is effectively polluting external sites' storage without disclosure.

**Required action:** Move all UI state storage to `chrome.storage.local` with site-scoped keys.

---

## Gap 7: `tabs` Permission Not Justified by Privacy Policy — LOW-MEDIUM

**What happens:** The extension requests the `tabs` permission, which grants access to the URL of every open tab (not just the active one). This is used only for reading the current tab's URL for the context menu title.

**Chrome Web Store policy:** Overly broad permissions can cause rejection.

**Required action:** Remove the `tabs` permission. Use `activeTab` which already provides the current tab's URL when the context menu is invoked.

---

## Gap 8: No Opt-Out for Analytics / Feedback Collection — MEDIUM

The settings include `historyOptIn: false` (off by default) but:
- The feedback queue still records `original_text` regardless of historyOptIn
- There is no clear distinction between "compression history" and "training data upload"
- No UI shows users what data is being collected

**Required action:** Separate "save compression history locally" from "upload feedback for training". Add clear toggle in settings UI.

---

## Gap 9: No Data Deletion / Export Flow — HIGH

**What happens:** There is no endpoint, UI, or flow for a user to:
- Delete their account
- Delete their prompt history
- Export their data

**Required action:** Implement `DELETE /api/user` (or Supabase RPC) that deletes all rows where `user_id = auth.uid()` from `prompt_feedback` and `teacher_compressions`. Add a "Delete my data" button to the extension options page and dashboard.

---

## Gap 10: Subprocessors Not Disclosed — MEDIUM

The following third parties receive user data (including raw prompt content) but are not disclosed:
- **Google Gemini API** — receives prompt content for compression
- **OpenAI API** — receives prompt content for rule extraction
- **Supabase** — stores all user data
- **Vercel** — hosts the web app
- **GitHub** — receives model training dispatch events

**Required action:** Create and publish a subprocessors list. Add to privacy policy.
