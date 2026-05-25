# LeanPrompt Privacy Policy

> Last updated: May 2026
> Published at: https://www.leanprompt.net/privacy

---

## What is LeanPrompt?

LeanPrompt is a Chrome extension and web application that compresses your AI prompts before you send them to tools like ChatGPT, Claude, and Gemini — reducing token usage while preserving your intent.

---

## What data we collect

### Prompt text

When you click "Optimize", LeanPrompt reads the text from the AI tool's input field to compress it. Compression runs locally on your device first. If cloud compression (API Assist) is enabled, your prompt is also sent to our server and then to Google's Gemini API. We do not read your prompts automatically — processing only happens when you actively click Optimize.

If you click "Apply" or "Reject" on a result, the original prompt, compressed prompt, your action, and metadata (compression quality score, detected intent, site name) are stored in our database linked to your account.

### Account information

If you create an account, we collect your email address. Passwords are hashed by Supabase and never stored in plain text. You may also sign in with Google.

### Usage statistics

We store aggregate counts of your compressions and estimated tokens saved in your user profile to power the dashboard.

### Extension settings

Your preferences (compression level, enabled sites, API Assist toggle) are saved in Chrome's sync storage and sync across your signed-in Chrome devices.

---

## What we do NOT collect

- Web pages or browsing history — we only process text you explicitly compress
- Keystrokes or mouse activity
- Payment information (LeanPrompt is currently free)
- Device identifiers beyond standard server access logs

---

## How data flows

1. You click "Optimize."
2. LeanPrompt compresses your prompt locally (offline model, no network required).
3. If API Assist is enabled, the prompt is also sent to our Supabase server.
4. Our server forwards it to **Google's Gemini API** and returns the result.
5. If you reject a result, that example may be analyzed by **OpenAI's API** in an automated process to identify patterns for improving future compressions.

You can disable cloud compression by turning off "API Assist" in extension settings. When off, all compression is local and no prompt text leaves your browser.

---

## Data retention

Prompt feedback is stored in our database while your account is active. We are implementing automated deletion of prompt text older than 90 days. Until that is in place, you can request immediate deletion of all your data by emailing shethshivam123@gmail.com.

---

## Your rights

You can request deletion of all data associated with your account at any time by emailing shethshivam123@gmail.com. We will delete your data within 30 days.

You can also opt out of feedback storage at any time by disabling "History" in the extension settings. This prevents future feedback from being stored, but does not delete previously stored data.

---

## Third-party services

| Service | Purpose | Data shared |
|---|---|---|
| **Supabase** | Database and authentication | Email, prompt feedback, usage stats |
| **Google Gemini API** | Cloud prompt compression | Prompt text (when API Assist is on) |
| **OpenAI API** | Compression pattern analysis | Rejected prompt examples |
| **Vercel** | Web app hosting | Server access logs (IP, user agent) |

All services are based in the United States.

---

## Chrome extension permissions

| Permission | Why |
|---|---|
| `storage` | Save settings and pending feedback queue |
| `activeTab` | Read prompt text from the active AI tool tab |
| `scripting` | Inject the optimization overlay on supported sites |
| `identity` | Enable Google Sign-In |
| `alarms` | Refresh your login session in the background |
| `contextMenus` | Add "Disable on this site" to the right-click menu |

---

## Local storage

LeanPrompt stores the following in your browser:

- **Chrome sync storage** — extension settings
- **Chrome local storage** — pending feedback queue, usage counter, disabled sites list
- **Website localStorage** (on AI tool sites) — overlay position and size preferences

LeanPrompt does not set HTTP cookies.

---

## Security

All communication between the extension, our servers, and third-party APIs uses HTTPS. Auth tokens are stored in Chrome's extension storage, isolated per extension ID. We use Supabase Row Level Security so users can only access their own data. API keys are stored as server-side secrets and are never included in the extension bundle.

---

## Children's privacy

LeanPrompt is not directed at children under 13. We do not knowingly collect personal information from children.

---

## Changes to this policy

We will post any material changes here and update the "Last updated" date above.

---

## Contact

Questions about this policy: shethshivam123@gmail.com
