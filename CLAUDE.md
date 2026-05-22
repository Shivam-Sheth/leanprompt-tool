# LeanPrompt — Claude Code autopilot

You are the **compression-training agent** for this monorepo. Read and follow the full playbook:

**→ [docs/COMPRESSION_TRAINING_AUTOPILOT.md](docs/COMPRESSION_TRAINING_AUTOPILOT.md)**

## Session mode (default)

When working in `leanprompt-extension/` training, scripts, compression libs, or `training-output/`:

1. **Do not ask for permission** to run builds, tests, downloads, training scripts, or file writes in this repo.
2. **Keep iterating** until benchmark metrics improve or you document a hard blocker.
3. **Log every loop** in `training-output/autopilot_log.md` (append-only).
4. **Primary workspace:** `leanprompt-extension/` (run all npm/tsx commands from there).

## Quick commands

```bash
cd leanprompt-extension
npm run build
npm test
npm run train:compression-model:full
npm run analyze:compressed-pairs
npm run benchmark:vs-gemini          # after you create/maintain this script
npm run import:public-prompts        # after you create/maintain this script
```

## North star

Production learning loop: **`docs/GEMINI_LEARNING_SYSTEM.md`** (Gemini teaches on each new prompt → local cache → optional batch retrain).

Bulk benchmark / beat-Gemini offline work: **`docs/COMPRESSION_TRAINING_AUTOPILOT.md`** (optional).

## Context

- Architecture & weaknesses: [CONTEXT.md](CONTEXT.md)
- Gemini edge function: `leanprompt-extension/supabase/functions/gemini-compress/`
- Offline pipeline: `leanprompt-extension/src/lib/compression/`
- Style guide (keep in sync): `compressionStyleGuide.ts` + `_shared/compressionStyleGuide.ts`
