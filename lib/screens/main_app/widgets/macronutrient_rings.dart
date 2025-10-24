import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../models/user_profile.dart';
import '../../../models/daily_log.dart';

class MacroNutrientRings extends StatelessWidget {
  final UserProfile userProfile;
  final DailyLog dailyLog;

  const MacroNutrientRings({
    super.key,
    required this.userProfile,
    required this.dailyLog,
  });

  @override
  Widget build(BuildContext context) {
    // Get macro goals from profile
    final proteinGoal = userProfile.proteinGoalGrams;
    final carbsGoal = userProfile.carbsGoalGrams;
    final fatGoal = userProfile.fatGoalGrams;

    // Get consumed macros from log
    final proteinConsumed = dailyLog.totalProteinConsumed;
    final carbsConsumed = dailyLog.totalCarbsConsumed;
    final fatConsumed = dailyLog.totalFatConsumed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMacroRing(
            context,
            "Protein",
            proteinConsumed,
            proteinGoal.toDouble(),
            Colors.blueAccent,
          ),
          _buildMacroRing(
            context,
            "Carbs",
            carbsConsumed,
            carbsGoal.toDouble(),
            Colors.greenAccent,
          ),
          _buildMacroRing(
            context,
            "Fat",
            fatConsumed,
            fatGoal.toDouble(),
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRing(
    BuildContext context,
    String label,
    double consumed,
    double goal,
    Color color,
  ) {
    double percent = goal == 0 ? 0 : (consumed / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 40.0,
          lineWidth: 8.0,
          percent: percent,
          center: Text(
            "${consumed.toStringAsFixed(0)}g",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: Colors.white,
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: color,
          backgroundColor: Colors.grey[800]!,
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        Text(
          "${goal.toStringAsFixed(0)}g Goal",
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
        ),
      ],
    );
  }
}
