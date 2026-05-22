class LeanPromptBridgePayload {
  const LeanPromptBridgePayload({
    required this.originalPrompt,
    required this.optimizedPrompt,
    required this.tokenBefore,
    required this.tokenAfter,
    required this.host,
  });

  final String originalPrompt;
  final String optimizedPrompt;
  final int tokenBefore;
  final int tokenAfter;
  final String host;
}

abstract class LeanPromptBridge {
  Future<void> openOverlayIfSupported();
  Future<void> applyCompression(LeanPromptBridgePayload payload);
}
