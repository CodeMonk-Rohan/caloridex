import '../models/user_profile.dart';

class HealthCalculator {
  // Calculates Basal Metabolic Rate (BMR)
  static double calculateBMR(UserProfile profile) {
    double bmr;
    if (profile.gender == Gender.male) {
      // Mifflin-St Jeor Equation for men
      bmr =
          (10 * profile.weightKg) +
          (6.25 * profile.heightCm) -
          (5 * profile.age) +
          5;
    } else {
      // Mifflin-St Jeor Equation for women
      bmr =
          (10 * profile.weightKg) +
          (6.25 * profile.heightCm) -
          (5 * profile.age) -
          161;
    }
    return bmr;
  }

  // Calculates Active Metabolic Rate (AMR)
  static double calculateAMR(double bmr, ActivityLevel activityLevel) {
    double multiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        multiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        multiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.725;
        break;
      case ActivityLevel.extraActive:
        multiplier = 1.9;
        break;
    }
    return bmr * multiplier;
  }

  // Calculates Daily Calorie Target based on goal
  static int calculateDailyTarget(double amr, Goal goal) {
    double adjustment; // Calorie deficit/surplus per day
    switch (goal) {
      case Goal.loseHalfKg:
        adjustment = -500;
        break; // Approx 500 kcal deficit/day for 0.5kg/week loss
      case Goal.loseQuarterKg:
        adjustment = -250;
        break;
      case Goal.maintainWeight:
        adjustment = 0;
        break;
      case Goal.gainQuarterKg:
        adjustment = 250;
        break;
      case Goal.gainHalfKg:
        adjustment = 500;
        break;
    }
    return (amr + adjustment).round(); // Round to nearest whole calorie
  }

  // Recalculates the daily calorie goal based on the profile data
  static UserProfile recalculateGoals(UserProfile profile) {
    final bmr = calculateBMR(profile);
    final amr = calculateAMR(bmr, profile.activityLevel);
    profile.dailyCalorieGoal = calculateDailyTarget(amr, profile.goal);
    return profile; // Return the updated profile
  }
}
