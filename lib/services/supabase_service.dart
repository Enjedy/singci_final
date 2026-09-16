import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/annonce_model.dart';
import '../models/signalement_model.dart';

class SupabaseService {
  static const String tableName = 'signalement';
  static const String annonceTable = 'annonces';
  static const String annonceCommentTable = 'annonce_comments';

  /// Bucket Supabase Storage contenant les photos des signalements et annonces.
  static const String storageBucket = 'signalements';

  static Future<List<SignalementModel>> getAllSignalements() async {
    final rows = await Supabase.instance.client.from(tableName).select();
    return rows.map((e) => SignalementModel.fromMap(e)).toList();
  }

  static Future<int> insertSignalement(SignalementModel model) async {
    final rows = await Supabase.instance.client
        .from(tableName)
        .insert(model.toMap())
        .select('id');
    if (rows.isNotEmpty && rows.first['id'] != null) {
      return (rows.first['id'] as num).toInt();
    }
    return 0;
  }

  static Future<void> upvote(int id) async {
    final rows = await Supabase.instance.client
        .from(tableName)
        .select('upvotesCount, priorite')
        .eq('id', id);
    if (rows.isEmpty) return;
    final next = ((rows.first['upvotesCount'] as num?) ?? 1) + 1;
    await Supabase.instance.client.from(tableName).update({
      'upvotesCount': next,
      if (next >= 5) 'priorite': 'Haute',
    }).eq('id', id);
  }

  static Future<void> updateStatus(int id, String status) async {
    await Supabase.instance.client
        .from(tableName)
        .update({'status': status})
        .eq('id', id);
  }

  static Future<void> deleteAll() async {
    await Supabase.instance.client.from(tableName).delete().gte('id', 0);
  }

  /// Envoie une photo locale vers Supabase Storage et renvoie son URL publique
  /// (de type `https://projectRef.supabase.co/storage/v1/object/public/signalements/...`).
  /// Retourne null si l'upload échoue (bucket introuvable, réseau, etc.).
  static Future<String?> uploadImageToStorage(String filePath) async {
    try {
      final file = File(filePath);
      final safeName = Uri.encodeComponent(
        file.uri.pathSegments.isEmpty ? 'photo.jpg' : file.uri.pathSegments.last,
      );
      final objectPath = 'signalements/'
          '${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final storage = Supabase.instance.client.storage.from(storageBucket);
      await storage.upload(
        objectPath,
        file,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      return storage.getPublicUrl(objectPath);
    } catch (_) {
      return null;
    }
  }

  // ============================ ANNONCES ============================

  /// Récupère toutes les annonces publiées par l'administration (les plus récentes d'abord).
  static Future<List<AnnonceModel>> getAllAnnonces() async {
    final rows = await Supabase.instance.client
        .from(annonceTable)
        .select()
        .order('datePublication', ascending: false);
    return rows.map((e) => AnnonceModel.fromMap(e)).toList();
  }

  /// Publie une nouvelle annonce et retourne son id.
  static Future<int> insertAnnonce(AnnonceModel model) async {
    final rows = await Supabase.instance.client
        .from(annonceTable)
        .insert(model.toMap())
        .select('id');
    if (rows.isNotEmpty && rows.first['id'] != null) {
      return (rows.first['id'] as num).toInt();
    }
    return 0;
  }

  /// Supprime une annonce (gestion administrateur).
  static Future<void> deleteAnnonce(int id) async {
    await Supabase.instance.client.from(annonceTable).delete().eq('id', id);
  }

  /// Incrémente (delta = +1) ou décrémente (delta = -1) le compteur de likes.
  static Future<void> addLikeAnnonce(int id, int delta) async {
    final rows = await Supabase.instance.client
        .from(annonceTable)
        .select('likes')
        .eq('id', id);
    if (rows.isEmpty) return;
    final current = (rows.first['likes'] as num?)?.toInt() ?? 0;
    final next = current + delta < 0 ? 0 : current + delta;
    await Supabase.instance.client
        .from(annonceTable)
        .update({'likes': next})
        .eq('id', id);
  }

  /// Récupère tous les commentaires citoyens (pour calculer les compteurs par annonce).
  static Future<List<AnnonceComment>> getAllAnnonceComments() async {
    final rows = await Supabase.instance.client
        .from(annonceCommentTable)
        .select()
        .order('created_at', ascending: false);
    return rows.map((e) => AnnonceComment.fromMap(e)).toList();
  }

  /// Récupère les commentaires d'une annonce précise.
  static Future<List<AnnonceComment>> getAnnonceComments(int annonceId) async {
    final rows = await Supabase.instance.client
        .from(annonceCommentTable)
        .select()
        .eq('annonceId', annonceId)
        .order('created_at', ascending: false);
    return rows.map((e) => AnnonceComment.fromMap(e)).toList();
  }

  /// Ajoute un commentaire citoyen à une annonce.
  static Future<void> insertAnnonceComment(AnnonceComment comment) async {
    await Supabase.instance.client
        .from(annonceCommentTable)
        .insert(comment.toMap());
  }
}