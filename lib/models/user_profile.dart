import 'package:cloud_firestore/cloud_firestore.dart';

// Enums for dropdown selections
enum Gender { male, female }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive,
}

enum Goal {
  loseHalfKg,
  loseQuarterKg,
  maintainWeight,
  gainQuarterKg,
  gainHalfKg,
}

class UserProfile {
  final String uid; // Link to Firebase Auth User
  Gender gender;
  int age;
  double weightKg;
  double heightCm;
  ActivityLevel activityLevel;
  Goal goal;
  int dailyCalorieGoal; // Calculated value
  // Macro Goals - Defined here with defaults
  double targetProteinPercentage;
  double targetCarbsPercentage;
  double targetFatPercentage;

  UserProfile({
    required this.uid,
    this.gender = Gender.male,
    this.age = 25,
    this.weightKg = 70.0,
    this.heightCm = 175.0,
    this.activityLevel = ActivityLevel.sedentary,
    this.goal = Goal.maintainWeight,
    this.dailyCalorieGoal = 2000,
    // Add macro goals to the constructor with defaults
    this.targetProteinPercentage = 0.30,
    this.targetCarbsPercentage = 0.40,
    this.targetFatPercentage = 0.30,
  });

  // Convert UserProfile object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'gender': gender.toString().split('.').last, // Store enum as string
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'activityLevel': activityLevel.toString().split('.').last,
      'goal': goal.toString().split('.').last,
      'dailyCalorieGoal': dailyCalorieGoal,
      'profileComplete': true, // Mark profile as complete after saving
      'targetProteinPercentage': targetProteinPercentage, // Save macro goals
      'targetCarbsPercentage': targetCarbsPercentage,
      'targetFatPercentage': targetFatPercentage,
    };
  }

  // --- THIS IS THE CORRECTED FACTORY METHOD ---
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? '',
      gender: Gender.values.firstWhere(
        (e) => e.toString().split('.').last == data['gender'],
        orElse: () => Gender.male, // Default if data is missing/invalid
      ),
      age: data['age'] ?? 25,
      weightKg: (data['weightKg'] ?? 70.0).toDouble(),
      heightCm: (data['heightCm'] ?? 175.0).toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == data['activityLevel'],
        orElse: () => ActivityLevel.sedentary,
      ),
      goal: Goal.values.firstWhere(
        (e) => e.toString().split('.').last == data['goal'],
        orElse: () => Goal.maintainWeight,
      ),
      dailyCalorieGoal: data['dailyCalorieGoal'] ?? 2000,
      // *** THE FIX IS HERE: Pass the loaded/default macro values ***
      targetProteinPercentage: (data['targetProteinPercentage'] ?? 0.30)
          .toDouble(),
      targetCarbsPercentage: (data['targetCarbsPercentage'] ?? 0.40).toDouble(),
      targetFatPercentage: (data['targetFatPercentage'] ?? 0.30).toDouble(),
      // *** END OF FIX ***
    );
  }
  // --- END OF CORRECTED FACTORY METHOD ---

  // --- Helper Methods for Display ---
  String getActivityLevelDisplay() {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return "Sedentary (little or no exercise)";
      case ActivityLevel.lightlyActive:
        return "Lightly Active (exercise 1-3 days/week)";
      case ActivityLevel.moderatelyActive:
        return "Moderately Active (exercise 3-5 days/week)";
      case ActivityLevel.veryActive:
        return "Very Active (exercise 6-7 days/week)";
      case ActivityLevel.extraActive:
        return "Extra Active (very hard exercise & physical job)";
    }
  }

  String getGoalDisplay() {
    switch (goal) {
      case Goal.loseHalfKg:
        return "Lose 0.5 kg per week";
      case Goal.loseQuarterKg:
        return "Lose 0.25 kg per week";
      case Goal.maintainWeight:
        return "Maintain weight";
      case Goal.gainQuarterKg:
        return "Gain 0.25 kg per week";
      case Goal.gainHalfKg:
        return "Gain 0.5 kg per week";
    }
  }

  // Getters to calculate macro goals in grams
  int get proteinGoalGrams =>
      ((dailyCalorieGoal * targetProteinPercentage) / 4).round();
  int get carbsGoalGrams =>
      ((dailyCalorieGoal * targetCarbsPercentage) / 4).round();
  int get fatGoalGrams =>
      ((dailyCalorieGoal * targetFatPercentage) / 9).round();
}
