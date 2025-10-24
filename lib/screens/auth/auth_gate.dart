// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../api/auth_service.dart';
// import '../../controllers/data_controller.dart'; // Import DataController
// import 'login_or_register.dart';
// // import '../main_app/dashboard_screen.dart'; // We will create this next
// import '../../main_app/onboarding/onboarding_screen.dart'; // Import Onboarding screen

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<User?>(
//         // Listen to Firebase Auth state changes
//         stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
//         builder: (context, authSnapshot) {
//           // Show loading indicator while checking auth state
//           if (authSnapshot.connectionState == ConnectionState.waiting) {
//             print("AuthGate: Waiting for auth state..."); // Debugging
//             return const Center(child: CircularProgressIndicator());
//           }

//           // User is logged in
//           if (authSnapshot.hasData) {
//              print("AuthGate: User is logged in (${authSnapshot.data!.uid}). Checking profile..."); // Debugging
//             // Use Consumer to react to DataController changes
//             return Consumer<DataController>(
//               builder: (context, dataController, child) {
//                 // Show loading indicator while DataController loads profile
//                 if (dataController.isLoading) {
//                    print("AuthGate: DataController is loading profile..."); // Debugging
//                    return const Center(child: CircularProgressIndicator());
//                 }
//                 // If profile needs completion, show Onboarding
//                 if (dataController.profileNeedsCompletion) {
//                    print("AuthGate: Profile needs completion. Showing OnboardingScreen."); // Debugging
//                    return const OnboardingScreen();
//                 }
//                 // If profile is complete, show Dashboard (Placeholder)
//                 else {
//                   print("AuthGate: Profile is complete. Showing Dashboard placeholder."); // Debugging
//                   // return const DashboardScreen(); // We will create this next
//                    return const Scaffold(
//                       backgroundColor: Color(0xFF121212), // Match theme
//                       body: Center(child: Text(
//                           "Profile Complete! Dashboard goes here.",
//                           style: TextStyle(color: Colors.white, fontSize: 18),
//                         )
//                       )
//                    );
//                 }
//               },
//             );
//           }
//           // User is NOT logged in
//           else {
//             print("AuthGate: User is not logged in. Showing LoginOrRegister."); // Debugging
//             return const LoginOrRegister();
//           }
//         },
//       ),
//     );
//   }
// }

// // --- LoginOrRegister Widget (Handles switching between login/signup) ---
// class LoginOrRegister extends StatefulWidget {
//   const LoginOrRegister({super.key});
//   @override
//   State<LoginOrRegister> createState() => _LoginOrRegisterState();
// }
// class _LoginOrRegisterState extends State<LoginOrRegister> {
//   bool showLoginPage = true; // Start with login page
//   // Function passed to child screens to allow toggling
//   void togglePages() {
//     setState(() { showLoginPage = !showLoginPage; });
//   }
//   @override
//   Widget build(BuildContext context) {
//     if (showLoginPage) {
//       // Pass the toggle function to LoginScreen
//       return LoginScreen(onSwitchToRegister: togglePages);
//     } else {
//       // Pass the toggle function to SignUpScreen
//       return SignUpScreen(onSwitchToLogin: togglePages);
//     }
//   }
// }
// // Import the actual screen files
// import 'login_screen.dart';
// import 'signup_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/auth_service.dart';
import '../../controllers/data_controller.dart'; // Import DataController
import 'login_screen.dart'; // Correctly imports the login screen file
import 'signup_screen.dart'; // Correctly imports the signup screen file

// We will create this file in a later step, so the import is commented out for now.
import '../main_app/dashboard_screen.dart';
import '../main_app/onboarding/onboarding_screen.dart'; // Import Onboarding screen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to Firebase Auth state changes
        stream: Provider.of<AuthService>(
          context,
          listen: false,
        ).authStateChanges,
        builder: (context, authSnapshot) {
          // Show loading indicator while checking auth state
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            print("AuthGate: Waiting for auth state..."); // Debugging
            return const Center(child: CircularProgressIndicator());
          }

          // User is logged in
          if (authSnapshot.hasData) {
            print(
              "AuthGate: User is logged in (${authSnapshot.data!.uid}). Checking profile...",
            ); // Debugging
            // Use Consumer to react to DataController changes
            return Consumer<DataController>(
              builder: (context, dataController, child) {
                // Show loading indicator while DataController loads profile
                if (dataController.isLoading) {
                  print(
                    "AuthGate: DataController is loading profile...",
                  ); // Debugging
                  return const Center(child: CircularProgressIndicator());
                }
                // If profile needs completion, show Onboarding
                if (dataController.profileNeedsCompletion) {
                  print(
                    "AuthGate: Profile needs completion. Showing OnboardingScreen.",
                  ); // Debugging
                  return const OnboardingScreen();
                }
                // If profile is complete, show Dashboard (Placeholder)
                else {
                  print(
                    "AuthGate: Profile is complete. Showing Dashboard placeholder.",
                  ); // Debugging
                  // return const DashboardScreen(); // We will create this next
                  return const DashboardScreen();
                }
              },
            );
          }
          // User is NOT logged in
          else {
            print(
              "AuthGate: User is not logged in. Showing LoginOrRegister.",
            ); // Debugging
            return const LoginOrRegister(); // Use the widget defined below
          }
        },
      ),
    );
  }
}

// --- LoginOrRegister Widget (Handles switching between login/signup) ---
// It is correctly placed in the same file, so no separate import is needed.
class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});
  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showLoginPage = true; // Start with login page
  // Function passed to child screens to allow toggling
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      // Pass the toggle function to LoginScreen
      return LoginScreen(onSwitchToRegister: togglePages);
    } else {
      // Pass the toggle function to SignUpScreen
      return SignUpScreen(onSwitchToLogin: togglePages);
    }
  }
}
