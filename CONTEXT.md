# LeanPrompt — Full Context Reference

Use this document to understand what LeanPrompt is, how it works end-to-end, what every file does, and where the current weaknesses are.

---

## What Is LeanPrompt?

LeanPrompt is a Chrome extension that compresses AI prompts before the user sends them. The idea: most prompts have 30–55% filler — "can you please", "I want you to", "tell me about" — that costs tokens without changing the LLM's answer. LeanPrompt strips this algorithmically, with no external API call, entirely in the browser.

**Primary user action:**
1. User types a prompt in ChatGPT, Claude, Gemini, etc.
2. A floating "lp" button appears near the input box
3. User clicks it → a panel shows the compressed version, token savings, cost estimate
4. User clicks Apply (replaces their prompt) or Reject (feedback collected)

**Secondary features:**
- Concise toggle: compresses even more aggressively (grammar-free noun-phrase form) + tells the AI to reply briefly
- File upload token estimation: warns when attached files + prompt exceed context window
- Usage tracking: free tier = 80 optimizations/month, Pro = unlimited
- Feedback loop: rejected compressions flow back to Supabase → LLM analysis → new rule proposals → auto-promoted into the model

---

## Monorepo Structure

```
LeanPromptTool/
├── leanprompt-extension/          ← Chrome extension (main codebase)
├── leanprompt-mobile/             ← Flutter mobile app (not yet active)
├── compressed_prompts_with_2000_edge_cases.json  ← Training data (see below)
└── .github/workflows/retrain-model.yml           ← Auto-retrain CI
```

---

## Extension Source Files

### Entry Points

