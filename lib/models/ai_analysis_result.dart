/// Modèle de résultat d'analyse d'Intelligence Artificielle pour SignCi.
/// Contient les suggestions automatiques de catégorie, problème, mots-clés,
/// gravité, score de confiance, vérification de la qualité d'image,
/// vérification de cohérence image/catégorie et explication intelligible.
class AIAnalysisResult {
  final String suggestedType;
  final String suggestedCategory;
  final String suggestedProblem;
  final List<String> keywords;
  final String severity; // "Basse", "Moyenne", "Haute"
  final double confidenceScore; // Ex: 0.85 (85%)
  final String? detectedObjectFromImage;

  // --- Vérification de la qualité de l'image ---
  final String imageQualityLabel; // "Bonne", "Floue", "Trop sombre", ...
  final double imageQualityScore; // 0.0 -> 1.0
  final List<String> imageIssues;

  // --- Vérification de cohérence image/catégorie ---
  final String coherenceStatus; // "Cohérent", "Incohérent", "À vérifier", "Sans image"
  final String coherenceMessage;

  final String explanation;

  AIAnalysisResult({
    required this.suggestedType,
    required this.suggestedCategory,
    required this.suggestedProblem,
    required this.keywords,
    required this.severity,
    required this.confidenceScore,
    this.detectedObjectFromImage,
    this.imageQualityLabel = "Sans image",
    this.imageQualityScore = 0.5,
    this.imageIssues = const [],
    this.coherenceStatus = "Sans image",
    this.coherenceMessage = "Aucune image fournie pour la vérification.",
    required this.explanation,
  });

  /// Indique si la vérification IA bloque la soumission du signalement.
  bool get isBlocking =>
      coherenceStatus == "Incohérent" || imageQualityScore < 0.35;

  Map<String, dynamic> toMap() {
    return {
      'suggestedType': suggestedType,
      'suggestedCategory': suggestedCategory,
      'suggestedProblem': suggestedProblem,
      'keywords': keywords,
      'severity': severity,
      'confidenceScore': confidenceScore,
      'detectedObjectFromImage': detectedObjectFromImage,
      'imageQualityLabel': imageQualityLabel,
      'imageQualityScore': imageQualityScore,
      'imageIssues': imageIssues,
      'coherenceStatus': coherenceStatus,
      'coherenceMessage': coherenceMessage,
      'explanation': explanation,
    };
  }

  factory AIAnalysisResult.fromMap(Map<String, dynamic> map) {
    return AIAnalysisResult(
      suggestedType: map['suggestedType'] ?? 'Lieu public',
      suggestedCategory: map['suggestedCategory'] ?? 'Routes',
      suggestedProblem: map['suggestedProblem'] ?? 'Autre',
      keywords: List<String>.from(map['keywords'] ?? []),
      severity: map['severity'] ?? 'Moyenne',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.70,
      detectedObjectFromImage: map['detectedObjectFromImage'],
      imageQualityLabel: map['imageQualityLabel'] ?? 'Sans image',
      imageQualityScore: (map['imageQualityScore'] as num?)?.toDouble() ?? 0.5,
      imageIssues: List<String>.from(map['imageIssues'] ?? []),
      coherenceStatus: map['coherenceStatus'] ?? 'Sans image',
      coherenceMessage: map['coherenceMessage'] ?? '',
      explanation: map['explanation'] ?? '',
    );
  }
}
