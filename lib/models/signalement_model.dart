import 'dart:convert';

/// Modèle de données complet représentant un signalement citoyen dans SignCi.
/// Inclus la compatibilité SQLite, Firestore, les métadonnées IA et le système de vote.
class SignalementModel {
  final int? id;
  final String? firestoreId;
  final String type;
  final String categorie;
  final String probleme;
  final String description;
  final String adresse;
  final String image; // Chemins séparés par ';' ou URLs Firebase
  final String status; // "En attente", "En cours", "Résolu"
  final double? latitude;
  final double? longitude;
  final String priorite; // "Basse", "Moyenne", "Haute"
  final double confidenceScore;
  final List<String> keywords;
  final int upvotesCount;
  final bool isDuplicate;
  final String? duplicateOfId;
  final bool isCriticalZone;
  final String createdAt;
  final String? userId;
  final String? userPseudo;
  final bool isSynced;

  SignalementModel({
    this.id,
    this.firestoreId,
    required this.type,
    required this.categorie,
    required this.probleme,
    required this.description,
    required this.adresse,
    required this.image,
    this.status = "En attente",
    this.latitude,
    this.longitude,
    this.priorite = "Moyenne",
    this.confidenceScore = 0.80,
    this.keywords = const [],
    this.upvotesCount = 1,
    this.isDuplicate = false,
    this.duplicateOfId,
    this.isCriticalZone = false,
    String? createdAt,
    this.userId,
    this.userPseudo,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  /// Convertit le modèle en Map compatible avec SQLite et Firestore
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firestoreId': firestoreId,
      'type': type,
      'categorie': categorie,
      'probleme': probleme,
      'description': description,
      'adresse': adresse,
      'image': image,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'priorite': priorite,
      'confidenceScore': confidenceScore,
      'keywords': jsonEncode(keywords),
      'upvotesCount': upvotesCount,
      'isDuplicate': isDuplicate ? 1 : 0,
      'duplicateOfId': duplicateOfId,
      'isCriticalZone': isCriticalZone ? 1 : 0,
      'createdAt': createdAt,
      'userId': userId,
      'userPseudo': userPseudo,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Instancie le modèle depuis une Map (SQLite ou Firestore)
  factory SignalementModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedKeywords = [];
    if (map['keywords'] != null) {
      if (map['keywords'] is String) {
        try {
          parsedKeywords = List<String>.from(jsonDecode(map['keywords']));
        } catch (_) {
          parsedKeywords = map['keywords'].toString().split(',');
        }
      } else if (map['keywords'] is List) {
        parsedKeywords = List<String>.from(map['keywords']);
      }
    }

    return SignalementModel(
      id: map['id'] is int ? map['id'] : null,
      firestoreId: map['firestoreId'] as String?,
      type: map['type'] ?? 'Lieu public',
      categorie: map['categorie'] ?? 'General',
      probleme: map['probleme'] ?? 'Non spécifié',
      description: map['description'] ?? '',
      adresse: map['adresse'] ?? '',
      image: map['image'] ?? '',
      status: map['status'] ?? 'En attente',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      priorite: map['priorite'] ?? 'Moyenne',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.80,
      keywords: parsedKeywords,
      upvotesCount: (map['upvotesCount'] as num?)?.toInt() ?? 1,
      isDuplicate: map['isDuplicate'] == 1 || map['isDuplicate'] == true,
      duplicateOfId: map['duplicateOfId']?.toString(),
      isCriticalZone: map['isCriticalZone'] == 1 || map['isCriticalZone'] == true,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      userId: map['userId'] as String?,
      userPseudo: map['userPseudo'] as String?,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  /// Duplique le modèle avec modifications sélectives (immutabilité)
  SignalementModel copyWith({
    int? id,
    String? firestoreId,
    String? type,
    String? categorie,
    String? probleme,
    String? description,
    String? adresse,
    String? image,
    String? status,
    double? latitude,
    double? longitude,
    String? priorite,
    double? confidenceScore,
    List<String>? keywords,
    int? upvotesCount,
    bool? isDuplicate,
    String? duplicateOfId,
    bool? isCriticalZone,
    String? createdAt,
    String? userId,
    String? userPseudo,
    bool? isSynced,
  }) {
    return SignalementModel(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      type: type ?? this.type,
      categorie: categorie ?? this.categorie,
      probleme: probleme ?? this.probleme,
      description: description ?? this.description,
      adresse: adresse ?? this.adresse,
      image: image ?? this.image,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priorite: priorite ?? this.priorite,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      keywords: keywords ?? this.keywords,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateOfId: duplicateOfId ?? this.duplicateOfId,
      isCriticalZone: isCriticalZone ?? this.isCriticalZone,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      userPseudo: userPseudo ?? this.userPseudo,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
