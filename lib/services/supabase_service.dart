import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_history_item.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  String get _userId {
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('No authenticated user');
    }
    return uid;
  }

  Future<List<FoodHistoryItem>> fetchHistory() async {
    try {
      final response = await client
          .from('food_history')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return response
          .map<FoodHistoryItem>((e) => FoodHistoryItem.fromSupabaseJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  Future<void> insertHistory(FoodHistoryItem item) async {
    try {
      await client.from('food_history').insert({
        'user_id': _userId,
        'food_name': item.foodName,
        'calories': item.calories,
        'ingredients': item.ingredients,
        'health_notes': item.healthNotes,
        'image_path': item.imagePath,
        'created_at': item.timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save history: $e');
    }
  }

  Future<void> deleteHistory(String id) async {
    try {
      await client
          .from('food_history')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await client
          .from('food_history')
          .delete()
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to clear history: $e');
    }
  }
}