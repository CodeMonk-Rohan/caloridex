import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:provider/provider.dart';
import '../../../controllers/data_controller.dart';
import 'package:intl/intl.dart';

class CalendarStrip extends StatefulWidget {
  const CalendarStrip({super.key});

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  // Create a controller for the DatePicker
  final DatePickerController _controller = DatePickerController();
  DateTime? _lastSelectedDate; // Keep track of the last selected date

  @override
  void initState() {
    super.initState();
    // Jump to today's date initially after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialDate = Provider.of<DataController>(
        context,
        listen: false,
      ).selectedDate;
      _controller.animateToDate(
        initialDate,
        duration: const Duration(milliseconds: 100),
      ); // Animate smoothly
      _lastSelectedDate = initialDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the DataController for changes in selectedDate
    final dataController = Provider.of<DataController>(context);
    final selectedDate = dataController.selectedDate;

    // --- KEY FIX: Check if the date has changed externally ---
    // If the selectedDate in the controller is different from the last date
    // we knew about, programmatically jump the calendar.
    if (_lastSelectedDate != null &&
        _getDateString(selectedDate) != _getDateString(_lastSelectedDate!)) {
      print(
        "CalendarStrip: Date changed in controller to $selectedDate, animating...",
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Animate after the build is complete
        _controller.animateToDate(
          selectedDate,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      _lastSelectedDate = selectedDate; // Update our tracked date
    } else if (_lastSelectedDate == null) {
      // Handle initial load case if initState callback didn't run yet or failed
      _lastSelectedDate = selectedDate;
    }
    // --- END OF KEY FIX ---

    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(const Duration(days: 30));
    final DateTime endDate = today.add(const Duration(days: 7));

    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DatePicker(
        startDate,
        controller: _controller, // Assign the controller
        width: 60,
        height: 85,
        initialSelectedDate: selectedDate, // Still useful for initial display
        selectionColor: Theme.of(context).colorScheme.primary,
        selectedTextColor: Colors.black,
        dayTextStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        monthTextStyle: const TextStyle(
          fontSize: 9,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
        dateTextStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        daysCount: endDate.difference(startDate).inDays + 1,

        onDateChange: (date) {
          // Update the controller's internal state AND tell DataController
          print("CalendarStrip: User selected date: $date");
          _lastSelectedDate = date; // Update tracked date immediately
          dataController.changeSelectedDate(date);
        },
      ),
    );
  }

  // Helper to compare dates without time
  String _getDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
