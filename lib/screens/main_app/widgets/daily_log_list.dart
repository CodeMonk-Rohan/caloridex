import 'package:flutter/material.dart';
import '../../../models/daily_log.dart';

class DailyLogList extends StatelessWidget {
  final DailyLog dailyLog;
  const DailyLogList({super.key, required this.dailyLog});

  @override
  Widget build(BuildContext context) {
    // Filter food items by their meal type from the real log data
    final breakfastItems = dailyLog.foodItems
        .where((i) => i.mealType == 'Breakfast')
        .toList();
    final lunchItems = dailyLog.foodItems
        .where((i) => i.mealType == 'Lunch')
        .toList();
    final dinnerItems = dailyLog.foodItems
        .where((i) => i.mealType == 'Dinner')
        .toList();
    final snackItems = dailyLog.foodItems
        .where((i) => i.mealType == 'Snacks')
        .toList();

    // Create a list of all log categories that contain items
    List<Widget> logCategories = [];
    if (breakfastItems.isNotEmpty) {
      logCategories.add(
        _buildLogCategory(
          context,
          "Breakfast",
          breakfastItems,
          Icons.free_breakfast,
        ),
      );
    }
    if (lunchItems.isNotEmpty) {
      logCategories.add(
        _buildLogCategory(context, "Lunch", lunchItems, Icons.lunch_dining),
      );
    }
    if (dinnerItems.isNotEmpty) {
      logCategories.add(
        _buildLogCategory(context, "Dinner", dinnerItems, Icons.dinner_dining),
      );
    }
    if (snackItems.isNotEmpty) {
      logCategories.add(
        _buildLogCategory(context, "Snacks", snackItems, Icons.fastfood),
      );
    }
    if (dailyLog.exerciseItems.isNotEmpty) {
      logCategories.add(
        _buildLogCategory(
          context,
          "Exercise",
          dailyLog.exerciseItems,
          Icons.fitness_center,
          isExercise: true,
        ),
      );
    }

    // If no items have been logged at all, show a helpful message
    if (logCategories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            "No items logged yet today.\nTap the '+' button to add a meal or exercise!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    // Build the list of category cards
    return Column(children: logCategories);
  }

  // A reusable widget to build a card for each category (e.g., Breakfast)
  Widget _buildLogCategory(
    BuildContext context,
    String title,
    List<dynamic> items,
    IconData icon, {
    bool isExercise = false,
  }) {
    Color iconColor = isExercise
        ? Colors.orangeAccent
        : Theme.of(context).colorScheme.secondary;

    // Calculate the total calories for this specific category
    int totalCalories = items.fold(0, (sum, item) {
      if (isExercise) {
        return sum + (item as ExerciseItem).caloriesBurned;
      } else {
        return sum + (item as FoodItem).calories;
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header (Title, Icon, Total Calories)
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  isExercise
                      ? '$totalCalories kcal burned'
                      : '$totalCalories kcal',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),

            // List of items within the category
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                String itemName = isExercise
                    ? (item as ExerciseItem).name
                    : (item as FoodItem).name;
                int itemCalories = isExercise
                    ? (item as ExerciseItem).caloriesBurned
                    : (item as FoodItem).calories;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          itemName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        isExercise
                            ? '$itemCalories burned'
                            : '$itemCalories kcal',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
