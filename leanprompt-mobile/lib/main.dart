import "package:flutter/material.dart";

import "src/ui/home_screen.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LeanPromptMobileApp());
}

class LeanPromptMobileApp extends StatelessWidget {
  const LeanPromptMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LeanPrompt Mobile",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      ),
      home: const HomeScreen(),
    );
  }
}
