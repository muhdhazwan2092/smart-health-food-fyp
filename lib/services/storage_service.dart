import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_history_item.dart';

class StorageService {
  Future<List<FoodHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('food_history') ?? [];

    return data
        .map((e) => FoodHistoryItem.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> saveHistory(List<FoodHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final data = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('food_history', data);
  }
}