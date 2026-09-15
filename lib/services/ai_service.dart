import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/ai_analysis_result.dart';
import '../models/signalement_model.dart';

/// Classe représentant le résultat de la détection de doublons.
class DuplicateMatch {
  final SignalementModel existingReport;
  final double distanceMeters;
  final double similarityScore; // 0.0 -> 1.0
  final bool isHighProbability;

  DuplicateMatch({
    required this.existingReport,
    required this.distanceMeters,
    required this.similarityScore,
    required this.isHighProbability,
  });
}

/// Résultat de l'analyse de la qualité d'une image (IA Vision offline).
class ImageQualityAnalysis {
  final bool hasImage;
  final int width;
  final int height;
  final String label; // "Bonne", "Floue", "Trop sombre", ...
  final double score; // 0.0 -> 1.0
  final List<String> issues;
  final String? visualHint;

  const ImageQualityAnalysis({
    required this.hasImage,
    required this.width,
    required this.height,
    required this.label,
    required this.score,
    required this.issues,
    this.visualHint,
  });

  /// Image illisible / fichier corrompu.
  factory ImageQualityAnalysis.unreadable(String reason) {
    return ImageQualityAnalysis(
      hasImage: true,
      width: 0,
      height: 0,
      label: "Image inexploitable",
      score: 0.0,
      issues: [reason],
      visualHint: "Impossible d'extraire le contenu visuel.",
    );
  }

  factory ImageQualityAnalysis.noImage() {
    return const ImageQualityAnalysis(
      hasImage: false,
      width: 0,
      height: 0,
      label: "Sans image",
      score: 0.4,
      issues: ['Aucune image fournie.'],
      visualHint: null,
    );
  }
}

/// Service centralisé d'Intelligence Artificielle pour SignCi.
/// Propose l'analyse NLP textuelle, la vérification de la qualité d'image
/// (floue, sombre, surexposée, inexploitable), la vérification de cohérence
/// image/catégorie, la détection de doublons GPS/Texte et la classification
/// de zones critiques.
class AIService {
  // Mots vides (stop-words) en français et malagasy pour l'extraction de mots-clés
  static const Set<String> _stopWords = {
    'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'dans', 'en', 'sur', 'sous',
    'est', 'sont', 'a', 'ont', 'avec', 'par', 'pour', 'qui', 'que', 'quoi', 'ce',
    'cette', 'ces', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'pas', 'plus',
    'très', 'grand', 'petit', 'ny', 'sy', 'amin', 'amin\'ny', 'dia', 'koa', 'misy',
    'noho', 'reo', 'ito', 'ity', 'izay', 've', 'aza', 'mianatra', 'efa',
    'votre', 'vos', 'notre', 'nos', 'au', 'aux', 'me', 'te', 'se', 'ma', 'ta', 'sa',
    'mon', 'ton', 'son', 'mes', 'tes', 'ses', 'et', 'ou', 'if', 'then'
  };

  /// Dictionnaire sémantique pour la classification intelligente des problèmes
  static final Map<String, Map<String, List<String>>> _categoryTaxonomy = {
    'Lieu public': {
      'Routes': [
        'trou', 'nid-de-poule', 'crevasse', 'inondation', 'goudron', 'bitume',
        'chaussée', 'obstacle', 'accident', 'affaissement', 'route', 'piste',
        'nid', 'rue', 'asphalte', 'trottoir', 'bordure', 'traverser'
      ],
      'Éclairage': [
        'lampadaire', 'nuit', 'obscurité', 'pôle', 'lumière', 'sombre',
        'électricité', 'câble', 'transformateur', 'ampoule', 'obscur',
        'eclairage', 'réverbère', 'éteint', 'fonctionne pas', 'panne'
      ],
      'Assainissement': [
        'ordure', 'déchet', 'poubelle', 'canal', 'égout', 'odeur', 'insalubrité',
        'accumulation', 'tuyau', 'canalisation', 'eau usée', 'dépôt', 'saleté',
        'détritus', 'ordures', 'propreté', 'boue'
      ],
      'Eau & Fuites': [
        'fuite', 'tuyau', 'eau', 'coupure', 'vanne', 'inondation', 'pression',
        'robine', 'jirama', 'compteur', 'égouttement', 'jaillir', 'souille'
      ],
      'Sécurité & Danger': [
        'arbre', 'branche', 'danger', 'câble suspendu', 'pylône', 'risque',
        'effondrement', 'glissement', 'panneau', 'chute', 'bloqué', 'danger'
      ]
    },
    'Bâtiment': {
      'École': [
        'table', 'banc', 'classe', 'porte', 'fenêtre', 'toit', 'fissure',
        'mur', 'tableau', 'école', 'lycée', 'salle', 'salle de classe', 'cour'
      ],
      'Infrastructure': [
        'pont', 'dalle', 'bâtiment', 'mur fissuré', 'effondrement', 'poutre',
        'escalier', 'fissure', 'plafond', 'toiture', 'construction'
      ]
    }
  };

