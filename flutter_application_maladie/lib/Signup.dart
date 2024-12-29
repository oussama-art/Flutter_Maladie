import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert'; // Add this import
import 'package:image_picker/image_picker.dart';
import 'Api_config.dart';
import 'Login.dart'; // Import the Sign In Screen
import 'package:flutter/foundation.dart'; // For kIsWeb

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _selectedFile; 
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  
  Future<void> _pickFile() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }
Future<void> _registerUser() async {
  if (_formKey.currentState!.validate()) {
    final String prenom = _prenomController.text.trim();
    final String nom = _nomController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    String baseUrl = ApiConfig.baseUrl;

    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = ApiConfig.baseUrl.replaceFirst('localhost', '10.0.2.2');
    }

    final String url = "$baseUrl/auth/register";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['prenom'] = prenom;
      request.fields['nom'] = nom;
      request.fields['email'] = email;
      request.fields['password'] = password;

      if (_selectedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedFile!.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 201) {
        
        showSuccessMessage('Registration Successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      } else if (response.statusCode == 400) {
        // Validation errors
        final validationErrors = _extractValidationErrors(responseBody);
        showErrorMessage(validationErrors);
      } else {
        // Other errors
        final errorMessage = _extractErrorMessage(responseBody) ??
            'Registration failed. Please try again.';
        showErrorMessage(errorMessage);
      }
    } catch (e) {
      // Network error
      print('Network Error: $e');
      showErrorMessage('Network Error: $e');
    }
  }
}


String _extractValidationErrors(String responseBody) {
  try {
    final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
    if (jsonResponse.containsKey('erros')) {
      final errors = jsonResponse['erros'] as Map<String, dynamic>;
      return errors.values.join('\n'); 
    }
  } catch (e) {
    print('Error parsing validation errors: $e');
  }
  return 'Validation failed. Please check your input.';
}


String? _extractErrorMessage(String responseBody) {
  try {
    final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
    return jsonResponse['message'] as String?;
  } catch (e) {
    return null; 
  }
}


void showSuccessMessage(String message) {
  _scaffoldKey.currentState?.hideCurrentSnackBar();
  _scaffoldKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}


void showErrorMessage(String message) {
  _scaffoldKey.currentState?.hideCurrentSnackBar();
  _scaffoldKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ClipPath(
                    clipper: TopImageClipper(),
                    child: Container(
                      height: 300,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('lib/assets/image2.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        CustomTextField(
                          hintText: 'First Name',
                          prefixIcon: Icons.person,
                          controller: _prenomController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hintText: 'Last Name',
                          prefixIcon: Icons.person_outline,
                          controller: _nomController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hintText: 'Email',
                          prefixIcon: Icons.email,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hintText: 'Password',
                          prefixIcon: Icons.lock,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 10),
                        // File Picker Button
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Choose File'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 100, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignInScreen()),
                                );
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false, 
      validator: widget.validator,
      decoration: InputDecoration(
        prefixIcon: Icon(widget.prefixIcon, color: Colors.green),
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.green[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Password visibility toggle
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText; 
                  });
                },
              )
            : null,
      ),
    );
  }
}


class TopImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 60,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
