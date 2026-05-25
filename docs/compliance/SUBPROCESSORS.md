# LeanPrompt Subprocessors

> Updated: 2026-05-25. Verify before publication.

These are the third-party services that receive or process user data on behalf of LeanPrompt.

| Service | Purpose | Data Received | Region | Privacy Policy |
|---|---|---|---|---|
| **Supabase** | Database, authentication, edge functions | Email, user ID, prompt feedback (original + compressed text), usage stats, auth tokens | US (AWS us-east-1) | supabase.com/privacy |
| **Google Gemini API** | Cloud prompt compression (when API Assist enabled) | Raw prompt text submitted for compression | Google global infrastructure | policies.google.com/privacy |
| **OpenAI** | Compression pattern analysis (automated, from rejected feedback) | Original and compressed prompts from rejected feedback rows | US | openai.com/policies/privacy |
| **Vercel** | Web app hosting (lean-prompt.vercel.app) | Server access logs (IP address, user agent, request path) | US | vercel.com/legal/privacy |
| **GitHub** | Model retraining CI/CD trigger | Non-personal metadata only (rule counts, build trigger event) | US | docs.github.com/en/site-policy/privacy-policies |

---

## Notes

**Opt-out implications:**
- Disabling "API Assist" in extension settings prevents Gemini from receiving your prompts.
- Disabling feedback (History toggle) prevents prompts from being stored in Supabase or sent to OpenAI for analysis.
- Deleting your account removes your stored data from Supabase.

**OpenAI training opt-out:** OpenAI has mechanisms for API customers to opt out of their data being used for model training via their API settings. LeanPrompt should verify and document whether opt-out is configured.

**Gemini training opt-out:** Google's standard API terms apply to prompts sent to Gemini. LeanPrompt should verify and document Google's data retention and training policies for API usage.

**[LEGAL REVIEW NEEDED: If serving EU users, standard contractual clauses (SCCs) or DPA agreements with each subprocessor may be required under GDPR Article 28.]**
