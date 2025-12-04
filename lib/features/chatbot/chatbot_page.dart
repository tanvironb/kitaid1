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

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  /// Initial bot message (like the prototype)
  final List<ChatMessage> _messages = const [
    ChatMessage(
      text: 'Hi, How can i assist you?',
      isUser: false,
    ),
  ];

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
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

            case 4: // PROFILE / SETTINGS
              Navigator.pushNamedAndRemoveUntil(context, '/settings', (_) => false);
              break;
          }
        },
      ),
    );
  }
}
