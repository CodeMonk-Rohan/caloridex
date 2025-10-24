import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../controllers/data_controller.dart';
import '../../../utils/health_calculator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  // Temporary profile to hold data during onboarding
  late UserProfile _tempProfile;
  bool _isInitialized = false; // Flag to ensure UID is set only once

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize _tempProfile with the UID from DataController only once
    if (!_isInitialized) {
      final dataController = Provider.of<DataController>(
        context,
        listen: false,
      );
      final uid = dataController.currentUser?.uid ?? ''; // Get UID safely
      _tempProfile = UserProfile(uid: uid);
      _isInitialized = true;
      print("Initialized onboarding with UID: $uid"); // Debugging
    }
  }

  void _nextPage() {
    int currentPage = _pageController.page!.round();
    if (currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Final step: Calculate goals and save
      final dataController = Provider.of<DataController>(
        context,
        listen: false,
      );
      // Ensure UID is correct before recalculating and saving
      if (_tempProfile.uid.isNotEmpty) {
        _tempProfile = HealthCalculator.recalculateGoals(_tempProfile);
        print("Saving profile: ${_tempProfile.toMap()}"); // Debugging
        dataController.saveUserProfile(_tempProfile);
        // AuthGate will automatically navigate away after saveUserProfile notifies listeners
      } else {
        print(
          "Error: Cannot save profile, UID is empty.",
        ); // Should not happen if AuthGate works correctly
        // Optionally show an error message
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we don't try to build if UID hasn't been initialized yet
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent swiping
                children: [
                  _buildStepContainer("Step 1 of 3: About You", _buildStep1()),
                  _buildStepContainer(
                    "Step 2 of 3: Your Lifestyle",
                    _buildStep2(),
                  ),
                  _buildStepContainer("Step 3 of 3: Your Goal", _buildStep3()),
                ],
              ),
            ),
            // Simple indicator (optional)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDotIndicator(index)),
            ),
            const SizedBox(height: 10),
            // Continue/Finish Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  (_pageController.positions.isNotEmpty &&
                          _pageController.page?.round() == 2)
                      ? 'Finish Setup'
                      : 'Continue',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for consistent page layout ---
  Widget _buildStepContainer(String title, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }

  // --- Dot Indicator ---
  Widget _buildDotIndicator(int index) {
    double currentPage = (_pageController.positions.isNotEmpty
        ? _pageController.page ?? 0.0
        : 0.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: currentPage.round() == index
            ? Theme.of(context).colorScheme.secondary
            : Colors.grey[600],
      ),
    );
  }

  // --- Widgets for each step ---
  Widget _buildStep1() {
    return Column(
      children: [
        _buildGenderPicker(),
        const SizedBox(height: 25),
        _buildNumberStepper(
          "Age",
          _tempProfile.age,
          13,
          100,
          (val) => setState(() => _tempProfile.age = val),
        ),
        const SizedBox(height: 25),
        _buildNumberStepper(
          "Weight (kg)",
          _tempProfile.weightKg.toInt(),
          30,
          200,
          (val) => setState(() => _tempProfile.weightKg = val.toDouble()),
        ),
        const SizedBox(height: 25),
        _buildNumberStepper(
          "Height (cm)",
          _tempProfile.heightCm.toInt(),
          100,
          250,
          (val) => setState(() => _tempProfile.heightCm = val.toDouble()),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(children: [_buildActivityLevelPicker()]);
  }

  Widget _buildStep3() {
    return Column(children: [_buildGoalPicker()]);
  }

  // --- Reusable input widgets ---

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        SegmentedButton<Gender>(
          segments: const [
            ButtonSegment<Gender>(
              value: Gender.male,
              label: Text('Male'),
              icon: Icon(Icons.male),
            ),
            ButtonSegment<Gender>(
              value: Gender.female,
              label: Text('Female'),
              icon: Icon(Icons.female),
            ),
          ],
          selected: {_tempProfile.gender},
          onSelectionChanged: (Set<Gender> newSelection) {
            setState(() {
              _tempProfile.gender = newSelection.first;
            });
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            selectedForegroundColor: Theme.of(
              context,
            ).colorScheme.primary, // Use primary color
            selectedBackgroundColor: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberStepper(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: value > min ? () => onChanged(value - 1) : null,
                    color: value > min
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey[600],
                    iconSize: 28,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: value < max ? () => onChanged(value + 1) : null,
                    color: value < max
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey[600],
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select your usual activity level",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ActivityLevel>(
          value: _tempProfile.activityLevel,
          isExpanded: true, // Make dropdown take full width
          items: ActivityLevel.values.map((ActivityLevel level) {
            return DropdownMenuItem<ActivityLevel>(
              value: level,
              child: Text(
                UserProfile(
                  uid: '',
                  activityLevel: level,
                ).getActivityLevelDisplay(),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (ActivityLevel? newValue) {
            if (newValue != null) {
              setState(() {
                _tempProfile.activityLevel = newValue;
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
          dropdownColor: Colors.grey[850],
          iconEnabledColor: Colors.white70,
        ),
      ],
    );
  }

  Widget _buildGoalPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What is your primary goal?",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Goal>(
          value: _tempProfile.goal,
          isExpanded: true,
          items: Goal.values.map((Goal goal) {
            return DropdownMenuItem<Goal>(
              value: goal,
              child: Text(
                UserProfile(uid: '', goal: goal).getGoalDisplay(),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (Goal? newValue) {
            if (newValue != null) {
              setState(() {
                _tempProfile.goal = newValue;
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
          dropdownColor: Colors.grey[850],
          iconEnabledColor: Colors.white70,
        ),
      ],
    );
  }
}
