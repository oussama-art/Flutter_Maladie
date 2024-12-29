import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart'; // Your API configuration file

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isEditing = false; // Track whether the user is in editing mode

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  /// Fetch the stored token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Fetch user data from the API
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String baseUrl = ApiConfig.baseUrl;
    final String url = "$baseUrl/api/user";

    try {
      final String? token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No token found. Please log in.';
        });
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
        setState(() {
          _userData = data['content'][0];
          _nameController.text =
              "${_userData!['nom']} ${_userData!['prenom']}";
          _emailController.text = _userData!['email'];
        });
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

  /// Update user information
  Future<void> _updateUserProfile() async {
    if (_userData == null) return;

    // Check if there are any changes
    if (_nameController.text.trim() ==
            "${_userData!['nom']} ${_userData!['prenom']}" &&
        _emailController.text.trim() == _userData!['email']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected'),
          backgroundColor: Colors.orange,
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
        return;
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nom': _nameController.text.split(" ")[0], // First name
          'prenom': _nameController.text.split(" ").skip(1).join(" "), // Last name
          'email': _emailController.text.trim(),
          'role': _userData!['role'], // Keep the role unchanged
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _fetchUserData();
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildEditableTextField(
                              label: "Name",
                              controller: _nameController,
                              isEditing: _isEditing,
                            ),
                            const SizedBox(height: 10),
                            _buildEditableTextField(
                              label: "Email",
                              controller: _emailController,
                              isEditing: _isEditing,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              label: "Role",
                              value: _userData!['role'],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (_isEditing) {
                                      _updateUserProfile();
                                    } else {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _isEditing ? Colors.blue : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(
                                    _isEditing
                                        ? Icons.save
                                        : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _isEditing ? 'Save' : 'Edit Profile',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Handle Logout action
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Log out'),
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

  Widget _buildTextField({
    required String label,
    required String value,
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
          readOnly: true,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: value,
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

  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
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
}
