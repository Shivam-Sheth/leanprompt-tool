# LeanPrompt Compression Training — Master Autopilot Prompt

**Audience:** Claude Code (or any autonomous coding agent) in this repository.  
**Goal:** Download public prompt datasets, label/compress with Gemini, train/improve the offline model, benchmark offline vs Gemini, and iterate without stopping for permission until metrics improve—then execute the phased product roadmap.

---

## 0. Operating rules (non-negotiable)

1. **Autonomous execution** — Do not ask the user to confirm downloads, script runs, refactors, or test execution. Proceed unless a secret is missing (document the blocker and continue other work).
2. **Never destructive git** — No `git push --force`, no hard reset, no commit unless the user explicitly asked.
3. **Never commit secrets** — Do not write API keys into tracked files. Use env vars: `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`.
4. **Append a log every iteration** — `leanprompt-extension/training-output/autopilot_log.md`:
   ```markdown
   ## YYYY-MM-DD HH:MM — Iteration N
   - Actions taken:
   - Metrics (before → after):
   - Failures / blockers:
   - Next step:
   ```
5. **Stop condition for Phase A only** — Phase A loops until ALL hold on the held-out set (20% of benchmark rows):
   - `avg_jaccard_to_gemini` ≥ **0.85**
   - `validation_pass_rate` ≥ **0.95**
   - `offline_beats_gemini_rate` ≥ **0.55** (offline shorter AND validation ≥ gemini validation)
   - OR **50 iterations** with no metric improvement → write `training-output/phase_a_stalled.md` and move to Phase B anyway.
6. **Prefer small, testable diffs** — One hypothesis per iteration; always run tests after compression logic changes.

---

## 1. Repository map

| Path | Role |
|------|------|
| `leanprompt-extension/src/lib/compression/` | Offline compressor (rules, optimize, context split) |
| `leanprompt-extension/scripts/trainCompressionModel.ts` | Builds `fast_compression_model.json` from gold JSONL |
| `leanprompt-extension/scripts/promoteAndRetrain.ts` | Supabase gold → retrain → optional Storage upload |
| `leanprompt-extension/supabase/functions/gemini-compress/` | Gemini teacher API (server-side key) |
| `compressed_prompts_with_2000_edge_cases.json` | ~12k local gold pairs |
| `leanprompt_gold_dataset_10000.jsonl` | 10k gold (if present at repo root or extension dir) |
| `training-output/` | Metrics, DB, logs, imported data, benchmark reports |

---

## 2. Phase A — Data + benchmark loop (do this first)

### 2.1 Create / maintain tooling (build if missing)

Implement and keep improving these scripts under `leanprompt-extension/scripts/`:

#### `importPublicPrompts.ts`

