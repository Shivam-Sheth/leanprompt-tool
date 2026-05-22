# Gemini learning system (on new prompts)

LeanPrompt learns from Gemini **automatically** — no batch labeling required for day-to-day use.

## Three layers

```text
User optimizes a NEW prompt
        │
        ▼
┌───────────────────────┐
│ 1. Learned cache      │  Same prompt signature seen before? → reuse Gemini text instantly (no API).
│    geminiLearnedStore │
└───────────┬───────────┘
            │ miss
            ▼
┌───────────────────────┐
│ 2. Offline engine     │  Rules + fast model + validation
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│ 3. Gemini teacher     │  Edge function `gemini-compress` → compress instruction only
└───────────┬───────────┘
            │
            ▼
     learnFromGeminiCompression()  ← stores (intent + signature) → text
            │
            ▼
     User Apply → reinforce cache + teacher_compressions row in Supabase
```

## When learning happens

| Event | What gets stored |
|--------|------------------|
| Gemini returns a shorter valid compression | `learnFromGeminiCompression(instruction, intent, text)` |
| User clicks **Apply** on a Gemini-backed result | Same (uses final/edited text if user changed it) |
| User rejects | Not learned (negative signal only in `teacher_compressions`) |

Storage: `chrome.storage.local` key `leanprompt_gemini_learned_v1` (max 2500 entries, LRU trim).

Lookup key: `intent + normalized signature` (numbers/quotes normalized — see `compressionSignature.ts`).

## Server-side (batch, optional)

- `teacher_compressions` table still receives every Apply/Reject for analytics and future retrain.
- Periodic: `npm run promote-and-retrain` merges approved **gold** into `public/models/fast_compression_model.json`.
- Nightly export (future): edge function `process-teacher-compressions` → `gold_compressions`.

## Files

| File | Role |
|------|------|
| `src/lib/compression/geminiLearnedStore.ts` | In-browser learned cache |
| `src/lib/compression/apiAssist.ts` | Calls Gemini + learns; skips API on cache hit |
| `src/lib/compression/optimizePrompt.ts` | Tries learned cache before rule engine |
| `src/content/index.ts` | Preloads cache; learns on Apply |

## Requirements

- **Gemini API** for *new* signatures: `GEMINI_API_KEY` in Supabase secrets (extension) and/or `.env.local` (training scripts).
- User does **not** need to run `label:gemini` for normal usage — only for offline benchmark / bulk training.

## What “accurate on new prompts” means here

- **Exact repeat** (same wording after normalization): uses cached Gemini output → matches teacher.
- **Novel wording**: still calls Gemini once, then learns that instance.
- **Gradual improvement**: more Applies → larger cache → fewer Gemini calls + better offline fast-model retrain from `teacher_compressions`.

This is the intended production loop; bulk Hugging Face datasets are optional for offline benchmark only.
