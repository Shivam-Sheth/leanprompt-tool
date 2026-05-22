import "dart:io";

import "package:flutter/services.dart";

import "../bridge/leanprompt_bridge.dart";

class PlatformBridgeChannel implements LeanPromptBridge {
  static const MethodChannel _channel = MethodChannel("leanprompt/mobile_bridge");

  @override
  Future<void> openOverlayIfSupported() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _channel.invokeMethod("openOverlayIfSupported");
  }

  @override
  Future<void> applyCompression(LeanPromptBridgePayload payload) async {
    await _channel.invokeMethod("applyCompression", {
      "originalPrompt": payload.originalPrompt,
      "optimizedPrompt": payload.optimizedPrompt,
      "tokenBefore": payload.tokenBefore,
      "tokenAfter": payload.tokenAfter,
      "host": payload.host,
    });
  }
}
