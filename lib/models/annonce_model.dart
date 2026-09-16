/// Modèle d'une annonce publiée par l'administration SignCi.
/// Les citoyens la lisent dans le fil d'actualités (style Facebook).
class AnnonceModel {
  final int? id;
  final String titre;
  final String description;
  final String image;
  final String auteur;
  final String datePublication;
  final int likes;

  AnnonceModel({
    this.id,
    required this.titre,
    required this.description,
    this.image = '',
    this.auteur = 'Administration SignCi',
    String? datePublication,
    this.likes = 0,
  }) : datePublication =
            datePublication ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titre': titre,
      'description': description,
      'image': image,
      'auteur': auteur,
      'datePublication': datePublication,
      'likes': likes,
    };
  }

  factory AnnonceModel.fromMap(Map<String, dynamic> map) {
    return AnnonceModel(
      id: map['id'] is int ? map['id'] : null,
      titre: map['titre'] ?? map['title'] ?? 'Annonce',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      auteur: map['auteur'] ?? 'Administration SignCi',
      datePublication: _parseDate(map['datePublication'] ?? map['date_publication'] ?? map['created_at']),
      likes: (map['likes'] as num?)?.toInt() ?? 0,
    );
  }

  static String _parseDate(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
  }
}

/// Commentaire citoyen sur une annonce.
class AnnonceComment {
  final int? id;
  final int annonceId;
  final String pseudo;
  final String contenu;
  final String createdAt;

  AnnonceComment({
    this.id,
    required this.annonceId,
    required this.pseudo,
    required this.contenu,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'annonceId': annonceId,
      'pseudo': pseudo,
      'contenu': contenu,
      'created_at': createdAt,
    };
  }

  factory AnnonceComment.fromMap(Map<String, dynamic> map) {
    return AnnonceComment(
      id: map['id'] is int ? map['id'] : null,
      annonceId: (map['annonceId'] ?? map['annonce_id'] ?? 0) as int,
      pseudo: map['pseudo'] ?? 'Citoyen SignCi',
      contenu: map['contenu'] ?? '',
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  static String _parseDate(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
  }
}