# Android implementation notes

Implement these pieces after generating the Android runner:

1. **Accessibility Service**
   - Detect supported hosts/apps (ChatGPT, Claude, Gemini).
   - Capture/edit focused text fields where permitted.

2. **Overlay controls (optional)**
   - Request overlay permission.
   - Show small floating LeanPrompt trigger.

3. **Share Target fallback**
   - Accept incoming text from any app.
   - Run compression and return via copy/share.

4. **MethodChannel handlers**
   - `openOverlayIfSupported`: open overlay or settings.
   - `applyCompression`: apply text replacement pipeline.

5. **Safety**
   - Keep explicit allowlist of packages/domains.
   - Respect user opt-in and clear enable/disable switches.
