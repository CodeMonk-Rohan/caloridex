// A simple local database mapping food labels to nutritional info.
// In a real app, this would be a much larger database, possibly online.

class NutrientInfo {
  final int calories; // Per 100g
  final double protein; // Per 100g
  final double carbs; // Per 100g
  final double fat; // Per 100g

  NutrientInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class NutritionDatabase {
  // IMPORTANT: The keys (e.g., "idli") MUST EXACTLY MATCH the names in your labels.txt file, but in lowercase.
  static final Map<String, NutrientInfo> _database = {
    'idli': NutrientInfo(
      calories: 39,
      protein: 1,
      carbs: 8,
      fat: 0.2,
    ), // Per piece
    'dosa': NutrientInfo(
      calories: 168,
      protein: 3.9,
      carbs: 29,
      fat: 4.8,
    ), // Per plain dosa
    'poha': NutrientInfo(
      calories: 180,
      protein: 2.9,
      carbs: 40,
      fat: 1.2,
    ), // Per 100g
    'upma': NutrientInfo(
      calories: 250,
      protein: 6,
      carbs: 45,
      fat: 5,
    ), // Per 100g
    'medu vada': NutrientInfo(
      calories: 97,
      protein: 4,
      carbs: 13,
      fat: 3.3,
    ), // Per piece (medu vada)
    'rice': NutrientInfo(
      calories: 130,
      protein: 2.7,
      carbs: 28,
      fat: 0.3,
    ), // Per 100g cooked
    'chapati': NutrientInfo(
      calories: 85,
      protein: 3,
      carbs: 18,
      fat: 0.5,
    ), // Per piece
    'samosa': NutrientInfo(
      calories: 262,
      protein: 4,
      carbs: 24,
      fat: 17,
    ), // Per piece
    'chole bhature': NutrientInfo(
      calories: 450,
      protein: 12,
      carbs: 60,
      fat: 18,
    ), // Per serving
    'biryani': NutrientInfo(
      calories: 290,
      protein: 15,
      carbs: 35,
      fat: 10,
    ), // Per 100g chicken biryani
  };

  // Public method to get nutrient info for a detected label
  static NutrientInfo? getNutrientInfo(String label) {
    return _database[label.toLowerCase()];
  }
}
