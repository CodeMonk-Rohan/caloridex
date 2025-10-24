import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'api/auth_service.dart';
import 'controllers/data_controller.dart';
import 'ai/tflite_helper.dart'; // Import the helper
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => DataController()),
        // --- ADD TFLiteHelper PROVIDER ---
        Provider<TFLiteHelper>(
          create: (_) => TFLiteHelper(),
          // Optional: If loadModel is async and needed early, consider FutureProvider
          // or load it within the DashboardScreen's initState
          lazy: false, // Load it immediately when the app starts
        ),
        // --- END OF ADDED PROVIDER ---
      ],
      child: const CaloriDEX(),
    ),
  );
}

class CaloriDEX extends StatelessWidget {
  const CaloriDEX({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Add the navigatorKey needed by TFLiteHelper for asset loading context
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CaloriDEX',
      theme: ThemeData(
        /* ... your theme data ... */
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.grey[850],
        dialogBackgroundColor: Colors.grey[850],
        colorScheme:
            ColorScheme.fromSwatch(
              brightness: Brightness.dark,
              primarySwatch: Colors.teal,
            ).copyWith(
              secondary: Colors.tealAccent,
              surface: Colors.grey[800],
              onSurface: Colors.white,
              primary: Colors.teal,
              onPrimary: Colors.black,
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.tealAccent),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.tealAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.tealAccent),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
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
        ),
      ),
      home: const AuthGate(),
    );
  }
}
