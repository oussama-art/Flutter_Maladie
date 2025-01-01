import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import './HomeScreen.dart'; 
import './LandingPage.dart'; // Create this for the landing page
import 'package:http/http.dart' as http;
import 'api_config.dart'; // Your API configuration file

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final bool isTokenValid = await _isTokenValid();

    if (isTokenValid) {
      // Navigate to HomeScreen if token is valid
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Navigate to LandingPage if token is invalid
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
    }
  }

  /// Helper function to check token validity
  Future<bool> _isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      // Token is absent
      return false;
    }

    String baseUrl = ApiConfig.baseUrl;
    final String url = "$baseUrl/api/compte";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Token is valid
        return true;
      } else {
        // Token is invalid, clear it
        await prefs.remove('auth_token');
        return false;
      }
    } catch (e) {
      // Handle network errors and consider token invalid
      print('Error checking token: $e');
      await prefs.remove('auth_token');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const Scaffold(); // The widget won't show because we handle navigation in _initializeApp.
  }
}
