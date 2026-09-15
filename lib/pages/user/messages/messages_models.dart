import 'package:flutter/material.dart';

/// Contact administratif/citoyen disponible dans la messagerie.
class ChatContact {
  final String id;
  final String name;
  final String role;
  final String phone;
  final Color color;
  final IconData icon;
  final List<String> autoReplies;

  const ChatContact({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.color,
    required this.icon,
    this.autoReplies = const [],
  });
}

/// Contacts officiels & services de la ville.
const List<ChatContact> kChatContacts = [
  ChatContact(
    id: 'maire',
    name: 'Maire de la ville',
    role: 'Cabinet du Maire',
    phone: '+261 34 12 34 567',
    color: Color(0xFF701460),
    icon: Icons.account_balance,
    autoReplies: [
      'Merci pour votre message. La mairie a bien pris note et le service compétent sera saisi. ✅',
      'Votre demande est en cours de traitement par le Cabinet du Maire. Nous revenons vers vous rapidement.',
    ],
  ),
  ChatContact(
    id: 'gendarmerie',
    name: 'Gendarmerie',
    role: 'Sécurité publique',
    phone: '19 (Urgence)',
    color: Color(0xFF154EA6),
    icon: Icons.local_police,
    autoReplies: [
      'Bien reçu. En cas de danger immédiat, appelez le 19. 🚨',
      'La brigade locale a été informée de votre alerte. Suivi en cours.',
    ],
  ),
  ChatContact(
    id: 'doctor',
    name: 'Centre de santé',
    role: 'Santé publique',
    phone: '+261 34 11 22 334',
    color: Color(0xFF0275D8),
    icon: Icons.local_hospital,
    autoReplies: [
      'Message reçu par le centre de santé. Nous vous recontactons au plus vite. 🏥',
      'Merci. Votre alerte sanitaire est transmise à l\'équipe médicale.',
    ],
  ),
  ChatContact(
    id: 'ecole',
    name: 'Direction de l\'École',
    role: 'Éducation',
    phone: '+261 34 55 66 778',
    color: Color(0xFF00A896),
    icon: Icons.school,
    autoReplies: [
      'Bien noté. La direction de l\'école prend les dispositions nécessaires. 🎒',
      'Merci de l\'information, nous allons vérifier avec le personnel concerné.',
    ],
  ),
  ChatContact(
    id: 'jirama',
    name: 'Service Eau (Jirama)',
    role: 'Eau & Électricité',
    phone: '+261 34 00 00 000',
    color: Color(0xFF00838F),
    icon: Icons.opacity,
    autoReplies: [
      'Fuite ou panne notée. Une équipe Jirama est dépêchée sur place. 💧',
      'Votre coupure d\'eau a été enregistrée. Intervention planifiée.',
    ],
  ),
  ChatContact(
    id: 'proprete',
    name: 'CUA – Propreté',
    role: 'Assainissement',
    phone: '+261 34 98 76 543',
    color: Color(0xFFF57C00),
    icon: Icons.cleaning_services,
    autoReplies: [
      'Dépôt d\'ordures signalé. La collecte est planifiée dans la zone. 🗑️',
      'Merci. Les agents de nettoyage interviennent sur le secteur concerné.',
    ],
  ),
];

/// Pièce jointe d'un message (photo, localisation ou alerte).
class ChatAttachment {
  final String type; // "image", "localisation", "alerte"
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final String label;

  const ChatAttachment({
    required this.type,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.label = '',
  });

  bool get isImage => type == "image";
  bool get isLocalisation => type == "localisation";
  bool get isAlerte => type == "alerte";
}

/// Un message individuel d'une conversation.
class ChatMessage {
  final String id;
  final bool fromMe;
  final String text;
  final DateTime time;
  final ChatAttachment? attachment;

  const ChatMessage({
    required this.id,
    required this.fromMe,
    required this.text,
    required this.time,
    this.attachment,
  });
}

/// Une conversation avec un contact.
class Conversation {
  final ChatContact contact;
  final List<ChatMessage> messages;
  int unreadCount;

  Conversation({
    required this.contact,
    List<ChatMessage>? messages,
    this.unreadCount = 0,
  }) : messages = messages ?? [];

  bool get isNew => messages.isEmpty;
}

/// Magasin de conversations partagé entre toutes les pages de messagerie.
/// Persiste pendant la session de l'application.
class ChatStore extends ChangeNotifier {
  ChatStore._();

  static final ChatStore instance = ChatStore._();

  final Map<String, Conversation> _conversations = {};
  int _nextId = 0;

  List<Conversation> get conversations {
    final list = _conversations.values.toList();
    list.sort((a, b) {
      if (a.messages.isEmpty) return 1;
      if (b.messages.isEmpty) return -1;
      return b.messages.last.time.compareTo(a.messages.last.time);
    });
    return list;
  }

  Conversation? conversationOf(String contactId) => _conversations[contactId];

  Conversation openConversation(ChatContact contact) {
    return _conversations.putIfAbsent(
      contact.id,
      () => Conversation(contact: contact, unreadCount: 0),
    );
  }

  /// Marque la conversation comme lue.
  void markAsRead(String contactId) {
    final conv = _conversations[contactId];
    if (conv != null && conv.unreadCount > 0) {
      conv.unreadCount = 0;
      notifyListeners();
    }
  }

  /// Envoie un message (texte + pièce jointe optionnelle) au contact.
  void sendMessage({
    required ChatContact contact,
    String text = '',
    ChatAttachment? attachment,
  }) {
    final conv = openConversation(contact);
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachment == null) return;

    conv.messages.add(ChatMessage(
      id: (_nextId++).toString(),
      fromMe: true,
      text: trimmed,
      time: DateTime.now(),
      attachment: attachment,
    ));
    notifyListeners();

    // Réponse automatique du contact pour simuler une vraie conversation.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!_conversations.containsKey(contact.id)) return;
      final convNow = _conversations[contact.id]!;
      final reply = contact.autoReplies.isEmpty
          ? 'Votre message a bien été reçu.'
          : contact.autoReplies[convNow.messages.length % contact.autoReplies.length];
      convNow.messages.add(ChatMessage(
id: (_nextId++).toString(),
        fromMe: false,
        text: reply,
        time: DateTime.now(),
      ));
      // Considéré comme lu si la conversation est déjà ouverte.
      notifyListeners();
    });
  }

  /// Partage un signalement existant sous forme d'alerte.
  void shareSignalement({
    required ChatContact contact,
    required String probleme,
    required String adresse,
  }) {
    sendMessage(
      contact: contact,
      text: '🔔 Alerte signalement : $probleme',
      attachment: ChatAttachment(
        type: 'alerte',
        label: '$probleme – $adresse',
      ),
    );
  }

  String formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}