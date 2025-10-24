// import 'package:flutter/material.dart';
// import 'dart:math';

// class CalorieProgressRing extends StatelessWidget {
//   final int consumed;
//   final int goal;
//   final int burned;
//   final int remaining;

//   const CalorieProgressRing({
//     super.key,
//     required this.consumed,
//     required this.goal,
//     required this.burned,
//     required this.remaining,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final double progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

//     return SizedBox(
//       width: 220,
//       height: 220,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Background track
//           SizedBox(
//             width: 220,
//             height: 220,
//             child: CircularProgressIndicator(
//               value: 1.0,
//               strokeWidth: 14,
//               backgroundColor: Colors.grey[800],
//               color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
//             ),
//           ),
//           // Progress arc
//           SizedBox(
//             width: 220,
//             height: 220,
//             child: Transform.rotate(
//               angle: -pi / 2,
//               child: CircularProgressIndicator(
//                 value: progress,
//                 strokeWidth: 14,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   Theme.of(context).colorScheme.primary,
//                 ),
//                 strokeCap: StrokeCap.round,
//               ),
//             ),
//           ),
//           // Central text content
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 '$remaining',
//                 style: Theme.of(context).textTheme.displaySmall?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Text(
//                 'Remaining',
//                 style: TextStyle(color: Colors.white70, fontSize: 16),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Make sure this is imported
import '../../../models/user_profile.dart'; // Assuming you might need profile info later, keep if already there
import '../../../models/daily_log.dart'; // Assuming you might need log info later, keep if already there

class CalorieProgressRing extends StatelessWidget {
  final int consumed;
  final int goal;
  final int burned;
  final int remaining;

  const CalorieProgressRing({
    super.key,
    required this.consumed,
    required this.goal,
    required this.burned,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage (handle goal being 0)
    double progress = goal == 0 ? 0 : consumed / goal;
    progress = progress.clamp(
      0.0,
      1.0,
    ); // Ensure progress stays between 0 and 1

    // Determine color based on remaining calories
    Color progressColor = Colors.greenAccent;
    if (remaining < 0) {
      progressColor = Colors.redAccent; // Over the limit
    } else if (remaining < goal * 0.15) {
      // Nearing the limit
      progressColor = Colors.orangeAccent;
    }

    // --- ADJUST SIZE HERE ---
    const double ringDiameter = 220.0; // New, smaller diameter
    const double ringRadius = ringDiameter / 2;
    const double lineWidth = 14.0; // Can adjust line width too if desired

    return SizedBox(
      width: ringDiameter, // Use new diameter
      height: ringDiameter, // Use new diameter
      child: Stack(
        fit: StackFit.expand, // Ensure Stack fills SizedBox
        children: [
          // Background Ring
          CircularPercentIndicator(
            radius: ringRadius, // Use new radius
            lineWidth: lineWidth,
            percent: 1.0, // Full circle
            backgroundColor: Colors.grey[800]!,
            progressColor: Colors.grey[700]!.withOpacity(
              0.5,
            ), // Slightly visible background track
          ),
          // Progress Ring
          CircularPercentIndicator(
            radius: ringRadius, // Use new radius
            lineWidth: lineWidth,
            percent: progress,
            center: Column(
              // Center Text Content
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  remaining >= 0 ? '$remaining' : '${remaining.abs()}',
                  // ** ADJUST FONT SIZE **
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    // Changed from displayMedium
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  remaining >= 0 ? 'KCAL LEFT' : 'KCAL OVER',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    // Slightly smaller label
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0, // Add some spacing
                  ),
                ),
                const SizedBox(height: 10), // Adjust spacing
                // // Smaller text for Goal, Consumed, Burned
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //   _buildStatColumn('Goal', goal, Colors.grey[400]!),
                    //   const SizedBox(width: 12), // Adjust spacing
                    _buildStatColumn('Food', consumed, Colors.blueAccent),
                    const SizedBox(width: 12), // Adjust spacing
                    _buildStatColumn('Exer', burned, Colors.orangeAccent),
                  ],
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round, // Make ends rounded
            progressColor: progressColor,
            backgroundColor:
                Colors.transparent, // Background handled by separate indicator
          ),
        ],
      ),
    );
  }

  // Helper widget for the small stat columns
  Widget _buildStatColumn(String label, int value, Color color) {
    // ** ADJUST FONT SIZES HERE TOO **
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 12, // Smaller value text
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9, // Smaller label text
          ),
        ),
      ],
    );
  }
}
