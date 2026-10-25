class NutritionInfo {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  NutritionInfo({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      proteinG: (json['protein_g'] as num? ?? 0).toDouble(),
      carbsG: (json['carbs_g'] as num? ?? 0).toDouble(),
      fatG: (json['fat_g'] as num? ?? 0).toDouble(),
      fiberG: (json['fiber_g'] as num? ?? 0).toDouble(),
      sugarG: (json['sugar_g'] as num? ?? 0).toDouble(),
      sodiumMg: (json['sodium_mg'] as num? ?? 0).toDouble(),
    );
  }

  static NutritionInfo empty() => NutritionInfo(
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
    fiberG: 0,
    sugarG: 0,
    sodiumMg: 0,
  );
}

class FoodAnalysisResult {
  final String foodName;
  final int calories;
  final String servingSize;
  final NutritionInfo nutrition;
  final List<String> ingredients;
  final List<String> allergens;
  final String healthNotes;
  final int healthScore;
  final List<String> dietTags;

  FoodAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.servingSize,
    required this.nutrition,
    required this.ingredients,
    required this.allergens,
    required this.healthNotes,
    required this.healthScore,
    required this.dietTags,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      foodName: json['food_name'] as String? ?? 'Unknown',
      calories: (json['calories'] as num? ?? 0).toInt(),
      servingSize: json['serving_size'] as String? ?? '1 serving',
      nutrition: json['nutrition'] is Map
          ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
          : NutritionInfo.empty(),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
      healthNotes: json['health_notes'] as String? ?? '',
      healthScore: (json['health_score'] as num? ?? 5).toInt().clamp(1, 10),
      dietTags: List<String>.from(json['diet_tags'] ?? []),
    );
  }
}