  /// Catégories réellement proposables dans l'application (clé normalisée,
  /// libellé d'affichage) avec leurs mots-clés attendus.
  static const Map<String, String> _selectableCategoryLabels = {
    'routes': 'Routes',
    'éclairage': 'Éclairage',
    'assainissement': 'Assainissement',
    'eau & fuites': 'Eau & Fuites',
    'école': 'École',
    'infrastructure': 'Infrastructure',
  };

  static const Map<String, List<String>> _selectableCategoryKeywords = {
    'routes': [
      'trou', 'nid-de-poule', 'nid', 'crevasse', 'route', 'rue', 'asphalte',
      'bitume', 'goudron', 'chaussée', 'trottoir', 'inondé', 'inondation',
      'affaissement', 'obstacle', 'accident', 'piste', 'bordure'
    ],
    'éclairage': [
      'lampadaire', 'réverbère', 'lumière', 'éclairage', 'eclairage', 'ampoule',
      'éteint', 'panne', 'obscur', 'sombre', 'nuit', 'pôle', 'câble', 'électricité'
    ],
    'assainissement': [
      'ordure', 'déchet', 'ordures', 'déchets', 'poubelle', 'égout', 'canal',
      'canalisation', 'tuyau', 'dépôt', 'saleté', 'détritus', 'insalubre',
      'odeur', 'boue'
    ],
    'eau & fuites': [
      'fuite', 'eau', 'tuyau', 'coupure', 'vanne', 'pression', 'robine',
      'compteur', 'jirama', 'égouttement', 'jaillit', 'ruisselle'
    ],
    'école': [
      'école', 'lycée', 'classe', 'table', 'banc', 'tableau', 'porte',
      'fenêtre', 'toit', 'mur', 'salle', 'cour de récréation'
    ],
    'infrastructure': [
      'pont', 'dalle', 'bâtiment', 'immeuble', 'mur', 'poutre', 'escalier',
      'fissure', 'plafond', 'toiture', 'effondrement', 'construction'
    ],
  };

  /// Mots-clés indiquant une urgence élevée (Haute gravité)
  static const List<String> _highSeverityKeywords = [
    'danger', 'urgente', 'urgent', 'blessé', 'bloqué', 'effondrement',
    'électrocution', 'mortel', 'grave', 'inondé', 'fissure grave', 'risque majeur',
    'zaza', 'loza', 'atrisk'
  ];

