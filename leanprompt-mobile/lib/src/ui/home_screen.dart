import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedStyle = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F8F8), Color(0xFFEFEFEF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "LeanPrompt Preview",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "ChatGPT and Claude inspired layouts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedStyle,
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Split"),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("ChatGPT"),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Claude"),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStyle = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (_selectedStyle) {
                      1 => const _ChatGptPreview(key: ValueKey("chatgpt")),
                      2 => const _ClaudePreview(key: ValueKey("claude")),
                      _ => const _SplitPreview(key: ValueKey("split")),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitPreview extends StatelessWidget {
  const _SplitPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _ChatGptPreview()),
        SizedBox(width: 10),
        Expanded(child: _ClaudePreview()),
      ],
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(color: backgroundColor, child: child),
        ),
      ),
    );
  }
}

class _ChatGptPreview extends StatelessWidget {
  const _ChatGptPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      backgroundColor: const Color(0xFFF6F7F8),
      child: Column(
        children: [
          const _StatusBarMock(textColor: Colors.black87),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(CupertinoIcons.line_horizontal_3, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Chat",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10A37F),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: const [
                _Bubble(
                  text: "Write a concise launch message for LeanPrompt.",
                  isUser: true,
                  userColor: Color(0xFF10A37F),
                ),
                _Bubble(
                  text: "Here is a friendly short version with clear CTA and no fluff.",
                  isUser: false,
                  assistantColor: Color(0xFFFFFFFF),
                ),
                _Bubble(
                  text: "Now make it punchier for mobile users.",
                  isUser: true,
                  userColor: Color(0xFF10A37F),
                ),
              ],
            ),
          ),
          const _InputBar(
            background: Color(0xFFFFFFFF),
            accent: Color(0xFF10A37F),
            placeholder: "Message ChatGPT",
          ),
        ],
      ),
    );
  }
}

class _ClaudePreview extends StatelessWidget {
  const _ClaudePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      backgroundColor: const Color(0xFFF7F1E8),
      child: Column(
        children: [
          const _StatusBarMock(textColor: Colors.black87),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                const Icon(CupertinoIcons.left_chevron, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Claude",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade900,
                  ),
                ),
                const Spacer(),
                Icon(CupertinoIcons.ellipsis_circle, color: Colors.brown.shade700),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: const [
                _Bubble(
                  text: "Summarize this feature in a warm, human tone.",
                  isUser: true,
                  userColor: Color(0xFFD97745),
                ),
                _Bubble(
                  text: "Absolutely. Here is a polished, natural sounding summary you can use.",
                  isUser: false,
                  assistantColor: Color(0xFFFFFBF5),
                  borderColor: Color(0xFFEADBC8),
                ),
                _Bubble(
                  text: "Great, now shorten to one sentence.",
                  isUser: true,
                  userColor: Color(0xFFD97745),
                ),
              ],
            ),
          ),
          const _InputBar(
            background: Color(0xFFFFFBF5),
            accent: Color(0xFFD97745),
            placeholder: "Talk to Claude",
          ),
        ],
      ),
    );
  }
}

class _StatusBarMock extends StatelessWidget {
  const _StatusBarMock({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Text(
            "9:41",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const Spacer(),
          Icon(CupertinoIcons.wifi, size: 13, color: textColor),
          const SizedBox(width: 6),
          Icon(CupertinoIcons.battery_100, size: 16, color: textColor),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    required this.userColor,
    this.assistantColor,
    this.borderColor,
  });

  final String text;
  final bool isUser;
  final Color userColor;
  final Color? assistantColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? userColor : (assistantColor ?? const Color(0xFFF1F1F1));
    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 12.5, height: 1.35)),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.background,
    required this.accent,
    required this.placeholder,
  });

  final Color background;
  final Color accent;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(CupertinoIcons.add_circled, color: accent, size: 20),
            ),
            Expanded(
              child: Text(
                placeholder,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 12.5),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(CupertinoIcons.mic_fill, color: accent, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
