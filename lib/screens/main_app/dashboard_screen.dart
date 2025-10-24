import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Data and Models
import '../../controllers/data_controller.dart';
import '../../models/daily_log.dart';
import '../../models/user_profile.dart';

// AI and Camera
import '../../ai/tflite_helper.dart'; // Import TFLite helper
import 'logging/camera_scan_screen.dart'; // Import camera scan screen

// UI Widgets and Screens
import 'widgets/calorie_progress_ring.dart';
import 'widgets/daily_log_list.dart';
import 'widgets/calendar_strip.dart'; // Import Calendar
import 'widgets/macronutrient_rings.dart'; // Import Macros
import 'logging/manual_food_log_screen.dart';
import 'logging/exercise_log_screen.dart';

// Convert to StatefulWidget to manage TFLiteHelper lifecycle
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TFLiteHelper _tfliteHelper; // Instance of our TFLite helper

  @override
  void initState() {
    super.initState();
    _tfliteHelper = TFLiteHelper();
    // Load model after the first frame is built to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use context safely here if needed for asset loading inside loadModel
      _tfliteHelper.loadModel();
    });
  }

  @override
  void dispose() {
    _tfliteHelper.dispose();
    super.dispose();
  }

  // --- Helper method to show the bottom sheet menu ---
  void _showAddItemSheet(BuildContext context) {
    // Note: Use the 'context' passed into this method.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Use ctx (builder context) for Navigator.pop
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Log Food Manually',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context, // Use original context
                    MaterialPageRoute(
                      builder: (context) => const ManualFoodLogScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.fitness_center,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Log Exercise',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context, // Use original context
                    MaterialPageRoute(
                      builder: (context) => const ExerciseLogScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title: const Text(
                  'Scan Meal with Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context, // Use original context
                    MaterialPageRoute(
                      builder: (context) =>
                          CameraScanScreen(tfliteHelper: _tfliteHelper),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- Method to show dialog for updating calorie goal ---
  void _showUpdateGoalDialog(BuildContext context, int currentGoal) {
    final dataController = Provider.of<DataController>(context, listen: false);
    final TextEditingController goalController = TextEditingController(
      text: currentGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            "Update Daily Goal",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "New Calorie Goal",
              labelStyle: TextStyle(color: Colors.grey[400]),
              suffixText: "kcal",
              suffixStyle: TextStyle(color: Colors.grey[400]),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                "Update",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              onPressed: () {
                final newGoal = int.tryParse(goalController.text);
                if (newGoal != null && newGoal > 0) {
                  dataController.updateCalorieGoalForSelectedDate(newGoal);
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to DataController for real-time updates
    final dataController = Provider.of<DataController>(context);
    final userProfile = dataController.userProfile;
    final selectedLog = dataController.selectedLog;

    // ** FIX 1: Use the correct public isLoading getter **
    final bool isLoading = dataController.isLoading;

    // Handle initial profile loading state OR if userProfile becomes null
    // Use isLoading here instead of isLoadingProfile
    if (isLoading && userProfile == null) {
      // More precise check for initial load
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Handle case where profile is somehow null after loading (shouldn't happen with AuthGate)
    if (userProfile == null) {
      return const Scaffold(
        body: Center(child: Text("Error: User profile not found.")),
      );
    }

    // Safely get goal, falling back to profile goal if log is null
    int goal = selectedLog?.calorieGoal ?? userProfile.dailyCalorieGoal;
    // Calculate totals only if log is loaded (not null and not currently loading)
    int consumed = (isLoading || selectedLog == null)
        ? 0
        : selectedLog.totalCaloriesConsumed;
    int burned = (isLoading || selectedLog == null)
        ? 0
        : selectedLog.totalCaloriesBurned;
    int remaining = (goal + burned) - consumed;

    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        // ** CHANGE 1: Set title to app name **
        title: const Text(
          'CaloriDEX',
          style: TextStyle(
            fontFamily: 'SFProText', // Use the family name from pubspec.yaml
            fontWeight: FontWeight.w600, // Example: Use Semibold weight
          ),
        ),
        // ** CHANGE 2: Remove centerTitle to align title left **
        // centerTitle: true, // Remove or comment out this line
        actions: [
          // ** CHANGE 3: Ensure Logout button is present **
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              // Call signOut from DataController
              Provider.of<DataController>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Strip
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: CalendarStrip(),
          ),
          const Divider(height: 1, color: Colors.white24),

          // Scrollable content area
          Expanded(
            // *** THE FIX IS HERE: Use the combined 'isLoading' getter ***
            child:
                isLoading // Show loading indicator if profile OR log is loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Calorie Ring and Stats Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              CalorieProgressRing(
                                consumed: consumed,
                                goal: goal,
                                burned: burned,
                                remaining: remaining,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatRow(
                                    context,
                                    "Goal",
                                    goal,
                                    Icons.flag_outlined,
                                    Colors.blueAccent,
                                    () {
                                      _showUpdateGoalDialog(context, goal);
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  _buildStatRow(
                                    context,
                                    "Food",
                                    consumed,
                                    Icons.restaurant_menu,
                                    Colors.greenAccent,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildStatRow(
                                    context,
                                    "Exercise",
                                    burned,
                                    Icons.local_fire_department,
                                    Colors.orangeAccent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Macronutrient Rings Section
                          Text("Macronutrients" /* ... style ... */),
                          const SizedBox(height: 10),
                          selectedLog != null
                              ? MacroNutrientRings(
                                  userProfile: userProfile,
                                  dailyLog: selectedLog,
                                )
                              : const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text(
                                      "Log food to see macros",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                          const Divider(height: 30, color: Colors.white24),

                          // Daily Log Section
                          Text("Daily Log" /* ... style ... */),
                          const SizedBox(height: 16),
                          // *** THE FIX IS HERE: Ensure selectedLog is not null before passing ***
                          selectedLog == null ||
                                  (selectedLog.foodItems.isEmpty &&
                                      selectedLog.exerciseItems.isEmpty)
                              ? const Center(
                                  /* ... (empty state message) ... */
                                )
                              : DailyLogList(
                                  dailyLog: selectedLog,
                                ), // Correctly pass selectedLog
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context), // Add the action here
        tooltip: 'Log Item',
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.black,
      ),
    );
  }

  // --- _buildStatRow method remains the same ---
  Widget _buildStatRow(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color, [
    VoidCallback? onTap,
  ]) {
    // ... (code for this helper method is unchanged)
    Widget content = Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        // Add edit icon if onTap is provided (for Goal)
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.edit_note, color: Colors.grey[600], size: 18),
        ],
      ],
    );

    // Make tappable only if onTap is provided
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: content,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: content,
      );
    }
  }
}
