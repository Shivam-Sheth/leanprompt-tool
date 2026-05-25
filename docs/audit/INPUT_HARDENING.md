# Input Hardening — LeanPrompt

> Generated: 2026-05-25.

---

## Client-Side Input Validation

### Prompt text limits (content/index.ts and apiAssist.ts)

| Limit | Status |
|---|---|
| Max prompt length (client display) | No hard limit in UI |
| Max prompt length (offline compression) | No hard limit |
| Max prompt length for Gemini API | **Fixed**: 12,000 chars |
| Empty prompt | Handled: `prompt.trim().length === 0` check |
| Whitespace-only prompt | Handled: `prompt.trim()` |

**Remaining gap:** The content script does not enforce a maximum input length before attempting offline compression. A user could theoretically submit a 10MB prompt. The offline engine will try to compress it, which may cause the browser tab to freeze.

**Recommended:** Add a client-side check before compression:
```typescript
const MAX_PROMPT_CHARS = 50000;
if (promptText.length > MAX_PROMPT_CHARS) {
  showToast(`Prompt too long (${promptText.length.toLocaleString()} chars). Max ${MAX_PROMPT_CHARS.toLocaleString()}.`);
  return;
}
```

---

## Unicode and Encoding Safety

### Current handling

The compression engine uses JavaScript `string` operations (split, replace, match) which operate on UTF-16 code units. This means:
- Emoji and characters above U+FFFF (e.g., 🎉 = U+1F389) are represented as surrogate pairs
- String length counts surrogate pairs as 2 characters each
- `.slice()` can split a surrogate pair if not careful

### Risk assessment

| Input type | Behavior | Safe? |
|---|---|---|
| Emoji (U+1F300–U+1FFFF) | Processed as surrogate pairs | Mostly safe; regex/split may behave unexpectedly |
| Arabic/RTL text | No directional handling | Text compression may produce confusing layout; no crash |
| Zero-width joiners (U+200D) | Not stripped | May produce unexpected output |
| Null bytes (U+0000) | Not handled | May corrupt stored text |
| Control characters (U+0001–U+001F) | Not stripped | May corrupt stored text |

**Recommended sanitization** (add to `compressPrompt.ts` `normalize()` function):
```typescript
function normalize(text: string): string {
  return text
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "") // Strip control chars
    .replace(/\s+/g, " ")
    // ... existing normalization
    .trim();
}
```

---

## XSS Prevention

### Status of fixes

| Location | Vector | Status |
|---|---|---|
| `content/index.ts` line 1359 | `fileNames` from CustomEvent in innerHTML | **FIXED** — `map(escapeHtml)` |
| `content/index.ts` line 1524 | `geminiErr` from API response in innerHTML | **FIXED** — `escapeHtml()` |
| `content/index.ts` line 1554 | `result.optimizedText` in textarea innerHTML | **FIXED** — set via `.value` property |
| `content/index.ts` line 1613 | `fileUploadState.names` in innerHTML | **FIXED** — `map(escapeHtml)` |
| `content/instructionHighlight.ts` line 127 | User textarea content in innerHTML | **Safe** — `escapeHtml()` already applied |
| `popup/index.ts` | Static HTML only | Safe |
| `options/index.ts` | Static HTML only | Safe |

### Remaining innerHTML uses (verified safe)

All remaining `innerHTML` assignments in `content/index.ts` use:
- Static HTML strings with no user-controlled data
- Integer values from local state (token counts) — not injectable
- Enum values from the intent classifier (fixed set of strings)

---

## SQL Safety

All database operations use the Supabase client ORM with parameterized queries. No raw SQL string concatenation found in application code (only in SQL migration files, which is expected).

---

## JSON Safety

- All API payloads use `JSON.stringify(body)` for serialization
- All API responses use `await req.json()` with try/catch
- No `eval(jsonString)` or `new Function(string)` found

---

## Weird Input Test Matrix

| Input | Offline compress | Gemini compress | UI display |
|---|---|---|---|
| Emoji: 🎉🧠💻 | Passes (regex-safe) | Passes | textContent safe |
| RTL: مرحبا | Passes | Passes | No crash, layout may be unexpected |
| Empty string | Returns original | Rejected client-side | Shows toast |
| 100k chars | May be slow | Rejected (>12k) | No limit — add client limit |
| `<script>alert(1)</script>` | Compresses text | Returns compressed | **FIXED** — escaped in textarea |
| `</textarea><img onerror=...>` | Compresses text | Returns compressed | **FIXED** — .value set |
| `'; DROP TABLE--` | Compresses text | Returns compressed | Safe — no SQL usage in UI |
| Null bytes | Passes through | API may reject | Stored in DB — may corrupt |
| 4096 emoji | Slow | Rejected | May freeze UI |
| Zero-width chars | Passes through | Passes | No visible effect |
