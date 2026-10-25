class FoodHistoryItem {
  final String id;
  final String foodName;
  final int calories;
  final List<String> ingredients;
  final String healthNotes;
  final DateTime timestamp;
  final String? imagePath;

  FoodHistoryItem({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.ingredients,
    required this.healthNotes,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'foodName': foodName,
    'calories': calories,
    'ingredients': ingredients,
    'healthNotes': healthNotes,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };

  factory FoodHistoryItem.fromJson(Map<String, dynamic> json) {
    return FoodHistoryItem(
      id: json['id'],
      foodName: json['foodName'],
      calories: json['calories'],
      ingredients: List<String>.from(json['ingredients']),
      healthNotes: json['healthNotes'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
    );
  }

  factory FoodHistoryItem.fromSupabaseJson(Map<String, dynamic> json) {
    return FoodHistoryItem(
      id: json['id'],
      foodName: json['food_name'],
      calories: json['calories'],
      ingredients: List<String>.from(json['ingredients']),
      healthNotes: json['health_notes'],
      timestamp: DateTime.parse(json['created_at']),
      imagePath: json['image_path'],
    );
  }
}