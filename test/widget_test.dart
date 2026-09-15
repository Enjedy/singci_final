import 'package:flutter_test/flutter_test.dart';
import 'package:signci/models/signalement_model.dart';
import 'package:signci/models/ai_analysis_result.dart';
import 'package:signci/services/ai_service.dart';
import 'package:signci/services/location_service.dart';
import 'package:signci/services/validation_service.dart';

void main() {
  group('SignalementModel', () {
    test('creates from map correctly', () {
      final model = SignalementModel(
        type: 'Lieu public',
        categorie: 'Routes',
        probleme: 'Route endommagée',
        description: 'Un trou dans la rue',
        adresse: 'Analakely, Antananarivo',
        image: 'img.jpg',
      );
      expect(model.type, 'Lieu public');
      expect(model.categorie, 'Routes');
      expect(model.status, 'En attente');
      expect(model.priorite, 'Moyenne');
    });

    test('toMap/fromMap roundtrip', () {
      final model = SignalementModel(
        id: 42,
        type: 'Bâtiment',
        categorie: 'École',
        probleme: 'Mur fissuré',
        description: 'Fissure dans le mur',
        adresse: 'Ambohimanarina',
        image: '',
        latitude: -18.9,
        longitude: 47.5,
        keywords: ['fissure', 'mur'],
      );
      final map = model.toMap();
      final restored = SignalementModel.fromMap(map);
      expect(restored.id, 42);
      expect(restored.type, 'Bâtiment');
      expect(restored.keywords, ['fissure', 'mur']);
      expect(restored.latitude, closeTo(-18.9, 0.01));
    });
  });

  group('AIAnalysisResult', () {
    test('toMap/fromMap roundtrip', () {
      final result = AIAnalysisResult(
        suggestedType: 'Lieu public',
        suggestedCategory: 'Routes',
        suggestedProblem: 'Nid-de-poule',
        keywords: ['trou', 'route'],
        severity: 'Haute',
        confidenceScore: 0.85,
        imageQualityLabel: 'Image nette et exploitable',
        imageQualityScore: 0.88,
        imageIssues: ['Aucun défaut détecté.'],
        coherenceStatus: 'Cohérent',
        coherenceMessage: 'La description confirme Routes.',
        explanation: 'Test explanation.',
      );
      final map = result.toMap();
      final restored = AIAnalysisResult.fromMap(map);
      expect(restored.suggestedCategory, 'Routes');
      expect(restored.imageQualityScore, 0.88);
      expect(restored.coherenceStatus, 'Cohérent');
      expect(restored.isBlocking, false);
    });

    test('isBlocking is true when coherence is Incohérent', () {
      final result = AIAnalysisResult(
        suggestedType: 'Lieu public',
        suggestedCategory: 'Routes',
        suggestedProblem: 'Test',
        keywords: [],
        severity: 'Basse',
        confidenceScore: 0.5,
        coherenceStatus: 'Incohérent',
        coherenceMessage: 'Incohérence',
        explanation: '',
      );
      expect(result.isBlocking, true);
    });
  });

  group('AIService image quality analysis', () {
    test('analyzeImageQuality handles nonexistent file', () async {
      final result = await AIService.analyzeImageQuality('/nonexistent/path.jpg');
      expect(result.hasImage, true);
      expect(result.label, 'Image inexploitable');
      expect(result.score, 0.0);
    });

    test('analyzeImageQuality handles nonexistent file gracefully', () async {
      final result = await AIService.analyzeImageQuality('/no/file.png');
      expect(result.hasImage, true);
      expect(result.score, lessThan(0.5));
    });
  });

  group('AIService coherence check', () {
    test('returns "Sans image" when no image', () {
      final quality = ImageQualityAnalysis.noImage();
      final result = AIService.checkCoherence(
        selectedCategory: 'Routes',
        description: 'Un trou dans la rue',
        quality: quality,
      );
      expect(result.status, 'Sans image');
    });
  });

  group('AIService conseil (agent de conseil)', () {
    test('advises Jirama safety steps for a downed power pole', () {
      final conseil = AIService.getConseil(
          'Il y a un poteau Jirama coupé dans ma rue avec des câbles tombés');
      expect(conseil.title.toLowerCase(), contains('jirama'));

      final text = conseil.toText().toLowerCase();
      expect(text, contains('ne touchez jamais'));
      expect(text, contains('photographiez à distance de sécurité'));
      expect(conseil.urgence, isNotNull);
    });

    test('advises water steps for a water cut', () {
      final conseil = AIService.getConseil('Coupure d\'eau depuis 2 jours dans le quartier');
      expect(conseil.title.toLowerCase(), contains('eau'));
      expect(conseil.toText(), contains('vanne'));
    });

    test('returns generic advice for unknown problem', () {
      final conseil = AIService.getConseil('Le marchand de légumes change de place');
      expect(conseil.steps, isNotEmpty);
      expect(conseil.toText(), contains('position GPS'));
    });
  });

  group('LocationService', () {
    test('isWithinAntananarivo returns true for center of Tana', () {
      expect(LocationService.isWithinAntananarivo(-18.8792, 47.5079), true);
    });

    test('isWithinAntananarivo returns false for far away city', () {
      expect(LocationService.isWithinAntananarivo(0, 0), false);
    });
  });

  group('ValidationService', () {
    test('fails when description is empty', () {
      final result = ValidationService.validateSignalement(
        probleme: 'Route endommagée',
        description: '',
        adresse: 'Analakely',
        latitude: -18.87,
        longitude: 47.50,
        images: [],
      );
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('description')), true);
    });

    test('fails when no GPS', () {
      final result = ValidationService.validateSignalement(
        probleme: 'Route endommagée',
        description: 'Un trou dans la rue qui menace les piétons',
        adresse: 'Analakely',
        latitude: null,
        longitude: null,
        images: [],
      );
      expect(result.isValid, false);
    });

    test('fails when GPS outside Antananarivo', () {
      final result = ValidationService.validateSignalement(
        probleme: 'Route endommagée',
        description: 'Un trou dans la rue qui menace les piétons',
        adresse: 'Analakely',
        latitude: 48.85,
        longitude: 2.35,
        images: [],
      );
      expect(result.isValid, false);
    });

    test('passes with valid data (no images)', () {
      final result = ValidationService.validateSignalement(
        probleme: 'Route endommagée',
        description: 'Un trou important dans la rue devant l\'école',
        adresse: 'Analakely, Antananarivo',
        latitude: -18.87,
        longitude: 47.50,
        images: [],
      );
      expect(result.isValid, false); // no images
    });
  });
}