  /// 🧠 Analyse principale d'un signalement par l'IA
  static Future<AIAnalysisResult> analyzeReport({
    required String description,
    String? imagePath,
    String? currentType,
    String? currentCategory,
  }) async {
    // Simulation d'un traitement IA réactif (sans latence perçue par l'utilisateur)
    await Future.delayed(const Duration(milliseconds: 120));

    final cleanText = description.toLowerCase();
    final tokens = _tokenize(cleanText);
    final keywords = _extractKeywords(tokens);

    // 1. Déduction intelligente du Type et de la Catégorie
    String suggestedType = currentType ?? "Lieu public";
    String suggestedCategory = currentCategory ?? "Routes";
    String suggestedProblem = "Problème à vérifier";
    double highestMatchScore = 0;

    _categoryTaxonomy.forEach((typeKey, categories) {
      categories.forEach((catKey, words) {
        int matchCount = 0;
        for (var word in words) {
          if (cleanText.contains(word)) {
            matchCount++;
          }
        }

        double score = matchCount / (words.length * 0.3);
        if (score > highestMatchScore) {
          highestMatchScore = score;
          suggestedType = typeKey;
          suggestedCategory = catKey;

          // Assigner le problème le plus précis selon les mots-clés
          if (catKey == 'Routes') {
            suggestedProblem = cleanText.contains('trou') || cleanText.contains('nid')
                ? 'Route endommagée / Nid-de-poule'
                : 'Route inondée / dégradée';
          } else if (catKey == 'Éclairage') {
            suggestedProblem = 'Lampadaire en panne / Zone sombre';
          } else if (catKey == 'Assainissement') {
            suggestedProblem = 'Accumulation de déchets / Égout bouché';
          } else if (catKey == 'Eau & Fuites') {
            suggestedProblem = 'Fuite d\'eau courante';
          } else if (catKey == 'École') {
            suggestedProblem = 'Mobilier cassé ou Mur fissuré';
          } else {
            suggestedProblem = 'Infrastructure endommagée';
          }
        }
      });
    });

    // 2. Vérification de l'Image (Pipeline Vision IA) : qualité + indices visuels
    ImageQualityAnalysis? quality;
    if (imagePath != null && imagePath.isNotEmpty) {
      quality = await analyzeImageQuality(imagePath);
    }

    // 3. Vérification de cohérence image/catégorie/textes
    final String selectedCategory = suggestedCategory;
    final CoherenceResult coherence = checkCoherence(
      selectedCategory: selectedCategory,
      description: cleanText,
      quality: quality ?? ImageQualityAnalysis.noImage(),
    );

    // 4. Évaluation de la Gravité (Basse, Moyenne, Haute)
    String severity = "Moyenne";
    bool containsDanger = _highSeverityKeywords.any((k) => cleanText.contains(k));
    if (containsDanger) {
      severity = "Haute";
    } else if (cleanText.length < 25 && highestMatchScore < 0.2) {
      severity = "Basse";
    } else if (cleanText.contains('grave') || cleanText.contains('bloque')) {
      severity = "Haute";
    }

    // 5. Calcul du Score de Confiance (Ex: 0.85 = 85%)
    double confidence = 0.55;
    if (tokens.length >= 5) confidence += 0.10;
    if (highestMatchScore > 0.3) confidence += 0.12;
    if (quality != null && quality.hasImage) confidence += 0.10;
    if (coherence.status == "Cohérent") confidence += 0.08;
    confidence = min(0.98, max(0.40, confidence));

    // 6. Génération de l'explication intelligible
    String explanation = "Analyse terminée avec un score de confiance de ${(confidence * 100).toInt()}%. ";
    if (quality != null && quality.hasImage) {
      explanation += "Qualité d'image : ${quality.label}. ";
    }
    explanation += "Catégorie vérifiée : '$selectedCategory' → ${coherence.status}. ";
    explanation += "Priorité suggérée : $severity.";

    final detectedObject = quality?.visualHint;

    return AIAnalysisResult(
      suggestedType: suggestedType,
      suggestedCategory: suggestedCategory,
      suggestedProblem: suggestedProblem,
      keywords: keywords,
      severity: severity,
      confidenceScore: confidence,
      detectedObjectFromImage: detectedObject,
      imageQualityLabel: quality?.label ?? "Sans image",
      imageQualityScore: quality?.score ?? 0.4,
      imageIssues: quality?.issues ?? const [],
      coherenceStatus: coherence.status,
      coherenceMessage: coherence.message,
      explanation: explanation,
    );
  }

  /// 🔍 Analyse de la qualité d'une image (floue, sombre, surexposée,
  /// inexploitable, basse résolution...) effectuée hors du thread UI.
  static Future<ImageQualityAnalysis> analyzeImageQuality(String path) async {
    try {
      final result = await Isolate.run(() => _analyzeImageSync(path));
      return result;
    } catch (_) {
      return ImageQualityAnalysis.unreadable(
          "Fichier inaccessible ou illisible par le moteur IA.");
    }
  }

  static ImageQualityAnalysis _analyzeImageSync(String path) {
    final Uint8List bytes;
    try {
      bytes = File(path).readAsBytesSync();
    } catch (_) {
      return ImageQualityAnalysis.unreadable("Fichier inaccessible.");
    }

    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return ImageQualityAnalysis.unreadable(
          "Format d'image non reconnu ou fichier corrompu.");
    }

    final int originalW = decoded.width;
    final int originalH = decoded.height;

    // Résolution trop faible => inexploitable
    if (originalW < 80 || originalH < 80) {
      return ImageQualityAnalysis(
        hasImage: true,
        width: originalW,
        height: originalH,
        label: "Image de qualité insuffisante (résolution trop faible)",
        score: 0.25,
        issues: [
          "Image trop petite (${originalW}x${originalH}px).",
          "Prenez une photo nette de plus grande résolution."
        ],
        visualHint: null,
      );
    }

    // Réduction du coût de calcul
    img.Image working = decoded;
    if (originalW > 300 || originalH > 300) {
      working = img.copyResize(decoded,
          width: 300, interpolation: img.Interpolation.average);
    }
    final img.Image gray = img.grayscale(working);

    final int w = gray.width;
    final int h = gray.height;

    double sum = 0;
    double sumSq = 0;
    int n = 0;
    final List<double> lap = <double>[];
    int darkCount = 0;
    int brightCount = 0;

