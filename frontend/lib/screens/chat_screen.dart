import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/chat_context_provider.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _seedIntroMessage();
  }

  void _seedIntroMessage() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final session = context.read<SessionProvider>();
      final name =
          session.firebaseUser?.displayName?.split(' ').first ?? 'there';
      setState(() {
        _messages.add(
          ChatMessage(
            sender: Sender.ai,
            text:
                'Hi $name, I’m your CareVibe assistant. Ask me anything about your symptoms or wellness!',
          ),
        );
      });
    });
  }

  Future<void> _sendMessage() async {
    final session = context.read<SessionProvider>();
    final chatCtx = context.read<ChatContextProvider>();
    final jwt = session.jwt;
    if (!session.isAuthenticated || jwt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to continue chatting.'),
        ),
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    // Update inferred keywords and hospital preference from user input before sending
    chatCtx.updateFromText(text);

    setState(() {
      _messages.add(ChatMessage(sender: Sender.user, text: text));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$apiBase/ai/chat'),
        headers: authHeaders(jwt),
        body: jsonEncode({'message': text}),
      );
      if (response.statusCode != 200) {
        throw Exception('Chat service unavailable (${response.statusCode})');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final reply =
          json['reply']?.toString() ??
          'I am still thinking. Could you rephrase that?';
      final warning = json['warning']?.toString();
      setState(() {
        _messages.add(
          ChatMessage(sender: Sender.ai, text: reply, warning: warning),
        );
      });
      // Also let AI replies influence context if it suggests a specialty or urgency
      chatCtx.updateFromText(reply);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            sender: Sender.ai,
            text:
                'I ran into a connection issue. Please try again in a moment.',
          ),
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final statusColor = session.isAuthenticated
        ? Colors.greenAccent
        : Colors.redAccent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Health Assistant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 8),
                    const SizedBox(width: 6),
                    Text(
                      session.isAuthenticated ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('CareVibe assistant'),
                content: const Text(
                  'This chatbot provides general wellness guidance only. For urgent or personal medical advice, contact a licensed professional.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isSending) {
                  return const _TypingIndicator();
                }
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.25
                          : 0.08,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      cursorColor: AppColors.primary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText:
                            'Ask about symptoms, lifestyle or medication…',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.55),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSending
                            ? AppColors.secondary.withOpacity(0.5)
                            : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

enum Sender { user, ai }

class ChatMessage {
  ChatMessage({required this.sender, required this.text, this.warning});

  final Sender sender;
  final String text;
  final String? warning;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = isUser ? AppColors.primary : Colors.white;
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: alignment,
      child:
          Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isUser ? 22 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    if (message.warning != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          message.warning!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.danger.withOpacity(0.9),
                              ),
                        ),
                      ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideX(begin: isUser ? 0.2 : -0.2, curve: Curves.easeOut),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(delay: Duration(milliseconds: 0)),
            SizedBox(width: 6),
            _Dot(delay: Duration(milliseconds: 120)),
            SizedBox(width: 6),
            _Dot(delay: Duration(milliseconds: 240)),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.delay});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 600),
          delay: delay,
        );
  }
}
