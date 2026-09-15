import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'messages_models.dart';

/// Liste des conversations de la messagerie (style application téléphone).
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String _query = '';

  List<Conversation> get _filtered {
    final all = ChatStore.instance.conversations;
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((c) => c.contact.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _pickContact() async {
    final contact = await showModalBottomSheet<ChatContact>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Choisir un contact",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: kChatContacts.map((contact) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact.color.withValues(alpha: 0.15),
                      child: Icon(contact.icon, color: contact.color, size: 22),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(contact.role),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.pop(ctx, contact),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (contact == null || !mounted) return;
    _openChat(contact);
  }

  void _openChat(ChatContact contact) {
    ChatStore.instance.markAsRead(contact.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(contact: contact)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages & Alertes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: "Nouveau message",
            onPressed: _pickContact,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0275D8),
        onPressed: _pickContact,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Rechercher une conversation...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Liste des conversations
          Expanded(
            child: ListenableBuilder(
              listenable: ChatStore.instance,
              builder: (context, _) {
                final conversations = _filtered;

                if (conversations.isEmpty) {
                  return _EmptyState(onNewChat: _pickContact, isDark: isDark);
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 78),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _ConversationTile(conv: conv, onTap: () => _openChat(conv.contact));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final VoidCallback onTap;

  const _ConversationTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final last = conv.messages.isEmpty ? null : conv.messages.last;
    final preview = last == null
        ? "Démarrer une conversation"
        : '${last.fromMe ? "Vous : " : ""}'
            '${last.text.isEmpty && last.attachment != null ? _attachmentLabel(last.attachment!.type) : last.text}';
    final time = last == null ? '' : ChatStore.instance.formatTime(last.time);
    final hasUnread = conv.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar contact
            Stack(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: conv.contact.color.withValues(alpha: 0.15),
                  child: Icon(conv.contact.icon, color: conv.contact.color, size: 26),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFED1C24),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${conv.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread ? Theme.of(context).colorScheme.secondary : Colors.grey,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread ? const Color(0xFF0275D8) : Colors.grey,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _attachmentLabel(String type) {
    switch (type) {
      case 'image':
        return '📷 Photo partagée';
      case 'localisation':
        return '📍 Position partagée';
      case 'alerte':
        return '🔔 Alerte signalement';
      default:
        return 'Pièce jointe';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  final bool isDark;

  const _EmptyState({required this.onNewChat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF0275D8).withValues(alpha: 0.1),
            child: const Icon(Icons.chat_bubble_outline, size: 46, color: Color(0xFF0275D8)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Aucune conversation",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Contactez la mairie, la gendarmerie, un centre de santé ou les services de la ville.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0275D8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onNewChat,
            icon: const Icon(Icons.add),
            label: const Text("Nouveau message", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}