    for (int y = 1; y < h - 1; y += 2) {
      for (int x = 1; x < w - 1; x += 2) {
        final int lum = gray.getPixel(x, y).r.toInt();
        final int up = gray.getPixel(x, y - 1).r.toInt();
        final int down = gray.getPixel(x, y + 1).r.toInt();
        final int left = gray.getPixel(x - 1, y).r.toInt();
        final int right = gray.getPixel(x + 1, y).r.toInt();

        final double laplacian = (4 * lum - up - down - left - right).toDouble();
        lap.add(laplacian);

        sum += lum;
        sumSq += lum * lum;
        n++;

        if (lum < 45) darkCount++;
        if (lum > 215) brightCount++;
      }
    }

    if (n == 0) {
      return ImageQualityAnalysis.unreadable("Image vide.");
    }

    final double mean = sum / n;
    final double variance = max(0.0, (sumSq / n) - (mean * mean));
    final double contrast = sqrt(variance);

    double lapMeanAbs = 0;
    for (final v in lap) {
      lapMeanAbs += v.abs();
    }
    lapMeanAbs /= lap.length;

    final double darkRatio = darkCount / n;
    final double brightRatio = brightCount / n;

    // Netteté normalisée (0 = très flou, 1 = net)
    final double sharpness =
        (((lapMeanAbs - 2.0) / 10.0)).clamp(0.0, 1.0);

    // Diversité tonale : nombre de "paliers" de luminosité distincts (0..8)
    final Set<int> buckets = <int>{};
    for (int y = 0; y < h; y += 2) {
      for (int x = 0; x < w; x += 2) {
        buckets.add(gray.getPixel(x, y).r.toInt() >> 5);
      }
    }
    final int uniqueBuckets = buckets.length;

    // Indice visuel (couleurs dominantes) pour aider la cohérence
    final String? visualHint = _describeVisualScene(
        working, mean, darkRatio, brightRatio);

    final List<String> issues = <String>[];

    if (uniqueBuckets <= 2) {
      issues.add("L'image est presque uniforme (contenu inexploitable).");
      return ImageQualityAnalysis(
        hasImage: true,
        width: originalW,
        height: originalH,
        label: "Image inexploitable (contenu uniforme)",
        score: 0.15,
        issues: issues,
        visualHint: "Image quasi uniforme, aucun détail exploitable.",
      );
    }

    if (mean < 38) {
      issues.add("Image trop sombre (luminosité moyenne : ${mean.toInt()} / 255).");
    }
    if (mean > 218) {
      issues.add("Image surexposée (luminosité moyenne : ${mean.toInt()} / 255).");
    }
    if (contrast < 18) {
      issues.add("Contraste insuffisant, l'image paraît terne.");
    }
    if (sharpness < 0.22) {
      issues.add("Image visiblement floue (netteté très faible).");
    } else if (sharpness < 0.38) {
      issues.add("Netteté limitée, l'image manque de détails.");
    }
    if (darkRatio > 0.45) {
      issues.add("Grande partie de l'image dans l'obscurité.");
    }

    // Décision du label + score
    String label;
    double score;

    if (mean < 38) {
      label = "Image trop sombre";
      score = 0.30;
    } else if (mean > 218) {
      label = "Image surexposée";
      score = 0.32;
    } else if (sharpness < 0.22) {
      label = "Image floue";
      score = (_qualityScore(sharpness, contrast) * 0.35);
    } else if (contrast < 18) {
      label = "Image de mauvaise qualité (contraste insuffisant)";
      score = 0.45;
    } else if (sharpness < 0.38) {
      label = "Image légèrement floue";
      score = 0.55;
    } else {
      label = "Image nette et exploitable";
      score = _qualityScore(sharpness, contrast);
    }

