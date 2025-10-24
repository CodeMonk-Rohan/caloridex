//

import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single food item logged by the user
class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType; // "Breakfast", "Lunch", "Dinner", "Snacks"
  final DateTime timestamp;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'mealType': mealType,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      calories: (map['calories'] is int)
          ? map['calories']
          : int.tryParse(map['calories'].toString()) ?? 0,
      protein: (map['protein'] is num)
          ? (map['protein'] as num).toDouble()
          : double.tryParse(map['protein'].toString()) ?? 0.0,
      carbs: (map['carbs'] is num)
          ? (map['carbs'] as num).toDouble()
          : double.tryParse(map['carbs'].toString()) ?? 0.0,
      fat: (map['fat'] is num)
          ? (map['fat'] as num).toDouble()
          : double.tryParse(map['fat'].toString()) ?? 0.0,
      mealType: map['mealType'] ?? 'Unknown',
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

// Represents a single exercise logged by the user
class ExerciseItem {
  final String id;
  final String name;
  final int caloriesBurned;
  final DateTime timestamp;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.caloriesBurned,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'caloriesBurned': caloriesBurned,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ExerciseItem.fromMap(Map<String, dynamic> map) {
    return ExerciseItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      caloriesBurned: (map['caloriesBurned'] is int)
          ? map['caloriesBurned']
          : int.tryParse(map['caloriesBurned'].toString()) ?? 0,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

// Represents all the data for a single day
class DailyLog {
  final String date; // YYYY-MM-DD format
  final List<FoodItem> foodItems;
  final List<ExerciseItem> exerciseItems;
  final int calorieGoal;

  DailyLog({
    required this.date,
    required this.foodItems,
    required this.exerciseItems,
    required this.calorieGoal,
  });

  // Total calories consumed from food items
  int get totalCaloriesConsumed {
    return foodItems.fold(0, (sum, item) => sum + item.calories);
  }

  // Total calories burned from exercise items
  int get totalCaloriesBurned {
    return exerciseItems.fold(0, (sum, item) => sum + item.caloriesBurned);
  }

  double get totalProteinConsumed {
    return foodItems.fold(0.0, (sum, item) => sum + item.protein);
  }

  double get totalCarbsConsumed {
    return foodItems.fold(0.0, (sum, item) => sum + item.carbs);
  }

  double get totalFatConsumed {
    return foodItems.fold(0.0, (sum, item) => sum + item.fat);
  }

  factory DailyLog.fromSubcollections({
    required String dateId,
    required List<FoodItem> foods,
    required List<ExerciseItem> exercises,
    required int goal,
  }) {
    return DailyLog(
      date: dateId, // Use the document ID (YYYY-MM-DD)
      foodItems: foods,
      exerciseItems: exercises,
      calorieGoal: goal, // Use the goal passed in
    );
  }

  // Create an empty log for a given date and goal
  factory DailyLog.empty(String dateId, int goal) {
    return DailyLog(
      date: dateId,
      foodItems: [],
      exerciseItems: [],
      calorieGoal: goal,
    );
  }
}
