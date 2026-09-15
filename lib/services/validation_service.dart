import 'dart:io';
import '../models/ai_analysis_result.dart';
import 'location_service.dart';

/// Résultat d'une validation de signalement.
class ValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({this.errors = const [], this.warnings = const []});

  bool get isValid => errors.isEmpty;

  String get errorsSummary => errors.join("\n• ");
}

/// Service de validation robuste des signalements avant envoi.
/// Empêche les signalements incorrects, incomplets ou incohérents.
class ValidationService {
  static const int minDescriptionLength = 15;
  static const int maxDescriptionLength = 2000;
  static const double minImageQualityThreshold = 0.35;

  /// "Autre (précisez le problème)" doit être accompagné d'un texte.
  static const String customProblemMarker = "Autre";

  static ValidationResult validateSignalement({
    required String probleme,
    required String description,
    required String adresse,
    required double? latitude,
    required double? longitude,
    required List<File> images,
    AIAnalysisResult? aiResult,
  }) {
    final List<String> errors = [];
    final List<String> warnings = [];

    String p = probleme.trim();
    String d = description.trim();
    String a = adresse.trim();

    // 1. Problème sélectionné
    if (p.isEmpty) {
      errors.add("Veuillez sélectionner un problème.");
    } else if (p.contains(customProblemMarker) && p.trim().length <= customProblemMarker.length) {
      errors.add("Précisez le problème (le choix « Autre » nécessite une description).");
    }

    // 2. Description
    if (d.isEmpty) {
      errors.add("La description du problème est obligatoire.");
    } else if (d.length < minDescriptionLength) {
      errors.add("Description trop courte ($d.length caractères, minimum $minDescriptionLength).");
    } else if (d.length > maxDescriptionLength) {
      errors.add("Description trop longue (maximum $maxDescriptionLength caractères).");
    }

    // 3. Adresse (doit être remplie automatiquement par le GPS)
    if (a.isEmpty) {
      errors.add("L'adresse est obligatoire. Activez le GPS pour une localisation automatique.");
    }

    // 4. Position GPS
    if (latitude == null || longitude == null) {
      errors.add("Position GPS indisponible. Activez le GPS pour localiser le problème.");
    } else if (!LocationService.isWithinAntananarivo(latitude, longitude)) {
      errors.add("Position hors de la zone couverte (Antananarivo uniquement).");
    }

    // 5. Photos
    if (images.isEmpty) {
      errors.add("Au moins une photo est requise.");
    }

    // 6. Validation IA
    if (aiResult != null) {
      // Qualité d'image
      if (aiResult.imageQualityScore < minImageQualityThreshold &&
          aiResult.imageQualityScore > 0.0) {
        errors.add(
            "Image inexploitable par l'IA : ${aiResult.imageQualityLabel}. "
            "Prenez une photo nette, bien éclairée et de bonne qualité.");
      }
      if (aiResult.coherenceStatus == "Incohérent") {
        errors.add(aiResult.coherenceMessage);
      } else if (aiResult.coherenceStatus == "À vérifier") {
        warnings.add(aiResult.coherenceMessage);
      }
      if (aiResult.isBlocking && aiResult.imageQualityScore > 0.0) {
        errors.add("Le signalement est bloqué par la vérification IA.");
      }
    }

    return ValidationResult(errors: errors, warnings: warnings);
  }
}