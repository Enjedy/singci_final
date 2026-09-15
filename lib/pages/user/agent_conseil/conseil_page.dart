import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/ai_service.dart';

/// Message affiché dans la conversation avec l'agent.
class _Message {
  final bool fromUser;
  final String text;

  const _Message({required this.fromUser, required this.text});
}

/// 🤖 Agent de conseil : donne des conseils concrets selon le problème
/// décrit par l'utilisateur (ex. : poteau Jirama tombé, coupure d'eau...).
class ConseilPage extends StatefulWidget {
  const ConseilPage({super.key});

  @override
  State<ConseilPage> createState() => _ConseilPageState();
}

class _ConseilPageState extends State<ConseilPage> {
  final List<_Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;

  static const List<String> _quick = [
    'Poteau Jirama tombé dans ma rue',
    'Coupure d\'eau depuis 2 jours',
    'Dépôt d\'ordures devant le marché',
    'Nid-de-poule dangereux sur la route',
    'Réverbère en panne près de l\'école',
    'Arbre penché juste à côté de ma maison',
  ];

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String input) {
    final text = input.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(fromUser: true, text: text));
    });
    _controller.clear();
    _scrollToBottom();

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Petite latence pour simuler la réflexion de l'agent.
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final conseil = AIService.getConseil(text);
      setState(() {
        _messages.add(_Message(fromUser: false, text: conseil.toText()));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF154EA6),
              child: Icon(Icons.smart_toy, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Agent de conseil",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Assistant intelligent SignCi",
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.lightGreenAccent),
                  SizedBox(width: 5),
                  Text('En ligne',
                      style: TextStyle(fontSize: 11, color: Colors.lightGreenAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFF154EA6).withValues(alpha: 0.06),
            child: Text(
              "Décrivez le problème que vous avez signalé ou souhaitez signaler : "
              "je vous donne des conseils pratiques et prioritaires.",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(isDark)
                : ListView(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      if (_isTyping) _buildTypingBubble(isDark),
                      for (final msg in _messages.reversed) _buildMessage(msg, isDark),
                    ],
                  ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFF154EA6).withValues(alpha: 0.12),
            child: const Icon(Icons.smart_toy, size: 48, color: Color(0xFF154EA6)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Bonjour 👋, je suis votre agent de conseil !",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Décrivez un problème (ex. : « un poteau Jirama est coupé ») "
            "ou choisissez un exemple pour obtenir des conseils adaptés.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Suggestions",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quick.map((q) {
              return ActionChip(
                avatar: const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFF57C00)),
                label: Text(q, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFF57C00).withValues(alpha: 0.08),
                side: BorderSide(color: const Color(0xFFF57C00).withValues(alpha: 0.3)),
                onPressed: () => _send(q),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_Message msg, bool isDark) {
    final isMe = msg.fromUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF0275D8), Color(0xFF154EA6)])
              : null,
          color: isMe ? null : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
          ],
        ),
        child: isMe
            ? Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
              )
            : _buildConseilText(msg.text, isDark),
      ),
    );
  }

  Widget _buildConseilText(String text, bool isDark) {
    final lines = text.split('\n');
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;

    final children = <Widget>[
      Text(
        lines.first,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: titleColor),
      ),
      const SizedBox(height: 6),
    ];

    for (var i = 1; i < lines.length; i++) {
      final l = lines[i];
      if (l.trim().isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          l.trim(),
          style: TextStyle(fontSize: 13.5, height: 1.4, color: bodyColor),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildTypingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _TypingDot(delay: Duration(milliseconds: i * 200)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(_controller.text),
              decoration: InputDecoration(
                hintText: "Décrivez votre problème...",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_controller.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0275D8), Color(0xFF154EA6)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// Point d'animation pour l'indicateur « l'agent écrit... ».
class _TypingDot extends StatefulWidget {
  final Duration delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = (_controller.value - widget.delay.inMilliseconds / 900) % 1.0;
        final scale = 0.5 + 0.5 * (1 - (phase * 2 - 1).abs());
        return Transform.scale(
          scale: scale.clamp(0.4, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}