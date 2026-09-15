import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signalement_model.dart';

class SupabaseService {
  static const String tableName = 'signalement';

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
}