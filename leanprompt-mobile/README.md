# LeanPrompt Mobile Companion (Flutter)

This is a cross-platform scaffold for a downloadable LeanPrompt mobile app.

## Goals

- **iOS Safari**: extension/share path for browser use.
- **Android**: accessibility-overlay path for native LLM apps and browsers.
- Shared Flutter UI for onboarding, auth handoff, token telemetry, and fallback manual compression.

## Current scaffold contents

- `lib/main.dart`: app bootstrap.
- `lib/src/ui/home_screen.dart`: starter screen.
- `lib/src/bridge/leanprompt_bridge.dart`: domain bridge contract.
- `lib/src/platform/platform_bridge_channel.dart`: method-channel bridge to native.

## Native implementation targets

### iOS

- Safari Web Extension + host app wrapper.
- Share Extension to push selected text into LeanPrompt.
- Optional custom keyboard extension for in-app text entry flows.

### Android

- Accessibility Service for detection/injection on supported LLM apps.
- Overlay permission flow (`SYSTEM_ALERT_WINDOW`) if using floating controls.
- Share Target fallback.

## Suggested next steps

1. Run `flutter create .` inside this folder to generate full iOS/Android runners.
2. Wire MethodChannel handlers:
   - `openOverlayIfSupported`
   - `applyCompression`
3. Add Supabase auth session handoff from extension/web to mobile.
4. Add host/app detection list and policy-safe allowlist.

## Notes

- iOS does not support Android-style global overlays across all apps.
- For iOS native LLM apps, prefer Share Extension / keyboard workflows.
