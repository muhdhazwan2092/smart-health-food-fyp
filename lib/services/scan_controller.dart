import 'dart:io';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../models/food_history_item.dart';
import '../models/food_analysis_result.dart';

class ScanController {
  final ApiService api;
  final SupabaseService supabase;
  final StorageService storage;

  ScanController({
    required this.api,
    required this.supabase,
    required this.storage,
  });

  Future<FoodAnalysisResult> analyze(File image) async {
    return await api.analyzeImage(image);
  }

  Future<FoodAnalysisResult> analyzeBytes(Uint8List bytes) async {
    return api.analyzeBytes(bytes);
  }

  Future<void> saveResult(
    FoodAnalysisResult result,
    String imagePath,
    List<FoodHistoryItem> currentHistory,
  ) async {
    final item = FoodHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodName: result.foodName,
      calories: result.calories,
      ingredients: result.ingredients,
      healthNotes: result.healthNotes,
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );

    currentHistory.insert(0, item);

    await storage.saveHistory(currentHistory);
    await supabase.insertHistory(item);
  }
}