    return ImageQualityAnalysis(
      hasImage: true,
      width: originalW,
      height: originalH,
      label: label,
      score: score.clamp(0.0, 1.0),
      issues: issues.isEmpty ? const ['Aucun défaut détecté.'] : issues,
      visualHint: visualHint,
    );
  }

  static double _qualityScore(double sharpness, double contrast) {
    final s = sharpness.clamp(0.0, 1.0);
    final c = (contrast / 60.0).clamp(0.0, 1.0);
    return (0.55 * s + 0.45 * c).clamp(0.0, 1.0);
  }

  /// Décrit grossièrement la scène photographiée (couleurs dominantes)
  /// pour aider la vérification de cohérence avec la catégorie.
  static String? _describeVisualScene(img.Image image, double mean,
      double darkRatio, double brightRatio) {
    if (darkRatio > 0.6) {
      return "Scène très sombre évoquant un problème d'éclairage ou de nuit.";
    }
    if (brightRatio > 0.5) {
      return "Scène très lumineuse évoquant une route ou un espace ouvert éclairé.";
    }

    int green = 0;
    int blue = 0;
    int warm = 0;
    int neutral = 0;
    int total = 0;

    for (int y = 0; y < image.height; y += 3) {
      for (int x = 0; x < image.width; x += 3) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        final maxC = max(r, max(g, b));
        final minC = min(r, min(g, b));
        total++;

        if (maxC - minC < 24) {
          neutral++;
        } else {
          if (g >= r && g >= b && g > 90) {
            green++;
          } else if (b >= r && b > 80 && b - r > 25) {
            blue++;
          } else if (r >= b && r > 100) {
            warm++;
          }
        }
      }
    }

    if (total == 0) return "Aucun détail détecté.";
    if (green / total > 0.35) {
      return "Scène avec végétation visible (arbre, branche, espace vert).";
    }
    if (blue / total > 0.30) {
      return "Scène avec présence d'eau ou ciel dominant.";
    }
    if (warm / total > 0.35) {
      return "Scène dominée par des tons chauds (terre, poussière, bâtiment).";
    }
    if (neutral / total > 0.55) {
      return "Scène neutre (gris/terne) évoquant route, trottoir ou infrastructure.";
    }
    return "Scène photographiée riche en détails et exploitable.";
  }

  /// 🔎 Vérifie la cohérence entre la catégorie sélectionnée, la description
  /// et l'image fournie.
  static CoherenceResult checkCoherence({
    required String selectedCategory,
    required String description,
    required ImageQualityAnalysis quality,
  }) {
    const String coherent = "Cohérent";
    const String incoherent = "Incohérent";
    const String verify = "À vérifier";

    if (!quality.hasImage) {
      return CoherenceResult(
        status: "Sans image",
        message: "Aucune image fournie : la vérification visuelle est impossible.",
      );
    }

    String normalized = _normalizeCategory(selectedCategory);
    if (!_selectableCategoryKeywords.containsKey(normalized)) {
      // Catégorie non connue (ex : suggestion IA "Sécurité & Danger")
      return CoherenceResult(
        status: verify,
        message: "Catégorie non répertoriée pour la vérification automatique.",
      );
    }

    final expected = _selectableCategoryKeywords[normalized]!;
    final List<String> matched = <String>[];

    // Meilleure autre catégorie correspondant au texte
    String bestOther = '';
    int bestOtherScore = 0;

    _selectableCategoryKeywords.forEach((key, words) {
      if (key == normalized) return;
      int count = 0;
      for (final w in words) {
        if (description.contains(w)) count++;
      }
      if (count > 0 && count > bestOtherScore) {
        bestOtherScore = count;
        bestOther = _selectableCategoryLabels[key] ?? key;
      }
    });

    for (final w in expected) {
      if (description.contains(w)) matched.add(w);
    }

    if (matched.isNotEmpty && matched.length * 2 >= bestOtherScore) {
      final msg = quality.visualHint == null
          ? "La description confirme la catégorie '${_selectableCategoryLabels[normalized] ?? selectedCategory}' (mots-clés : ${matched.take(3).join(', ')})."
          : "La description confirme la catégorie '${_selectableCategoryLabels[normalized] ?? selectedCategory}' et l'image est exploitable.";
      return CoherenceResult(status: coherent, message: msg);
    }

    if (bestOtherScore >= 2) {
      final msg = "Incohérence probable : la description évoque la catégorie '$bestOther' alors que '$selectedCategory' est sélectionnée. Veuillez corriger la catégorie ou la description.";
      return CoherenceResult(status: incoherent, message: msg);
    }

    if (matched.isNotEmpty && bestOtherScore < 2) {
      return CoherenceResult(
        status: coherent,
        message:
            "La description contient des mots-clés compatibles avec '${_selectableCategoryLabels[normalized] ?? selectedCategory}'.",
      );
    }

    final hint = quality.visualHint;
    if (hint != null) {
      // L'indice visuel est-il en conflit avec la catégorie ?
      if ((normalized == 'éclairage' && hint.contains('route')) ||
          (normalized == 'routes' && hint.contains('éclairage'))) {
        return CoherenceResult(
          status: verify,
          message:
              "L'image et la catégorie semblent peu cohérentes ($hint). Vérifiez avant d'envoyer.",
        );
      }
      return CoherenceResult(
        status: verify,
        message:
            "Aucun mot-clé ne confirme la catégorie '$selectedCategory' dans la description. ($hint)",
      );
    }

    return CoherenceResult(
      status: verify,
      message:
          "Aucun mot-clé ne confirme la catégorie '$selectedCategory'. Précisez la description pour renforcer la vérification.",
    );
  }

  static String _normalizeCategory(String category) {
    final c = category.trim().toLowerCase();
    if (c.isEmpty) return '';
    if (c == 'route' || c == 'routes' || c == 'voirie') return 'routes';
    if (c == 'éclairage' || c == 'eclairage') return 'éclairage';
    if (c == 'assainissement' || c == 'déchet' || c == 'dechet' ||
        c == 'propreté' || c == 'proprete' || c == 'déchets') {
      return 'assainissement';
    }
    if (c.startsWith('eau') || c == 'fuites') return 'eau & fuites';
    if (c == 'école' || c == 'ecole') return 'école';
    if (c == 'infrastructure' || c == 'bâtiment' || c == 'batiment') {
      return 'infrastructure';
    }
    return c;
  }

  /// 🔎 Détection des Doublons Basée sur la Distance GPS (Haversine) et le Texte (Jaccard)
  static List<DuplicateMatch> findDuplicates({
    required String category,
    required String description,
    required double? lat,
    required double? lng,
    required List<SignalementModel> existingReports,
    double maxDistanceKm = 0.5, // Rayon de 500m par défaut
  }) {
    List<DuplicateMatch> matches = [];

    final inputTokens = _tokenize(description.toLowerCase());

    for (var report in existingReports) {
      // Ignorer les signalements résolus
      if (report.status == "Résolu") continue;

      double distanceMeters = double.infinity;
      bool isCloseByGps = false;

      if (lat != null && lng != null && report.latitude != null && report.longitude != null) {
        distanceMeters = _calculateHaversineDistance(
          lat, lng, report.latitude!, report.longitude!,
        );
        if (distanceMeters <= (maxDistanceKm * 1000)) {
          isCloseByGps = true;
        }
      }

      // Calcul de similarité textuelle
      final existingTokens = _tokenize(report.description.toLowerCase());
      double textSimilarity = _jaccardSimilarity(inputTokens, existingTokens);

      // Correspondance de catégorie
      bool sameCategory = report.categorie.toLowerCase() == category.toLowerCase();

      // Formule combinée de probabilité de doublon
      double probability = 0.0;
      if (sameCategory) probability += 0.35;
      if (isCloseByGps) {
        double distFactor = max(0.0, 1.0 - (distanceMeters / 500.0));
        probability += 0.40 * distFactor;
      }
      probability += 0.25 * textSimilarity;

      if (probability >= 0.45) {
        matches.add(DuplicateMatch(
          existingReport: report,
          distanceMeters: distanceMeters,
          similarityScore: probability,
          isHighProbability: probability >= 0.70,
        ));
      }
    }

    // Trier par probabilité décroissante
    matches.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return matches;
  }

  /// 🚨 Détection des Zones Critiques (Clusters de signalements non résolus)
  static Map<int, bool> evaluateCriticalZones(
    List<SignalementModel> reports, {
    double radiusKm = 0.5,
    int minReportsThreshold = 3,
  }) {
    Map<int, bool> criticalStatusMap = {};

    final activeReports = reports.where((r) => r.status != "Résolu" && r.latitude != null && r.longitude != null).toList();

    for (var report in activeReports) {
      if (report.id == null) continue;

      int nearbyCount = 0;
      for (var other in activeReports) {
        double dist = _calculateHaversineDistance(
          report.latitude!, report.longitude!,
          other.latitude!, other.longitude!,
        );
        if (dist <= (radiusKm * 1000)) {
          nearbyCount++;
        }
      }

      criticalStatusMap[report.id!] = nearbyCount >= minReportsThreshold;
    }

    return criticalStatusMap;
  }

  /// 📊 Recalcul Dynamique de la Priorité d'un Signalement avec Confirmatory Upvotes
  static String calculateUpdatedPriority(SignalementModel report, {int newUpvotes = 0}) {
    int totalVotes = report.upvotesCount + newUpvotes;

    if (report.priorite == "Haute" || totalVotes >= 5) {
      return "Haute";
    } else if (totalVotes >= 3 || report.priorite == "Moyenne") {
      return "Moyenne";
    }
    return "Basse";
  }

  /// 💡 Agent de conseil : génère des recommandations concrètes
  /// à partir de la description du problème signalé par l'utilisateur.
  static ConseilResult getConseil(String description) {
    final text = description.toLowerCase().trim();

    if (text.isEmpty) {
      return const ConseilResult(
        title: "Conseils généraux",
        steps: [
          "Décrivez la situation : type de problème, rue et repère le plus proche (carrefour, école, marché…).",
          "Prenez une photo nette et bien éclairée de la zone (jamais en plein danger).",
          "Envoyez votre position GPS depuis l'application pour accélérer l'intervention.",
          "Suivez l'évolution du signalement dans l'historique et re-signalez si rien ne bouge après 7 jours.",
        ],
      );
    }

    final bool isUrgent = _highSeverityKeywords.any(text.contains);
    final String? urgence =
        isUrgent ? "Urgence détectée : traitez ce problème en priorité absolue." : null;

    // ⚡ Poteau / câble électrique / Jirama sous tension ou tombé
    if (_hasAny(text, [
      'poteau', 'poleau', 'pylône', 'pyle', 'câble', 'fil électrique',
      'électrique', 'electricite', 'électricité', 'tension', 'jirama',
      'transformateur', 'sous tension', 'étincelle', 'etincelle', 'court-circuit',
    ])) {
      return ConseilResult(
        title: "Poteau ou ligne électrique (Jirama)",
        steps: [
          "Ne touchez JAMAIS le poteau ni les fils tombés : ils peuvent être sous tension (risque d'électrocution mortel).",
          "Éloignez les passants et surtout les enfants de la zone.",
          "Confinez la zone : ne laissez personne marcher dans l'eau ou à proximité des câbles.",
          "Contactez immédiatement la Jirama (appel gratuit *134 ou le contact service Eau de la messagerie).",
          "Photographiez à distance de sécurité et envoyez votre signalement avec la position GPS : l'équipe interviendra plus vite.",
          "Ne tentez jamais de réparer ou de repousser le câble vous-même.",
        ],
        urgence: urgence ?? "Danger potentiel : tension électrique. Restez à distance.",
      );
    }

    // 💧 Coupure d'eau / fuite / tuyau cassé
    if (_hasAny(text, [
      'coupure d\'eau', 'fuite', 'eau', 'tuyau', 'canalisation', 'inondé', 'inondation',
      'jaillit', 'robine', 'compteur', 'vanne',
    ])) {
      return ConseilResult(
        title: "Eau & fuites",
        steps: [
          "Si la fuite se situe chez vous, fermez la vanne principale pour limiter les dégâts.",
          "Notez le repère exact (rue, croisement, numéro) pour faciliter la localisation.",
          "Signalez via l'application : le service Eau (Jirama) est informé automatiquement.",
          "Surveillez l'eau stagnante : elle attire les moustiques et représente un risque sanitaire.",
          "Évacuons les biens sensibles vers une zone sèche pendant l'intervention.",
        ],
        urgence: isUrgent ? urgence : null,
      );
    }

    // 🗑️ Ordures / déchets / dépôt sauvage
    if (_hasAny(text, [
      'ordure', 'dechet', 'déchet', 'poubelle', 'dépôt', 'depot', 'amas',
      'saleté', 'salete', 'canal bouché', 'caniveau', 'égout',
    ])) {
      return ConseilResult(
        title: "Assainissement & déchets",
        steps: [
          "Repérez l'adresse et un point de repère (croisement, boutique, école).",
          "Ne brûlez jamais les ordures : les fumées sont toxiques pour le quartier.",
          "Ne jetez pas d'huile ou produits dangereux avec les ordures.",
          "Signalez via l'application : la CUA Propreté est informée pour la collecte.",
          "Si le dépôt bloque un canal, signalez-le aussi : les risques d'inondation augmentent vite.",
        ],
      );
    }

    // 🛣️ Route / nid-de-poule / chaussée dégradée
    if (_hasAny(text, [
      'trou', 'nid-de-poule', 'nid', 'crevasse', 'route', 'rue', 'chaussée',
      'chaussee', 'bitume', 'goudron', 'asphalte', 'trottoir', 'affaissement',
      'obstacle', 'accident',
    ])) {
      return ConseilResult(
        title: "Routes & trottoirs",
        steps: [
          "Ralentissez et gardez vos distances : un nid-de-poule peut faire chuter les deux-roues.",
          "Signalez la position précise (repère visible) : le service voirie interviendra selon la gravité.",
          "Si le trou représente un danger immédiat (profondeur, bordure coupante), alertez la gendarmerie.",
          "Rebouclez dans 7 jours si aucune intervention : re-signalez pour augmenter la priorité.",
        ],
        urgence: isUrgent ? urgence : null,
      );
    }

    // 💡 Éclairage / réverbère cassé
    if (_hasAny(text, [
      'lampadaire', 'reverbère', 'réverbère', 'lumière', 'lumiere', 'ampoule',
      'éclairage', 'eclairage', 'sombre', 'obscur', 'nuit', 'éteint', 'eteint',
    ])) {
      return ConseilResult(
        title: "Éclairage public",
        steps: [
          "Un réverbère en panne augmente l'insécurité la nuit : signalez-le vite.",
          "Indiquez le numéro du candélabre s'il est visible (pochoir sur le poteau).",
          "Prévenez vos voisins : témoigner en groupe accélère la prise en charge.",
          "En attendant, restez sur des axes éclairés et signalez tout comportement suspect à la gendarmerie.",
        ],
      );
    }

    // 🏫 École / bâtiment fissuré / infrastructure
    if (_hasAny(text, [
      'école', 'ecole', 'lycée', 'lycee', 'classe', 'salle de classe',
      'fissure', 'mur', 'toit', 'effondrement', 'plafond', 'poutre',
    ])) {
      return ConseilResult(
        title: "École & bâtiments",
        steps: [
          "Si une fissure s'agrandit, progresse en diagonale ou qu'un plafond se déforme : évacuez la pièce.",
          "Signalez à la direction ou au propriétaire + via l'application (photos avant/après).",
          "À l'école, interdisez l'accès à la salle concernée en attendant la visite technique.",
          "En cas de signe d'effondrement imminent : écartez tout le monde et appelez la gendarmerie.",
        ],
        urgence: isUrgent ? urgence : null,
      );
    }

    // 🌳 Arbre / branche menaçante / danger général
    if (_hasAny(text, [
      'arbre', 'branche', 'chute d\'arbre', 'penché', 'penche', 'sécurité',
      'securite', 'danger', 'risque',
    ])) {
      return ConseilResult(
        title: "Danger & sécurité",
        steps: [
          "Ne stationnez pas sous un arbre penché ou une branche fissurée.",
          "Informez les riverains, surtout avant un épisode de pluie ou de vent.",
          "Signalez via l'application : la mairie peut diligenter un élagage de sécurité.",
          "Si le danger est imminent pour des personnes, appelez la gendarmerie (19).",
        ],
        urgence: urgence ?? "Restez en alerte : situation potentiellement dangereuse.",
      );
    }

    // Cas général
    return ConseilResult(
      title: "Ce que je vous conseille",
      steps: [
        "Décrivez le plus précisément possible : nature du problème, rue et repère visible.",
        "Prenez une photo nette et bien éclairée (à distance de sécurité).",
        "Envoyez votre position GPS pour une intervention rapide.",
        "Utilisez la messagerie de l'application pour contacter le service concerné (mairie, jirama, propreté…).",
        "Re-signalez si aucune action n'est visible après 7 jours. Bon courage ! 💪",
      ],
      urgence: isUrgent ? urgence : null,
    );
  }

  static bool _hasAny(String text, List<String> words) {
    return words.any((w) => text.contains(w));
  }

  // ==========================================
  // FONCTIONS UTILITAIRES PRIVÉES (MATH & NLP)
  // ==========================================

  /// Formule de Haversine pour calculer la distance orthodromique entre 2 points GPS en mètres
  static double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Rayon moyen de la Terre en mètres
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) => degree * pi / 180.0;

  /// Tokenisation basique
  static List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\sàâäéèêëîïôöùûüç]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w.toLowerCase()))
        .toList();
  }

  /// Extraction des mots-clés significatifs
  static List<String> _extractKeywords(List<String> tokens) {
    Map<String, int> counts = {};
    for (var token in tokens) {
      counts[token] = (counts[token] ?? 0) + 1;
    }

    var sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Inférence Jaccard pour la similarité entre deux jeux de mots
  static double _jaccardSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final setA = a.toSet();
    final setB = b.toSet();

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;

    return intersection / union;
  }
}

/// Résultat de la vérification de cohérence.
class CoherenceResult {
  final String status; // "Cohérent", "Incohérent", "À vérifier", "Sans image"
  final String message;

  const CoherenceResult({required this.status, required this.message});

  bool get isBlocking => status == "Incohérent";
}

/// Conseils donnés par l'Agent de conseil (IA) à partir d'une description.
class ConseilResult {
  final String title;
  final List<String> steps;
  final String? urgence;

  const ConseilResult({
    required this.title,
    required this.steps,
    this.urgence,
  });

  String toText() {
    final buffer = StringBuffer(title);
    if (urgence != null) {
      buffer.writeln('\n\n⚠️ $urgence');
    }
    for (final step in steps) {
      buffer.writeln('\n• $step');
    }
    return buffer.toString();
  }
}