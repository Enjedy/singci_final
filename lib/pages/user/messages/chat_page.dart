import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/signalement_model.dart';
import '../../../services/location_service.dart';
import '../../../services/supabase_service.dart';
import '../carte.dart';
import 'messages_models.dart';

/// Écran de conversation type messagerie téléphone.
class ChatPage extends StatefulWidget {
  final ChatContact contact;

  const ChatPage({super.key, required this.contact});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _typingTimer;
  bool _isSending = false;

  ChatContact get contact => widget.contact;

  @override
  void initState() {
    super.initState();
    ChatStore.instance.openConversation(contact);
    ChatStore.instance.markAsRead(contact.id);
  }

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

  void _send() {
    if (_isSending) return;
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    setState(() => _isSending = true);
    ChatStore.instance.sendMessage(contact: contact, text: text);
    _controller.clear();
    _scrollToBottom();
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isSending = false);
    });
    _scrollToBottom();
  }

  // ------------------- PIÈCES JOINTES -------------------

  Future<void> _showAttachmentSheet() async {
    final choice = await showModalBottomSheet<String>(
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
              child: Text("Partager quelque chose",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0275D8)),
              title: const Text("Photo ou image"),
              subtitle: const Text("Joindre une photo depuis la galerie"),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF701460)),
              title: const Text("Prendre une photo"),
              subtitle: const Text("Utiliser la caméra"),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.green),
              title: const Text("Ma position"),
              subtitle: const Text("Partager vos coordonnées GPS actuelles"),
              onTap: () => Navigator.pop(ctx, 'location'),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: const Text("Un signalement"),
              subtitle: const Text("Transmettre un problème déjà signalé"),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    switch (choice) {
      case 'image':
        await _attachImage(ImageSource.gallery);
      case 'camera':
        await _attachImage(ImageSource.camera);
      case 'location':
        await _attachLocation();
      case 'report':
        await _attachReport();
    }
  }

  Future<void> _attachImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    ChatStore.instance.sendMessage(
      contact: contact,
      text: source == ImageSource.camera ? "📷 Photo partagée" : "🖼️ Image partagée",
      attachment: ChatAttachment(
        type: 'image',
        imagePath: picked.path,
        label: "Pièce jointe",
      ),
    );
    _scrollToBottom();
  }

  Future<void> _attachLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    ChatStore.instance.sendMessage(
      contact: contact,
      text: "📍 Ma position actuelle : ${loc.address}",
      attachment: ChatAttachment(
        type: 'localisation',
        latitude: loc.latitude,
        longitude: loc.longitude,
        label: loc.address,
      ),
    );
    _scrollToBottom();
  }

  Future<void> _attachReport() async {
    List<SignalementModel> reports;
    try {
      reports = await SupabaseService.getAllSignalements();
    } catch (_) {
      reports = [];
    }
    if (!mounted) return;

    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun signalement disponible à partager.")),
      );
      return;
    }

    final reportsToShow = reports.take(5).toList();
    final selected = await showModalBottomSheet<SignalementModel>(
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
              child: Text("Choisir un signalement à partager",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: reportsToShow.map((r) {
                  return ListTile(
                    leading: const Icon(Icons.warning_amber, color: Color(0xFF0275D8)),
                    title: Text(r.probleme, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(r.adresse, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(ctx, r),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      ChatStore.instance.shareSignalement(
        contact: contact,
        probleme: selected.probleme,
        adresse: selected.adresse,
      );
      _scrollToBottom();
    }
  }

  // ------------------- UI -------------------

  List<Widget> _buildMessages(Conversation conv) {
    if (conv.messages.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "Démarrez la conversation avec ${contact.name}. "
              "Tapez un message ou partagez une photo, votre position ou un signalement.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      ];
    }

    return conv.messages.map((msg) {
      final isMe = msg.fromMe;
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(colors: [Color(0xFF0275D8), Color(0xFF154EA6)])
                : null,
            color: isMe ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.attachment != null) _buildAttachment(msg),
              if (msg.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: msg.attachment != null ? 8 : 0),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  ChatStore.instance.formatTime(msg.time),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAttachment(ChatMessage msg) {
    final a = msg.attachment!;
    final isMe = msg.fromMe;
    final textColor = isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;

    if (a.isImage && a.imagePath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(a.imagePath!),
              width: 200,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 200,
                height: 140,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          if (a.label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(a.label, style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ],
      );
    }

    if (a.isLocalisation && a.latitude != null && a.longitude != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, size: 30, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Position partagée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    const SizedBox(height: 2),
                    Text(
                      '${a.latitude!.toStringAsFixed(5)}, ${a.longitude!.toStringAsFixed(5)}',
                      style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map, size: 14, color: isMe ? Colors.white : const Color(0xFF0275D8)),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CarteSignalementPage()),
                    );
                  },
                  child: Text(
                    "Ouvrir la carte",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white : const Color(0xFF0275D8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (a.isAlerte) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notification_important, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                a.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: contact.color,
              child: Icon(contact.icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    contact.role,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (contact.phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call),
              tooltip: 'Appeler ${contact.phone}',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Appel vers ${contact.name} (${contact.phone})")),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Message d'accroche du contact
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.blue.withValues(alpha: 0.06),
            child: Text(
              "Vous discutez avec ${contact.name} – ${contact.role}. "
              "Toutes les conversations sont utilisées pour améliorer la ville.",
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListenableBuilder(
              listenable: ChatStore.instance,
              builder: (context, _) {
                final conv = ChatStore.instance.conversationOf(contact.id) ??
                    Conversation(contact: contact);
                return ListView(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: _buildMessages(conv).reversed.toList(),
                );
              },
            ),
          ),

          // Barre de saisie
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton pièce jointe
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF0275D8), size: 28),
            tooltip: "Ajouter / Partager",
            onPressed: _showAttachmentSheet,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: "Écrire un message...",
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
          // Bouton envoyer (microphone ou send)
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0275D8), Color(0xFF154EA6)],
                ),
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