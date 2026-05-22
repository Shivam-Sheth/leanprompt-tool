# iOS implementation notes

Implement these pieces after generating the iOS runner:

1. **Safari Web Extension host app**
   - Convert/export LeanPrompt browser extension for Safari.
   - Add auth + storage bridge to Flutter host app.

2. **Share Extension**
   - Receive selected text from Safari/other apps.
   - Send payload into Flutter app for compression and return/share back.

3. **MethodChannel handlers**
   - `openOverlayIfSupported`: noop or route to in-app flow.
   - `applyCompression`: cache payload and expose in app UI.

4. **Policy constraints**
   - No global overlays over third-party apps on iOS.
   - Use extension/share/keyboard flows instead.
