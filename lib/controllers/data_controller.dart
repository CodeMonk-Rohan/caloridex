import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // For StreamSubscription
import 'package:rxdart/rxdart.dart'; // Import rxdart

import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../utils/health_calculator.dart';

class DataController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _logSubscription; // To listen to real-time log updates

  User? _currentUser;
  UserProfile? _userProfile;
  DailyLog?
  _selectedLog; // Changed from _todayLog to represent the selected date's log
  DateTime _selectedDate =
      DateTime.now(); // Track the date the user selects on the calendar

  bool _isLoadingProfile = true; // Tracks profile loading
  bool _isLoadingLog = false; // Tracks log loading for selected date
  bool _profileNeedsCompletion = false;

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  DailyLog? get selectedLog => _selectedLog; // Updated getter
  DateTime get selectedDate => _selectedDate; // Getter for selected date
  bool get isLoading =>
      _isLoadingProfile || _isLoadingLog; // Combined loading state
  bool get profileNeedsCompletion => _profileNeedsCompletion;

  DataController() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Helper to get date string in YYYY-MM-DD format
  String _getDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // --- Authentication State Change ---
  Future<void> _onAuthStateChanged(User? user) async {
    _isLoadingProfile = true; // Start loading profile state
    _isLoadingLog = false; // Reset log loading
    _profileNeedsCompletion = false;
    _userProfile = null;
    _selectedLog = null;
    _selectedDate = DateTime.now();
    _logSubscription?.cancel();
    notifyListeners(); // Notify UI that overall loading has started

    _currentUser = user;

    if (user != null) {
      // --- MODIFICATION START ---
      try {
        await _loadUserProfile(user.uid); // Attempt to load the profile

        // Check completion status *after* loading attempt
        if (!_profileNeedsCompletion && _userProfile != null) {
          // Profile loaded successfully and is complete, now load log
          await _loadOrCreateLogForDate(user.uid, _selectedDate);
        }
        // If profile loading resulted in _profileNeedsCompletion = true,
        // or if _userProfile is still null, the AuthGate will handle showing onboarding.
      } catch (e) {
        print("Error during profile/log loading sequence: $e");
        // Ensure flags are set correctly even if _loadUserProfile throws an unexpected error
        _userProfile = null;
        _profileNeedsCompletion = true;
      } finally {
        // ** CRITICAL FIX **: Ensure loading flag is set to false *after* all loading attempts
        _isLoadingProfile = false;
        // Note: _isLoadingLog is handled within _loadOrCreateLogForDate's listener
        notifyListeners(); // Notify UI that profile loading attempt is finished
      }
      // --- MODIFICATION END ---
    } else {
      // No user, stop profile loading immediately
      _isLoadingProfile = false;
      notifyListeners();
    }
    // _isLoadingLog state is managed within _loadOrCreateLogForDate
  }

  // --- Profile Management ---
  Future<void> _loadUserProfile(String uid) async {
    try {
      DocumentSnapshot profileDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (profileDoc.exists &&
          (profileDoc.data() as Map<String, dynamic>)['profileComplete'] ==
              true) {
        _userProfile = UserProfile.fromFirestore(profileDoc);
        _profileNeedsCompletion = false;
        print("Profile loaded successfully.");
      } else {
        _userProfile = null;
        _profileNeedsCompletion = true;
        print("Profile needs completion or doesn't exist.");
      }
    } catch (e) {
      print("Error loading user profile: $e");
      _userProfile = null;
      _profileNeedsCompletion = true;
    }
    // Don't notify listeners here, let _onAuthStateChanged handle it after log loading attempt
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (_currentUser == null || profile.uid != _currentUser!.uid) return;
    try {
      // Recalculate goals before saving
      UserProfile updatedProfile = HealthCalculator.recalculateGoals(profile);
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(updatedProfile.toMap(), SetOptions(merge: true));
      _userProfile = updatedProfile; // Update local profile
      _profileNeedsCompletion = false;
      // Load log for the currently selected date with potentially updated goal
      await _loadOrCreateLogForDate(profile.uid, _selectedDate);
      notifyListeners(); // Notify UI about profile and potential log update
      print("User profile saved successfully.");
    } catch (e) {
      print("Error saving user profile: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // _onAuthStateChanged listener handles UI updates and clearing data
  }

  // --- Log Management ---

  // Called when the user taps a date on the calendar strip
  Future<void> changeSelectedDate(DateTime newDate) async {
    if (_currentUser == null) return;
    // Check if the date actually changed to avoid unnecessary reloads
    if (_getDateString(newDate) == _getDateString(_selectedDate)) return;

    _selectedDate = newDate;
    _isLoadingLog = true; // Start loading indicator for the log
    _selectedLog = null; // Clear old log while loading
    notifyListeners();

    await _loadOrCreateLogForDate(
      _currentUser!.uid,
      newDate,
    ); // Fetch/create log for the new date

    // Loading indicator is turned off within the _loadOrCreateLogForDate listener
  }

  // Loads the log for a specific date, creates it if it doesn't exist, and listens for real-time updates
  // Loads the log for a specific date, creates it if it doesn't exist, and listens for real-time updates
  Future<void> _loadOrCreateLogForDate(String uid, DateTime date) async {
    _logSubscription?.cancel(); // Stop listening to the previous date's log
    final dateString = _getDateString(date);

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(dateString);
    final foodCollectionRef = docRef.collection('food_items');
    final exerciseCollectionRef = docRef.collection('exercise_items');

    _logSubscription =
        CombineLatestStream.combine2(
              foodCollectionRef
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              exerciseCollectionRef
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              // This combiner function processes the snapshots synchronously
              (QuerySnapshot foodSnap, QuerySnapshot exerciseSnap) {
                // Use different names here
                final foods = foodSnap.docs
                    .map(
                      (doc) =>
                          FoodItem.fromMap(doc.data() as Map<String, dynamic>),
                    )
                    .toList();
                final exercises = exerciseSnap.docs
                    .map(
                      (doc) => ExerciseItem.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();
                // Return the processed lists in a map
                return {'foods': foods, 'exercises': exercises};
              },
            )
            // asyncMap receives the map and fetches the goal asynchronously
            .asyncMap((data) async {
              DocumentSnapshot logDoc = await docRef.get();
              int currentGoal =
                  _userProfile?.dailyCalorieGoal ?? 2000; // Fallback

              if (logDoc.exists &&
                  (logDoc.data() as Map<String, dynamic>).containsKey(
                    'calorieGoal',
                  )) {
                currentGoal =
                    (logDoc.data() as Map<String, dynamic>)['calorieGoal'];
              }

              // *** THIS IS THE CORRECTED PART ***
              // Use the 'data' map passed into asyncMap
              final foodItems = data['foods'] as List<FoodItem>;
              final exerciseItems = data['exercises'] as List<ExerciseItem>;
              // *** END OF CORRECTION ***

              // Create the DailyLog object using the correct variables
              return DailyLog.fromSubcollections(
                dateId: dateString,
                foods: foodItems, // Use variable from asyncMap scope
                exercises: exerciseItems, // Use variable from asyncMap scope
                goal: currentGoal,
              );
            })
            .listen(
              (dailyLog) {
                // The listener receives the DailyLog object
                _selectedLog = dailyLog;
                if (_isLoadingLog) _isLoadingLog = false;
                notifyListeners();
                print("Log updated for date: $dateString");
              },
              onError: (error) {
                print("Error listening to log for $dateString: $error");
                _selectedLog = DailyLog.empty(
                  dateString,
                  _userProfile?.dailyCalorieGoal ?? 2000,
                );
                _isLoadingLog = false;
                notifyListeners();
              },
            );

    // Set an initial empty log immediately
    if (_selectedLog == null && !_isLoadingLog) {
      _selectedLog = DailyLog.empty(
        dateString,
        _userProfile?.dailyCalorieGoal ?? 2000,
      );
      notifyListeners();
    }
  }

  Future<void> addFoodItem(FoodItem food) async {
    if (_currentUser == null) return;
    final dateString = _getDateString(_selectedDate); // Use selected date
    final docRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('daily_logs')
        .doc(dateString);

    try {
      // Ensure the main log document exists and has the correct goal
      // Use the *current* goal from the loaded log or profile
      int goalForDay =
          _selectedLog?.calorieGoal ?? _userProfile!.dailyCalorieGoal;
      await docRef.set({
        'date': Timestamp.fromDate(_selectedDate),
        'calorieGoal': goalForDay,
      }, SetOptions(merge: true));

      // Add food item to the subcollection
      await docRef.collection('food_items').doc(food.id).set(food.toMap());
      // No need to manually update local state, the listener (_listenToTodayLog) will do it
      print("Food item added: ${food.name}");
    } catch (e) {
      print("Error adding food item: $e");
    }
  }

  Future<void> addExerciseItem(ExerciseItem exercise) async {
    if (_currentUser == null) return;
    final dateString = _getDateString(_selectedDate); // Use selected date
    final docRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('daily_logs')
        .doc(dateString);
    try {
      // Ensure the main log document exists and has the correct goal
      int goalForDay =
          _selectedLog?.calorieGoal ?? _userProfile!.dailyCalorieGoal;
      await docRef.set({
        'date': Timestamp.fromDate(_selectedDate),
        'calorieGoal': goalForDay,
      }, SetOptions(merge: true));

      // Add exercise item to the subcollection
      await docRef
          .collection('exercise_items')
          .doc(exercise.id)
          .set(exercise.toMap());
      // Listener handles UI update
      print("Exercise item added: ${exercise.name}");
    } catch (e) {
      print("Error adding exercise item: $e");
    }
  }

  // Update the calorie goal specifically for the selected day
  Future<void> updateCalorieGoalForSelectedDate(int newGoal) async {
    if (_currentUser == null || _selectedLog == null) return;
    final dateString = _getDateString(_selectedDate);
    print("Updating goal for $dateString to $newGoal");
    try {
      // --- Update Firestore ---
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('daily_logs')
          .doc(dateString)
          // Ensure the document exists before updating, or create it
          .set({'calorieGoal': newGoal}, SetOptions(merge: true));

      // --- THE FIX: Update local state immediately ---
      // Create a new DailyLog instance with the updated goal
      // This is safer than trying to modify the existing immutable object
      _selectedLog = DailyLog(
        date: _selectedLog!.date,
        foodItems: _selectedLog!.foodItems,
        exerciseItems: _selectedLog!.exerciseItems,
        calorieGoal: newGoal, // Use the new goal here
      );
      print("Local selectedLog goal updated to $newGoal");

      // Tell the UI to rebuild with the new data
      notifyListeners();
      // --- END OF FIX ---
    } catch (e) {
      print("Error updating calorie goal: $e");
      // Optionally show an error message to the user
    }
  }

  @override
  void dispose() {
    _logSubscription?.cancel(); // Clean up the Firestore listener
    super.dispose();
  }
}
