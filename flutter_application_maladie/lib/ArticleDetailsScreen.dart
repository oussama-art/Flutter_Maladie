import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './PlantDetailsScreen.dart';
import 'api_config.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> articleData;

  const ArticleDetailsScreen({Key? key, required this.articleData}) : super(key: key);

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<String> _comments = []; // Simulated list of comments for demonstration

  Future<Map<String, dynamic>> _fetchPlantDetails(int plantId) async {
    String baseUrl = ApiConfig.baseUrl;
    final String url = "$baseUrl/api/plantes/$plantId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {
      // Handle error
    }
    return {};
  }

  String _decodeUtf8(String? text) {
    return text != null ? utf8.decode(text.codeUnits) : '';
  }

  String _formatImageUrl(String rawUrl) {
    final RegExp filenameRegex = RegExp(r'[\\/]([^\\/]+)$');
    final Match? match = filenameRegex.firstMatch(rawUrl);
    if (match != null) {
      final String filename = match.group(1) ?? '';
      return '${ApiConfig.baseUrl}/api/image/plante/$filename';
    }
    return '${ApiConfig.baseUrl}/api/image/plante/default.jpg';
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add(_commentController.text);
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> plantIds = widget.articleData['plante'] ?? [];
    final String articleTitle = _decodeUtf8(widget.articleData['title']);
    final String articleContent = _decodeUtf8(widget.articleData['content']);
    final String articleImage = _formatImageUrl(widget.articleData['image'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          articleTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white, // Ensures the entire screen has a white background
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Image
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        articleImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Article Title
                  Text(
                    articleTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Article Content
                  Text(
                    articleContent,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Linked Plants Section
                  const Text(
                    'Linked Plants:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...plantIds.map((plantId) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchPlantDetails(plantId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError || snapshot.data == null) {
                          return const Text(
                            'Error loading plant details',
                            style: TextStyle(color: Colors.red),
                          );
                        } else {
                          final plant = snapshot.data!;
                          final String plantName = _decodeUtf8(plant['name']);
                          final String plantImage = _formatImageUrl(plant['image'] ?? '');

                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white, // Ensure the card has a white background
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  plantImage,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                                  },
                                ),
                              ),
                              title: Text(
                                plantName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward, color: Colors.green),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlantDetailsScreen(plantData: plant),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Comments Section
                  const Text(
                    'Comments:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._comments.map((comment) => ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(comment),
                      )),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addComment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Post'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
