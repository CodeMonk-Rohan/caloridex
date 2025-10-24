import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  const LoginScreen({super.key, required this.onSwitchToRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _signIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      setState(() {
        _errorMessage = null;
      });
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CaloriDEX',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'SFProText',
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to continue your journey',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'SFProText',
                    color: const Color.fromARGB(189, 65, 65, 65),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ), // Set input text color to white
                  cursorColor: const Color.fromARGB(255, 0, 0, 0),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 242, 237, 237),
                    enabledBorder: OutlineInputBorder(
                      // Use enabledBorder for the non-focused state
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ), // Example: Slightly lighter grey
                        width: 1, // Example: Slightly thicker
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      // Border when focused
                      borderRadius: BorderRadius.circular(12),
                      // Set the color for the focused border
                      borderSide: BorderSide(
                        color: const Color.fromARGB(
                          188,
                          0,
                          0,
                          0,
                        ), // Example: Use accent color
                        width:
                            2.0, // Make the border slightly thicker when focused
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ), // Set input text color to white
                  cursorColor: const Color.fromARGB(255, 0, 0, 0),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 242, 237, 237),
                    enabledBorder: OutlineInputBorder(
                      // Use enabledBorder for the non-focused state
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ), // Example: Slightly lighter grey
                        width: 1, // Example: Slightly thicker
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      // Border when focused
                      borderRadius: BorderRadius.circular(12),
                      // Set the color for the focused border
                      borderSide: BorderSide(
                        color: const Color.fromARGB(
                          188,
                          0,
                          0,
                          0,
                        ), // Example: Use accent color
                        width:
                            2.0, // Make the border slightly thicker when focused
                      ),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 213, 77),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Log In', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onSwitchToRegister,
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 35, 35, 35),
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