- **Input:** Hugging Face datasets (download via `huggingface-cli` or HTTP; no Python required if you use direct JSONL URLs).
- **Priority sources (in order):**
  1. [PromptTensor/prompttensor-promptbank](https://huggingface.co/datasets/PromptTensor/prompttensor-promptbank) — CC-BY-4.0, ~7k, has `intent` + `constraints`
  2. `databricks/databricks-dolly-15k` — use `instruction` field
  3. Local: `../compressed_prompts_with_2000_edge_cases.json` + any `*.jsonl` gold in repo
- **Filter:** English, length 40–1200 chars, skip jailbreak/injection keywords (`ignore previous`, `DAN`, `jailbreak`, etc.).
- **Output:** `training-output/imported/public_prompts.jsonl` with schema:
  ```json
  { "original_text": "...", "intent": "question_answering", "source": "prompttensor|dolly|local", "constraints": [] }
  ```
- **Cap:** Start with 5k–10k rows for fast iteration; expand later.

#### `labelWithGemini.ts`

- For each `original_text` without `ideal_compressed`, call Gemini:
  - **Preferred:** `supabase functions invoke gemini-compress` with service role OR direct Google API using `GEMINI_API_KEY` + same system prompt as `supabase/functions/_shared/compressionStyleGuide.ts`
- **Rate limit:** Batch with delays; resume from checkpoint file `training-output/imported/label_checkpoint.json`.
- **Output:** `training-output/imported/gemini_labeled.jsonl`:
  ```json
  {
    "original_text": "...",
    "ideal_compressed": "...",
    "gemini_model": "gemini-2.5-flash",
    "intent": "...",
    "must_preserve": [],
    "must_not_happen": []
  }
  ```
- Run `validateCompression` from TS on each pair; drop rows with score < 0.75 or output longer than input.

#### `benchmarkVsGemini.ts`

- **Hold-out:** 20% stratified by `intent` (stable seed).
- For each row:
  1. `offline = optimizePrompt(original, "balanced", false)` (no live extension; import from src)
  2. `gemini =` cached `ideal_compressed` from labeled JSONL OR live Gemini call
  3. Score:
     - `jaccard(offline, gemini)`
     - `validateCompression(original, offline)` vs same for gemini
     - `token_reduction` for both
     - `offline_wins` = offline shorter AND offline validation ≥ gemini validation − 0.02
- **Output:**
  - `training-output/benchmark_report.json` (machine-readable)
  - `training-output/benchmark_report.md` (human comparison table by intent + worst 20 examples)
- **Print summary** to stdout every run.

#### `compareModelsReport.ts` (optional thin wrapper)

- Pretty-print side-by-side: `original | offline | gemini | winner` for N random samples.

Add npm scripts in `leanprompt-extension/package.json`:

```json
"import:public-prompts": "tsx scripts/importPublicPrompts.ts",
"label:gemini": "tsx scripts/labelWithGemini.ts",
"benchmark:vs-gemini": "tsx scripts/benchmarkVsGemini.ts"
```

### 2.2 Download workflow (run without asking)

```bash
cd leanprompt-extension
mkdir -p training-output/imported

# Example: HF CLI if available
# huggingface-cli download PromptTensor/prompttensor-promptbank --repo-type dataset --local-dir training-output/imported/prompttensor

npm run import:public-prompts
# If GEMINI_API_KEY or Supabase secrets exist:
npm run label:gemini
npm run train:compression-model:full -- training-output/imported/gemini_labeled.jsonl
npm run benchmark:vs-gemini
```

If `GEMINI_API_KEY` is missing: label using **existing** gold only, but still run benchmark comparing offline vs `ideal_compressed` from `compressed_prompts_with_2000_edge_cases.json` (treat ideal as Gemini proxy where gemini column absent).

### 2.3 Iteration loop (repeat until Phase A stop condition)

```
┌─────────────────────────────────────────────────────────┐
│ 1. Run benchmark:vs-gemini → save report                │
│ 2. Identify worst intent + worst prefix clusters        │
│     (use analyze:compressed-pairs patterns)             │
│ 3. Hypothesis-driven fix (pick ONE):                    │
│    - Add/fix rule in patterns.ts                        │
│    - Extend semanticFallback.ts                         │
│    - Fix rankCandidate / validateCompression weights      │
│    - Add fast_model templates from gemini_labeled       │
│    - Propose learned_rule via offline delta analysis    │
│ 4. npm test && npm run benchmark:vs-gemini              │
│ 5. If metrics improved → keep; else revert              │
│ 6. npm run train:compression-model with new gold        │
│ 7. Append autopilot_log.md                              │
└─────────────────────────────────────────────────────────┘
```

**Do not** spend iterations only tweaking regex counts without re-running benchmark.

### 2.4 Comparison report format (required for user)

End each Phase A session block by updating `training-output/benchmark_report.md` with:

| Metric | Offline | Gemini (teacher) |
|--------|---------|------------------|
| Avg Jaccard (offline vs gemini text) | | N/A |
| Avg validation score | | |
| Avg token reduction % | | |
| % offline wins (shorter + valid) | | |
| % exact match to teacher | | |

Plus **top 3 intents improved** and **top 3 still failing**.

---

## 3. Phase B — Product roadmap (after Phase A metrics or stall)

Execute in order; do not skip tests.

### B1 — Teacher flywheel (week 1–2 equivalent)

- Edge function or script: export `teacher_compressions` → `gold_compressions` with label priority: `user_edited` > applied gemini > gemini_output.
- Wire into `promoteAndRetrain.ts` dataset merge.
- Cron doc: nightly batch (Supabase scheduled function or GitHub Action).

### B2 — Context / reference integrity (week 2–3)

- Harden `compressPrompt.context.ts`:
  - Same-line split after `:\s+` when head matches instruction patterns
  - Single-paragraph body (>200 chars) without requiring 2 body lines
  - Post-check: if `instructionContextText` changed in output → restore verbatim
- Add `src/tests/contextSplit.fixture.test.ts` with ≥50 cases (include restaurant paste case).

### B3 — Replace purple highlight beta (week 3–4)

- Default: auto-split only; highlight beta off
- On paste >200 chars: auto-insert `\n\n---\n\n` between instruction and paste OR show chip “Compressing: lines 1–2 [Edit]”
- Manual selection: document in panel; do not fight browser native blue selection with overlay mirrors on Gemini/ChatGPT

### B4 — Shadow mode + flip default (week 6+)

- Log `offline_would_win` in compression trace (no UI)
- Flip to offline-first when `offline_beats_gemini_rate` ≥ 0.60 for 7 days in benchmark + production logs

### B5 — Neural compressor (optional, long)

- Distill (original → gemini) to ONNX; runtime in extension behind flag

---

## 4. Quality gates (CI-minded)

Before claiming improvement:

```bash
cd leanprompt-extension
npm run build
npm test
npm run benchmark:vs-gemini
```

Add `src/tests/geminiCompress.test.ts` cases when changing selection logic.

**Regression:** Fail iteration if `validation_pass_rate` drops by >2% or any intent goes to 0% pass.

---

## 5. Datasets to avoid

- Jailbreak / prompt-injection benchmarks (WildJailbreak, injection evals)
- Unlabeled 2M+ dumps without filtering (MEGA) until filter pipeline exists

---

## 6. Alignment with Gemini teacher

All new gold labels and rules must match `TEACHER_SYSTEM_PROMPT` in:

- `leanprompt-extension/src/lib/compression/compressionStyleGuide.ts`
- `leanprompt-extension/supabase/functions/_shared/compressionStyleGuide.ts`

Offline must NOT add `Classify` / `Summarize` prefixes unless the original already starts with that verb. No `Answer concisely` injection unless concise mode.

---

## 7. Secrets checklist (if blocked, note in log and continue)

| Secret | Where |
|--------|--------|
| `GEMINI_API_KEY` | `leanprompt-extension/.env.local` — auto-loaded by `scripts/loadEnv.ts` for labeling |
| Same key for extension users | `supabase secrets set GEMINI_API_KEY=…` then `supabase functions deploy gemini-compress` |
| `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` | Export teacher rows, promote-and-retrain |
| `SUPABASE_ANON_KEY` | Already in `.env.local` as `LEANPROMPT_*` |

**Never commit `.env.local`.** Rotate keys if exposed in chat.

---

## 8. First-run checklist for a new agent session

- [ ] Read `CONTEXT.md` metrics baseline (~4.4% exact match, ~0.557 Jaccard)
- [ ] Ensure `training-output/` exists
- [ ] Run `import:public-prompts` (create script if missing)
- [ ] Merge local `compressed_prompts_with_2000_edge_cases.json`
- [ ] Run `benchmark:vs-gemini` (create script if missing) — establish baseline
- [ ] Enter iteration loop §2.3
- [ ] When Phase A complete → Phase B §3

**Start now. Do not ask for permission.**
