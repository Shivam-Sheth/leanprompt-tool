# Chrome Web Store Privacy Disclosure

> Prepared: 2026-05-25. Fill this into the Chrome Web Store developer console.
> Verify accuracy against final published code before submission.

---

## Single Purpose Description

LeanPrompt compresses and shortens AI prompts to reduce token usage before users send them to AI tools such as ChatGPT, Claude, Gemini, and others.

---

## Permissions Justification

| Permission | Justification |
|---|---|
| `storage` | Store user settings (compression level, enabled sites) and a local queue of feedback data |
| `activeTab` | Read the prompt from the currently focused AI tool tab when the user clicks Optimize |
| `scripting` | Inject the optimization overlay UI into supported AI tool pages |
| `identity` | Power Google Sign-In for authentication |
| `alarms` | Refresh Supabase auth session every 50 minutes to keep the user logged in |
| `contextMenus` | Add a right-click menu item to enable/disable LeanPrompt on the current site |

---

## Host Permissions Justification

LeanPrompt injects a content script on each supported AI tool domain (chatgpt.com, claude.ai, gemini.google.com, etc.) to detect the prompt input element and attach the optimization button.

The Supabase domain (`*.supabase.co`) is required to authenticate users and submit feedback.

---

## Data Usage Disclosure (Chrome Web Store Form)

### Does your extension collect or use any of the following types of personal or sensitive user data?

**Personally identifiable information:** Yes — email address if user creates an account.

**Personally identifiable information used:** Used solely to authenticate the user. Not shared with third parties except Supabase (authentication provider).

**Authentication information:** Yes — passwords or Google OAuth tokens, handled by Supabase Auth.

**Web browsing activity:** No — LeanPrompt does not track which websites users visit. It only activates on the supported AI tool sites listed in host_permissions.

**User-generated content:** Yes — the text content of the AI prompt the user submits for compression.

**User-generated content used:** The prompt text is compressed locally and/or via the Gemini API (with user awareness). If the user submits accept/reject feedback, the original and compressed prompt are stored to improve compression quality.

**Financial and payment information:** No.

**Health information:** No (but users may paste health information into prompts — see privacy policy).

**Personal communications:** No.

**Location:** No.

**Web history:** No.

**User activity:** Yes — aggregate counts of compressions performed (not individual prompt content).

---

## Certification

I certify that:

- [ ] LeanPrompt's use of user data complies with the Chrome Web Store User Data Policy.
- [ ] I have a privacy policy URL that accurately describes the data handling described above.
- [ ] Prompt text sent to cloud compression is disclosed to users before it is sent.
- [ ] Users can opt out of cloud compression by disabling API Assist in settings.

**[NOTE: Items 3 and 4 are not yet implemented. These are blockers before Chrome Store submission.]**

---

## Privacy Policy URL

[INSERT PUBLISHED PRIVACY POLICY URL]
