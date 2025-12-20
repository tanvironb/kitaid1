import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

/// Simple chat message model
class ChatMessage {
  final String text;
  final bool isUser; // false = bot, true = user

  const ChatMessage({
    required this.text,
    required this.isUser,
  });
}

/// Simple rule model (pattern match -> answer)
class _BotRule {
  final List<RegExp> patterns;
  final String answer;

  const _BotRule({required this.patterns, required this.answer});

  bool matches(String text) => patterns.any((p) => p.hasMatch(text));
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  /// Initial bot message (like the prototype)
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text: 'Hi, How can i assist you?',
      isUser: false,
    ),
  ];

  /// --------------------------
  /// BOT KNOWLEDGE (FAQ + PRIVACY POLICY + CARDS + DOCS)
  /// Based on your provided FAQ page and Privacy Policy content.
  /// --------------------------
  late final List<_BotRule> _rules = [
    // ------------------ Greetings / Help ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bhi\b', caseSensitive: false),
        RegExp(r'\bhello\b', caseSensitive: false),
        RegExp(r'\bhey\b', caseSensitive: false),
        RegExp(r'\bassalam', caseSensitive: false),
      ],
      answer:
          'Hi 👋 You can ask me about KitaID FAQ, Privacy Policy, cards, documents, QR verification, login, biometrics, and troubleshooting.',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bhelp\b', caseSensitive: false),
        RegExp(r'\bwhat can you\b', caseSensitive: false),
        RegExp(r'\bcan you do\b', caseSensitive: false),
      ],
      answer:
          'I can help with:\n• FAQ (account, login, biometrics, QR)\n• Privacy Policy (data collected, sharing, deletion)\n• Cards (MyKad, passport, driving license)\n• Documents (upload, view, supported files)\n\nAsk your question 😊',
    ),

    // ------------------ FAQ: What is KitaID ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bwhat is kitaid\b', caseSensitive: false),
        RegExp(r'\bwhat is this app\b', caseSensitive: false),
        RegExp(r'\bkitaid meaning\b', caseSensitive: false),
      ],
      answer:
          'KitaID is a digital identity wallet designed for users in Malaysia. It helps you securely store and access important identity documents (MyKad, passport, driver’s license) in one place, with biometric login and QR-based verification.',
    ),

    // ------------------ FAQ: Create account ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bcreate an account\b', caseSensitive: false),
        RegExp(r'\bsign up\b', caseSensitive: false),
        RegExp(r'\bregister\b', caseSensitive: false),
        RegExp(r'\bhow do i create\b', caseSensitive: false),
      ],
      answer:
          'You can create an account in the app using your phone number and basic details. After signing up, you’ll verify your account using an OTP sent to your phone.',
    ),

    // ------------------ FAQ: Supported documents / cards ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bwhich documents\b', caseSensitive: false),
        RegExp(r'\bwhat documents\b', caseSensitive: false),
        RegExp(r'\bsupported\b', caseSensitive: false),
        RegExp(r'\bwhat cards\b', caseSensitive: false),
      ],
      answer:
          'KitaID currently supports:\n• MyKad / I-Kad information\n• Passport information\n• Driver’s license information\n• Other supporting identity-related documents (where supported)',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bmykad\b', caseSensitive: false),
        RegExp(r'\bi-kad\b', caseSensitive: false),
        RegExp(r'\bpassport\b', caseSensitive: false),
        RegExp(r'\bdriving\b', caseSensitive: false),
        RegExp(r'\blicen[cs]e\b', caseSensitive: false),
      ],
      answer:
          'KitaID supports storing identity documents like MyKad/I-Kad, Passport, and Driver’s License in one place (current supported types in the app).',
    ),

    // ------------------ FAQ: Login methods ------------------
    _BotRule(
      patterns: [
        RegExp(r'\blogin methods\b', caseSensitive: false),
        RegExp(r'\bhow to login\b', caseSensitive: false),
        RegExp(r'\blog in\b', caseSensitive: false),
        RegExp(r'\bsign in\b', caseSensitive: false),
      ],
      answer:
          'KitaID supports secure login using your registered phone number and password. If your device supports it, you can enable biometric login (fingerprint or Face ID) from the Settings page.',
    ),

    // ------------------ FAQ: Forgot password ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bforgot password\b', caseSensitive: false),
        RegExp(r'\breset password\b', caseSensitive: false),
        RegExp(r'\bchange password\b', caseSensitive: false),
      ],
      answer:
          'If you forgot your password: on the login screen, tap “Forgot Password” and follow the steps to verify your phone number and set a new password.',
    ),

    // ------------------ FAQ: Multiple devices ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bmultiple devices\b', caseSensitive: false),
        RegExp(r'\bother device\b', caseSensitive: false),
        RegExp(r'\bnew phone\b', caseSensitive: false),
        RegExp(r'\bcan i use\b.*\bdevice\b', caseSensitive: false),
      ],
      answer:
          'You can log in to KitaID on another device using your account. For security reasons, you may be asked to re-verify your identity (such as OTP or security checks) when using a new device.',
    ),

    // ------------------ FAQ: Security & privacy (FAQ) ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bis my data safe\b', caseSensitive: false),
        RegExp(r'\bdata safe\b', caseSensitive: false),
        RegExp(r'\bsecure\b', caseSensitive: false),
      ],
      answer:
          'KitaID takes security seriously and uses secure communication and storage practices to help protect your data. Biometric login, encrypted storage, and secure sessions reduce unauthorized access risk.',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bcan anyone else see\b', caseSensitive: false),
        RegExp(r'\bsee my documents\b', caseSensitive: false),
        RegExp(r'\bsee my cards\b', caseSensitive: false),
      ],
      answer:
          'Your documents are visible only after you unlock the app with password or biometrics. When you share/show a QR for verification, only the necessary information is shown.',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bshare\b.*\bthird\b', caseSensitive: false),
        RegExp(r'\bthird parties\b', caseSensitive: false),
        RegExp(r'\bsell\b.*\bdata\b', caseSensitive: false),
        RegExp(r'\bdoes kitaid share\b', caseSensitive: false),
      ],
      answer:
          'KitaID does not sell your personal data. Any sharing (with service providers or partners) is only to provide core features and follows privacy practices.',
    ),

    // ------------------ FAQ: QR verification ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bqr\b', caseSensitive: false),
        RegExp(r'\bverification\b', caseSensitive: false),
        RegExp(r'\bverify\b', caseSensitive: false),
        RegExp(r'\bscan\b', caseSensitive: false),
      ],
      answer:
          'QR verification lets certain services scan your KitaID QR code to confirm identity details. The QR contains a secure reference and only authorized verifiers can read the necessary information.',
    ),

    // ------------------ FAQ: Offline ------------------
    _BotRule(
      patterns: [
        RegExp(r'\boffline\b', caseSensitive: false),
        RegExp(r'\bno internet\b', caseSensitive: false),
      ],
      answer:
          'Some features (like viewing stored documents) may work offline. But real-time verification, syncing, OTP, and online checks require an internet connection.',
    ),

    // ------------------ FAQ: Not official government app ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bofficial\b', caseSensitive: false),
        RegExp(r'\bgovernment\b', caseSensitive: false),
        RegExp(r'\bis this government app\b', caseSensitive: false),
      ],
      answer:
          'KitaID is a student project / prototype to demonstrate a modern digital identity experience. It is not an official replacement for government-issued IDs.',
    ),

    // ------------------ Troubleshooting ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bcrash\b', caseSensitive: false),
        RegExp(r'\bnot loading\b', caseSensitive: false),
        RegExp(r'\bkeeps crashing\b', caseSensitive: false),
        RegExp(r'\bapp not working\b', caseSensitive: false),
      ],
      answer:
          'If the app is not loading or crashes:\n• Close & reopen the app\n• Check internet connection\n• Update app (if available)\n• Restart your device',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bnot updating\b', caseSensitive: false),
        RegExp(r'\binfo not updating\b', caseSensitive: false),
        RegExp(r'\brefresh\b', caseSensitive: false),
      ],
      answer:
          'If your information is not updating: check internet, then log out and log back in. If it continues, contact support with details/screenshots.',
    ),

    // ------------------ Contact ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bcontact\b', caseSensitive: false),
        RegExp(r'\bemail\b', caseSensitive: false),
        RegExp(r'\bsupport\b', caseSensitive: false),
      ],
      answer:
          'You can contact the KitaID team via email: monirsa2002@gmail.com',
    ),

    // ------------------ PRIVACY POLICY (More direct) ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bprivacy policy\b', caseSensitive: false),
        RegExp(r'\bprivacy\b', caseSensitive: false),
      ],
      answer:
          'Privacy Policy summary: KitaID collects and uses your information to provide and improve the service. It may collect personal data (name, email, phone) and usage data. You can request deletion of your data, and data may be shared with service providers only as needed.',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bwhat data\b.*\bcollect\b', caseSensitive: false),
        RegExp(r'\bdata collected\b', caseSensitive: false),
        RegExp(r'\bpersonal data\b', caseSensitive: false),
      ],
      answer:
          'KitaID may collect: Email address, first name & last name, phone number, and usage data. It may also collect location (with permission) and images from camera/photo library (with permission).',
    ),
    _BotRule(
      patterns: [
        RegExp(r'\bdelete\b.*\bdata\b', caseSensitive: false),
        RegExp(r'\bremove\b.*\bdata\b', caseSensitive: false),
        RegExp(r'\bdelete my account\b', caseSensitive: false),
      ],
      answer:
          'You can delete/request deletion of your personal data through the service (where available) or by contacting the team. Some information may be retained if there is a legal obligation or lawful basis.',
    ),

    // ------------------ Thanks ------------------
    _BotRule(
      patterns: [
        RegExp(r'\bthanks\b', caseSensitive: false),
        RegExp(r'\bthank you\b', caseSensitive: false),
        RegExp(r'\bty\b', caseSensitive: false),
      ],
      answer: 'You’re welcome 😊 Anything else you want to ask?',
    ),
  ];

  String _normalize(String input) {
    final s = input.toLowerCase().trim();
    return s.replaceAll(RegExp(r'[^\w\s]'), ' ');
  }

  String _getBotReply(String userText) {
    final norm = _normalize(userText);

    // Match best rule
    for (final r in _rules) {
      if (r.matches(norm)) return r.answer;
    }

    // Fallback (helpful)
    return 'I’m not sure about that yet.\n\nTry asking like:\n• "What is KitaID?"\n• "How to create an account?"\n• "I forgot my password"\n• "How does QR verification work?"\n• "What data does KitaID collect?"\n• "How can I delete my data?"';
  }

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // user message
      _messages.add(ChatMessage(text: text, isUser: true));

      // bot reply (smart)
      final reply = _getBotReply(text);
      _messages.add(ChatMessage(text: reply, isUser: false));
    });

    _textCtrl.clear();

    // Scroll to bottom smoothly after sending
    Future.microtask(() {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildBubble(ChatMessage msg) {
    final theme = Theme.of(context);
    final isUser = msg.isUser;

    // Colors fully from your theme
    final Color botBg = mycolors.Primary;
    final Color botText = theme.colorScheme.onPrimary;

    final Color userBg = theme.colorScheme.secondaryContainer;
    final Color userText = theme.colorScheme.onSecondaryContainer;

    final Alignment alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;

    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? userBg : botBg,
          borderRadius: radius,
        ),
        child: Text(
          msg.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? userText : botText,
            fontSize: mysizes.fontSm,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color chatBackground = theme.colorScheme.surfaceVariant;

    return Scaffold(
      backgroundColor: chatBackground,
      appBar: AppBar(
        backgroundColor: mycolors.Primary,
        centerTitle: true,
        title: Text(
          'Ask Bot',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// BODY
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: chatBackground,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildBubble(_messages[index]);
                },
              ),
            ),
          ),

          /// MESSAGE INPUT
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Container(
              color: theme.colorScheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mycolors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write your message here',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: _handleSend,
                    icon: Icon(
                      Icons.send,
                      color: mycolors.Primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ===== OFFICIAL KITAID NAVBAR =====
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 1, // Chatbot page index
        onTap: (index) {
          if (index == 1) return; // Already here

          switch (index) {
            case 0: // HOME
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              break;

            case 1: // CHATBOT
              Navigator.pushNamedAndRemoveUntil(context, '/chatbot', (_) => false);
              break;

            case 2: // SERVICES
              Navigator.pushNamedAndRemoveUntil(context, '/services', (_) => false);
              break;

            case 3: // NOTIFICATIONS
              Navigator.pushNamedAndRemoveUntil(context, '/notifications', (_) => false);
              break;

            case 4: // PROFILE
              Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
              break;
          }
        },
      ),
    );
  }
}