| File | Purpose |
|------|---------|
| `src/content/index.ts` | Main content script (~2000 lines). Injected into every AI chat page. Detects the text input, injects the LP button and concise toggle, runs optimization on click, shows the panel, records feedback. All UI logic lives here. |
| `src/background/index.ts` | MV3 service worker. Owns the single authoritative Supabase client. Handles all auth operations (login, signup, Google OAuth, session refresh via 50-min alarm) via message passing from other contexts. |
| `src/popup/index.ts` | Extension icon popup. Shows signed-in dashboard (usage, plan) or login/signup form. Routes all auth through the background via `messagingClient`. |
| `src/options/index.ts` | Settings page (chrome://extensions → details → extension options). Shows compression level, feature toggles. No Supabase credential fields — those are baked in at build time. |

### Compression Pipeline

| File | Purpose |
|------|---------|
| `src/lib/compression/optimizePrompt.ts` | **Main orchestrator.** Runs 15 iterative passes, trying fast model → rule engine → semantic fallback across multiple compression levels and prompt variants. Ranks all candidates by `(validation_score × intent_weight) + reduction_bonus + overlap_tiebreaker`. Returns the best. Never returns a result longer than the input. |
| `src/lib/compression/compressPrompt.ts` | **3-path compressor.** Path 1: structured assignment (preserve section headers, compress intro filler). Path 2: rule engine (patterns.ts). Path 2.5: semantic fallback. Path 3: conservative phrase replacement. |
| `src/lib/compression/nanoCompress.ts` | **Concise-mode compressor.** Grammar-free, noun-phrase output. "Explain the difference between petrol cars and diesel cars" → "petrol/diesel cars difference". Uses comparison detection + entity extraction + shared-suffix merging. Returns null when it can't help (falls through to rule engine). |
| `src/lib/compression/rules/patterns.ts` | **~2200 lines of hand-crafted compression rules.** Each rule: `{id, intent, pattern (regex), build() fn, priority (50–300), examples}`. Higher priority wins. Sources: "seed" (hand-written) and "learned" (LLM-proposed via feedback loop). |
| `src/lib/compression/rules/helpers.ts` | Utility functions used by rule build() functions: `sc()` (sentence-case), `conciseSubjectQuestion()`, `learningTopic()`, etc. |
| `src/lib/compression/semanticFallback.ts` | Handles 4 conversational patterns algorithmically: "I am at [PLACE], I want to know how to [VERB]", "I want to know more about [TOPIC]", "How should I go about [GERUND]?", "I'm a [ROLE] at [PLACE], [REQUEST]". Has 100+ irregular gerund→infinitive conversions. |
| `src/lib/compression/fastModel.ts` | **Template lookup model.** On extension load, fetches `public/models/fast_compression_model.json` (bundled) and tries Supabase Storage for a newer version (1-hour cache TTL). Normalizes prompt signatures, looks up by (intent, signature). Consulted first in every optimization pass if validation score ≥ 0.75. |
| `src/lib/compression/removeFillerPhrases.ts` | First-pass filler removal. Strips "please", "can you", "I want you to", "would you mind", etc. |
| `src/lib/compression/autoCorrect.ts` | Spell-checks the prompt before compression (uses nspell + dictionary-en). Sync, offline. |
| `src/lib/compression/compressPrompt.context.ts` | Detects and separates embedded context blocks (e.g. "summarize the following: [big paste]") so only the instruction gets compressed, not the content. |

### Intent & Constraints

| File | Purpose |
|------|---------|
| `src/lib/intent/detectIntent.ts` | Classifies prompt into one of 15 intents via regex: `summarization`, `classification`, `extraction`, `rewriting_paraphrasing`, `code_debugging`, `code_explanation`, `code_generation`, `email_drafting`, `brainstorming`, `question_answering`, `translation`, `analysis`, `creative_writing`, `general_instruction`, `structured_assignment`. Intent affects which compression rules fire and how candidates are ranked. |
| `src/lib/constraints/extractConstraints.ts` | Extracts explicit requirements from the prompt. 4 categories: `outputFormat` (bullet_points, json, table, concise, step_by_step, markdown, one_sentence...), `tone` (professional, formal, casual, beginner_friendly...), `labels` (true/false, positive/negative...), `explicit` ("under 200 words", "preserve examples"...). Constraints are appended as suffix imperatives ("Be concise. Use bullet points.") so they survive compression. |

### Validation

| File | Purpose |
|------|---------|
| `src/lib/validation/validateCompression.ts` | Scores a compression 0–1. Checks: (1) intent anchor present (−0.15 if missing), (2) ≥40% significant-token overlap (−0.25 if below), (3) protected entities preserved — quoted text, numbers, proper nouns (−0.12 per missing, max −0.45), (4) explicit constraints not dropped (−0.1 per dropped). Must score ≥ 0.7 to be considered valid. Used to rank candidates and filter out bad outputs. |

### Auth

| File | Purpose |
|------|---------|
| `src/lib/auth/supabaseBrowser.ts` | Creates and caches the Supabase JS client. Uses `chromeLocalAuthStorage` so sessions survive popup close/reopen. `autoRefreshToken: false` in service worker (uses alarm instead), `true` in UI contexts. PKCE flow. |
| `src/lib/auth/chromeAuthStorage.ts` | Custom Supabase storage adapter backed by `chrome.storage.local`. Makes sessions persist across popup opens and extension restarts. |
| `src/lib/auth/client.ts` | Auth operations (login, signup, logout, Google OAuth via `chrome.identity.launchWebAuthFlow`). Called directly by the background service worker. |
| `src/lib/auth/messagingClient.ts` | Popup/content-script side of auth messaging. Routes all auth calls to the background via `chrome.runtime.sendMessage` so only the background owns a Supabase client. Functions: `getCurrentUserFromBackground`, `getAuthStateFromBackground`, `loginThroughBackground`, `signupThroughBackground`, `googleSignInThroughBackground`. |
| `src/lib/auth/supabaseCredentials.ts` | Reads Supabase URL + anon key. Priority: chrome.storage.sync override → build-time env (`__LEANPROMPT_BUILD__`). Validates URL format. |
| `src/lib/auth/validateSessionEdge.ts` | Pings the `validate-session` edge function to check server-side session validity. Stale-check: only pings once per session tab. |

### Feedback & Learning Loop

| File | Purpose |
|------|---------|
| `src/lib/feedback/promptFeedback.ts` | Queues feedback locally in `chrome.storage.local` (max 500 items). Each item: original, optimized, edited, intent, validation score, reduction %, site, action (applied/rejected), rejection category, matched rule ID. |
| `src/lib/feedback/promptFeedbackBridge.ts` | Bridges content script → background for feedback recording (content scripts can't write to Supabase directly). |

### Metrics & Config

| File | Purpose |
|------|---------|
| `src/lib/metrics/estimation.ts` | Token estimation (GPT-3/4 tokenizer approximation), cost estimation (GPT-4o pricing), carbon estimation. All offline, no API call. |
| `src/lib/billing/plan.ts` | Free/Pro plan logic. Free limit: 80 optimizations/month. Checks usage count from user_metadata. |
| `src/lib/config/buildEnv.ts` | Reads `__LEANPROMPT_BUILD__` (injected by build script). Contains Supabase URL + anon key baked in at build time. |
| `src/lib/storage/settings.ts` | Reads/writes user settings from `chrome.storage.sync`: compression level, auto-optimize, show inline metrics, enabled sites (chatgpt/claude/gemini), history opt-in. |
| `src/content/siteDetection.ts` | Determines whether LeanPrompt should activate on a given page. Explicit support for chatgpt.com, claude.ai, gemini.google.com. Heuristic detection for other AI tools via hostname hints ("openai", "gpt", "copilot", ".ai" TLD, etc.) and path hints (/chat, /assistant). Explicit blocklist for Gmail, Outlook, Google Docs, Notion, etc. |
| `src/content/fileIntercept.ts` | Intercepts file uploads to estimate token cost of attachments before they're sent. |

---

## Supabase Backend

### Database Tables

| Table | Purpose |
|-------|---------|
| `prompt_feedback` | Every optimization event: original, optimized, action (applied/rejected), intent, validation score, reduction %, matched rule ID, rejection category/reason, ideal_output (backfilled by LLM). |
| `prompt_feedback_agent_runs` | Log of each LLM analysis batch: status, model used, summary, proposed rules, proposed dataset. |
| `learned_rules` | LLM-proposed rules waiting for promotion. Columns: rule_id, intent, pattern_source (JS regex), build_template, priority, examples, status (pending/approved/rejected), auto_promoted, confidence_score, promotion_notes. |
| `gold_compressions` | Ground-truth (original, expected_output) pairs. Used as benchmark and training data. Status: pending/approved/rejected. |
| `rule_metrics` | Per-rule applied/rejected counts. Used to identify rules that frequently produce rejected outputs. |
| `model_builds` | Build history: pending → running → completed/failed. Created when ≥5 items are auto-promoted. Triggers GitHub Actions retrain. |
| `user_profiles` | User plan (free/pro), monthly_usage_count. |

### Edge Functions

| Function | Purpose |
|----------|---------|
| `process-prompt-feedback` | Triggered when ≥100 rejections accumulate OR any rejection is >1hr old. Sends batch to GPT-4.1-mini for analysis. LLM outputs: ideal_output per rejection, proposed learned_rules (need ≥3 matching examples), proposed gold_compressions. Writes results to DB, then calls `promote-learned-rules` (fire-and-forget). |
| `promote-learned-rules` | Auto-promotes pending learned_rules that pass quality checks (regex compiles, ≥3 examples, ≥67% match rate, valid capture group refs, priority in range) and gold_compressions (shorter than original, must_contain tokens present). Sets confidence_score. When ≥5 items newly promoted, creates a model_builds record and dispatches `retrain-model` event to GitHub Actions. |
| `validate-session` | Validates a user's session server-side. Pinged by the extension on first interaction per session. |

### Migrations (in order)

| File | What it adds |
|------|-------------|
| `001_prompt_feedback.sql` | Base schema: prompt_feedback, prompt_feedback_agent_runs. RLS policies. |
| `002_user_profiles.sql` | user_profiles table (plan, usage count). |
| `003_increment_usage_stats.sql` | RPC function to atomically increment usage count. |
| `004_feedback_learning_loop.sql` | learned_rules, gold_compressions, rule_metrics tables. |
| `005_anon_feedback_ideal_output.sql` | Allows anonymous feedback inserts. Adds ideal_output column to prompt_feedback. |
| `006_auto_promotion.sql` | Adds auto_promoted, confidence_score, promotion_notes columns. Adds model_builds table. |

---

## Training Pipeline

### Data Sources

| File | Description |
|------|-------------|
| `leanprompt_gold_dataset_10000.jsonl` | 10,000 hand-curated (original, ideal_compressed) pairs. Each row: original_text, ideal_compressed, intent, must_preserve[], must_not_happen[]. |
| `compressed_prompts_with_2000_edge_cases.json` | ~12,000 pairs (10,000 base + 2,000 edge cases). Edge case categories: code_context, embedded_constraints, implicit_role, multi-topic, nested_questions, coreference. |

### Scripts

| File | Purpose |
|------|---------|
| `scripts/trainCompressionModel.ts` | Reads gold JSONL, runs current engine on each row, computes Jaccard similarity between engine output and ideal. Groups by (intent, normalized signature) → up to 5,000 templates in `fast_compression_model.json`. Templates with ≥2 samples and avg similarity ≥0.55 are kept. |
| `scripts/promoteAndRetrain.ts` | Downloads all approved gold_compressions from Supabase, merges with local datasets, runs trainCompressionModel, optionally uploads new model to Supabase Storage. Marks model_builds record as completed. |
| `scripts/analyzeCompressedPairs.ts` | Reports failure rate and top failure prefixes. Used to identify which patterns the engine handles poorly. |

### CI

| File | Purpose |
|------|---------|
| `.github/workflows/retrain-model.yml` | Triggered by `repository_dispatch` event `retrain-model` (fired by `promote-learned-rules` edge function when ≥5 items are promoted) or manually via GitHub UI. Runs `promoteAndRetrain.ts` with `UPLOAD_TO_STORAGE=true`. New model is available to users within ~1 hour (fastModel.ts checks Supabase Storage on load with 1-hour TTL). |

---

## Current Optimizer Performance — Honest Assessment

### Numbers

| Metric | Value |
|--------|-------|
| Training rows | 14,295 |
| Exact match rate (engine = ideal) | **4.4%** |
| Average Jaccard similarity | **0.557** (1.0 = perfect, 0 = totally different) |
| Engine avg reduction | 21.3% |
| Ideal avg reduction | 31.6% |
| Failure rate on base dataset | **30.4%** (3,045 / 10,000 pairs failed similarity threshold) |
| Failure rate on edge cases | **30.1%** (602 / 2,000 edge case pairs failed) |

### What "failure" means here
A compression is marked failed when Jaccard similarity between engine output and ideal output is below 0.38, meaning the words the engine kept are significantly different from the words the ideal keeps. The engine isn't producing garbage — it's just picking different words to keep, often in a different order or with different stopword decisions.

### Worst categories

| Category | Failure rate |
|----------|-------------|
| Code context ("in Spring Boot + Redis...") | 58% |
| Embedded constraints ("write me something professional") | 53% |
| Implicit role ("I'm a CS grad...") | 54% |
| Multi-topic | 8% (actually decent) |
| Nested questions | 5% (good) |
| Coreference | 4% (good) |

### Root causes

**1. The rule engine is too rigid.**
Rules are hand-written regexes. They cover common patterns well ("tell me about X" → "X overview") but fail when the prompt structure deviates even slightly. The ~2,200 rules in `patterns.ts` look large but most are domain-specific (fitness, food, coding). The long tail of conversational/personal prompts ("I'm a CS grad, I'm going through a career change...") mostly fall through to the conservative fallback which does almost nothing useful.

**2. The fast model is a template lookup, not a real model.**
`fast_compression_model.json` stores ~2,500 (signature → ideal) pairs keyed by normalized prompt signature. This only helps when the user types a prompt that nearly exactly matches something in the training set. On novel prompts it contributes nothing.

**3. No true NLP.**
There's no part-of-speech tagger, no dependency parser, no semantic role labeling. The "semantic fallback" handles 4 hand-coded patterns. Entity extraction is regex-based. The engine cannot reliably identify the subject/verb/object of an arbitrary sentence, which is what you'd need to reliably compress it.

**4. The nano compressor (concise mode) is new and narrow.**
`nanoCompress.ts` handles comparison ("explain the difference between X and Y" → "X/Y difference") and multi-topic info requests ("tell me about A and B" → "A + B info"). This is good for simple queries but it also returns null for most prompts and falls through to the standard pipeline.

**5. Training data quality is mixed.**
Some ideal_compressed examples in the training JSON are themselves poor compressions. For example: `"any tips for a step by step plan for cold war"` → `"Cold war i need something practical — practical."` — this ideal is nonsensical. The LLM that generated the training data made mistakes, and those mistakes are now baked into the gold dataset and the fast model templates.

### What would actually fix it

- A lightweight neural sequence model (distilled BERT encoder → compressed token sequence) trained on clean gold data, running in the browser via ONNX/WebNN — this is the real long-term solution
- Better training data curation — filter out the ~15-20% of gold pairs where the ideal is clearly wrong
- More comprehensive semantic fallback patterns covering the top failure prefixes (implicit role prompts are the biggest win: "I'm a [ROLE], [REQUEST]" → "[REQUEST] for [ROLE]")
- Better entity extraction to identify what the user is actually asking about, independent of sentence structure

---

## Key Design Decisions

**Everything runs offline.** Compression, validation, intent detection, token estimation — zero network calls. The only network calls are: auth (Supabase), feedback sync (Supabase), remote model check (Supabase Storage, 1-hour TTL). A user with no internet still gets compression.

**Feedback loop is fully automated.** User rejects → batch analysis by GPT-4.1-mini → rules auto-promoted if quality checks pass (≥3 examples, ≥67% match rate, valid regex) → GitHub Actions retrain fires → new model available to all users within ~1hr. Zero manual steps.

**Validation gates everything.** Even if the rule engine produces a short output, it only gets used if `validateCompression` scores ≥ 0.70. This prevents destroying prompts with valid-looking but semantically broken compressions.

**The concise toggle is distinct from the main optimizer.** When ON: (a) nano compressor runs first (grammar-free, more aggressive), (b) every prompt gets `[Reply concisely — minimum words, no filler]` prepended to tell the AI to respond briefly too. When OFF: the standard pipeline runs, and on the first prompt of a session `"Answer concisely. Use the fewest words..."` is prepended once.

---

## Environment & Build

- **Runtime**: Chrome MV3 extension. TypeScript, bundled with esbuild.
- **Auth**: Supabase Auth (email/password + Google OAuth via chrome.identity)
- **Database**: Supabase Postgres
- **Edge functions**: Deno (Supabase Edge Functions)
- **Training scripts**: Node.js + tsx (TypeScript execution), better-sqlite3 for local training DB
- **Build-time env**: `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env.local` → injected as `__LEANPROMPT_BUILD__` global by `scripts/build.mjs`
- **Supported sites**: ChatGPT, Claude, Gemini (explicit). Detected heuristically: any `.ai` TLD domain, any hostname containing "openai", "gpt", "copilot", "llm", "chatbot", "assistant", "perplexity", "mistral", "grok", "deepseek", "huggingface", "openrouter". Explicit blocklist prevents activation on Gmail, Outlook, Google Docs, Notion, etc.
