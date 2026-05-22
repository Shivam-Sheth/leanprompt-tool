import "package:flutter_test/flutter_test.dart";

import "package:leanprompt_mobile/main.dart";

void main() {
  testWidgets("app loads home screen", (WidgetTester tester) async {
    await tester.pumpWidget(const LeanPromptMobileApp());
    expect(find.text("LeanPrompt"), findsOneWidget);
    expect(find.text("Quick optimize"), findsOneWidget);
  });
}
