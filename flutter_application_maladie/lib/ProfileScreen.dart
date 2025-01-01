import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import './Login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isEditing = false;

  File? _selectedFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Fetch the stored token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
Future<void> _fetchUserData() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  String baseUrl = ApiConfig.baseUrl;
  final String url = "$baseUrl/api/compte";

  try {
    final String? token = await _getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'No token found. Please log in.';
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Determine if `data['image']` is a full URL or just a filename
      String? imageUrl;
      if (data['image'] != null) {
        if (data['image'].startsWith('http://localhost')) {
          // Replace localhost with 10.0.2.2
          imageUrl = data['image'].replaceFirst('http://localhost', 'http://10.0.2.2');
        } else if (data['image'].startsWith('http')) {
          imageUrl = data['image']; // Use the full URL directly
        } else {
          imageUrl = "$baseUrl/api/image/user/${data['image']}"; // Construct URL
        }
        print("Image URLLLLL: $imageUrl"); // Debug: Log the image URL
      }

      setState(() {
        _userData = data;
        _nameController.text = _userData!['nom'] ?? '';
        _prenomController.text = _userData!['prenom'] ?? '';
        _emailController.text = _userData!['email'] ?? '';
        if (imageUrl != null) {
          _userData!['image_url'] = imageUrl;
        }
      });
    } else {
      setState(() {
        _errorMessage =
            'Error: ${jsonDecode(response.body)['message'] ?? 'Failed to fetch user data.'}';
      });
      await _clearTokenAndRedirect();
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Network error: $e';
    });
    await _clearTokenAndRedirect();
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}



  /// Clear token and redirect to login page
  Future<void> _clearTokenAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  /// Pick an image from the gallery
  Future<void> _pickFile() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

 Future<void> _updateUserProfile() async {
  // Validate required fields
  if (_nameController.text.trim().isEmpty ||
      _prenomController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty) {
    // Show error if any required field is empty
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in all required fields.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  String baseUrl = ApiConfig.baseUrl;
  final String url = "$baseUrl/api/user/${_userData!['id']}";

  try {
    final String? token = await _getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'No token found. Please log in.';
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
      return;
    }

    final request = http.MultipartRequest('PUT', Uri.parse(url))
      ..headers.addAll({
        'Authorization': 'Bearer $token',
      })
      ..fields['prenom'] = _prenomController.text.trim()
      ..fields['nom'] = _nameController.text.trim()
      ..fields['email'] = _emailController.text.trim()
      ..fields['role'] = _userData!['role'];

    // Only add the password field if it is not empty
    if (_passwordController.text.trim().isNotEmpty) {
      request.fields['password'] = _passwordController.text.trim();
    }

    // Add the image file only if it's selected
    if (_selectedFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      setState(() {
        _fetchUserData();
        _isEditing = false;
        _selectedFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Error: $responseBody (${response.statusCode})';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Network error: $e';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}



  /// Logout process
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    String baseUrl = ApiConfig.baseUrl;
    final String url = "$baseUrl/api/auth/logout";

    try {
      final String? token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No token found. Please log in.';
        });
        return;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token'); // Remove the token from storage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        ); // Navigate to SignInScreen
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.reasonPhrase} (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Disable default back button
      title: const Text(
        'Profile',
        style: TextStyle(color: Colors.black),
      ),
      centerTitle: true,
    ),
    backgroundColor: Colors.white,
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            : _userData != null
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isEditing ? _pickFile : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.green,
                                  backgroundImage: _selectedFile != null
                                      ? FileImage(_selectedFile!)
                                      : (_userData != null &&
                                              _userData!['image_url'] != null
                                          ? NetworkImage(
                                              _userData!['image_url'])
                                          : const AssetImage(
                                              'assets/default_avatar.png')
                                              as ImageProvider),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: _pickFile,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        padding: const EdgeInsets.all(5),
                                        child: const Icon(Icons.camera_alt,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildEditableTextField(
                            label: "Name",
                            controller: _nameController,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildEditableTextField(
                            label: "Prenom",
                            controller: _prenomController,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          // Role Field (Non-editable)
                          _buildTextField(
                            label: "Role",
                            value: _userData!['role'] ?? 'Not available',
                          ),
                          const SizedBox(height: 20),
                          _buildEditableTextField(
                            label: "Email",
                            controller: _emailController,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          if (_isEditing)
                            _buildEditableTextField(
                              label: "Password",
                              controller: _passwordController,
                              isEditing: true,
                              isPassword: true,
                            ),
                          const SizedBox(height: 30),
                          Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    Flexible(
  child: ElevatedButton.icon(
    onPressed: () {
      // Validation check for required fields
      if (_nameController.text.trim().isEmpty ||
          _prenomController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        // Show error if any required field is empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Do not proceed further
      }

      // If validation passes, save the profile
      if (_isEditing) {
        _updateUserProfile();
      } else {
        setState(() {
          _isEditing = true;
        });
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    icon: const Icon(
      Icons.edit,
      color: Colors.white,
    ),
    label: Text(
      _isEditing ? 'Save' : 'Edit Profile',
      style: const TextStyle(color: Colors.white),
    ),
  ),
),

    if (_isEditing)
      const SizedBox(width: 10), // Add spacing between buttons
    if (_isEditing)
      Flexible(
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isEditing = false;
              _selectedFile = null;
              _nameController.text = _userData!['nom'] ?? '';
              _prenomController.text = _userData!['prenom'] ?? '';
              _emailController.text = _userData!['email'] ?? '';
              _passwordController.clear();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(
            Icons.cancel,
            color: Colors.white,
          ),
          label: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    const SizedBox(width: 10), // Add spacing between buttons
    Flexible(
      child: ElevatedButton.icon(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          Icons.logout,
          color: Colors.white,
        ),
        label: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  ],
),

                        ],
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'No user data available',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
  );
}

Widget _buildEditableTextField({
  required String label,
  required TextEditingController controller,
  required bool isEditing,
  bool isPassword = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        readOnly: !isEditing,
        obscureText: isPassword,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}

Widget _buildTextField({
  required String label,
  required String value,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      ),
      const SizedBox(height: 5),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    ],
  );
}

}
