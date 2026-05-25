# Data Retention Policy — LeanPrompt

> Generated: 2026-05-25. **Not yet implemented in code. All items are policy targets.**
> LEGAL REVIEW REQUIRED before publishing.

---

## Policy Summary

| Data type | Retention target | Current enforcement | Action needed |
|---|---|---|---|
| `prompt_feedback` rows (original_text, optimized_text) | 90 days | None | Implement deletion job |
| `teacher_compressions` rows | 90 days | None | Implement deletion job |
| `gold_compressions` (approved) | 2 years (benchmark data) | None | Implement deletion job with exception for approved |
| `learned_rules` (approved) | 2 years | None | Keep approved rules; delete pending/rejected after 30 days |
| `user_profiles` | Until account deletion | None | Cascade delete on auth.users row delete |
| `prompt_feedback_agent_runs` | 30 days | None | Implement deletion job |
| Auth tokens | Until session expiry (Supabase default) | Supabase managed | No action needed |
| Extension local feedback queue | 500 items rolling window | Implemented (`.slice(-500)`) | Consider time-based expiry also |

---

## Retention Implementation Plan

### Step 1: Add `pg_cron` deletion job

```sql
-- Install pg_cron (Supabase supports this)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Delete prompt_feedback older than 90 days (keep only metadata, not content)
SELECT cron.schedule(
  'delete-old-prompt-feedback',
  '0 2 * * *',  -- 2am UTC daily
  $$
  DELETE FROM public.prompt_feedback
  WHERE created_at < now() - interval '90 days';
  $$
);

-- Delete teacher_compressions older than 90 days
SELECT cron.schedule(
  'delete-old-teacher-compressions',
  '0 2 * * *',
  $$
  DELETE FROM public.teacher_compressions
  WHERE created_at < now() - interval '90 days';
  $$
);
```

### Step 2: Anonymize instead of delete (alternative)

Instead of deleting rows (which loses training signal), anonymize by setting `original_prompt` and `optimized_text` to NULL after the retention period:

```sql
UPDATE public.prompt_feedback
SET original_text = '[REDACTED]', optimized_text = '[REDACTED]'
WHERE created_at < now() - interval '90 days'
  AND original_text != '[REDACTED]';
```

### Step 3: User account deletion RPC

```sql
CREATE OR REPLACE FUNCTION public.delete_user_data(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.prompt_feedback WHERE user_id = p_user_id;
  DELETE FROM public.teacher_compressions WHERE user_id = p_user_id;
  DELETE FROM public.user_profiles WHERE id = p_user_id;
  -- Auth user deletion is handled separately by Supabase admin API
END;
$$;
```

---

## User Data Deletion Flow (UI)

**Not yet implemented.** Required before public launch.

1. User opens Extension Options → "Account" tab → "Delete my data"
2. Shows confirmation dialog: "This will permanently delete all your compression history. This cannot be undone."
3. On confirm: calls background → `supabase.rpc('delete_user_data', {p_user_id: user.id})`
4. Then calls Supabase admin API to delete the auth user (requires service role — must be done via edge function, not from extension directly)
5. Signs user out locally

**Note:** Supabase's `auth.users` table has `on delete cascade` set up in `user_profiles`, but `prompt_feedback` uses `on delete set null` (user_id becomes null). This means prompt content persists even after account deletion. The `delete_user_data` RPC above is needed to actually delete the content rows.
