import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'PlantDetailsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> articleData;

  const ArticleDetailsScreen({Key? key, required this.articleData}) : super(key: key);

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    final int articleId = widget.articleData['id'];
    final String url = '${ApiConfig.baseUrl}/api/articles/commentaire/$articleId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _comments = data['content'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch comments: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error fetching comments: $e');
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    final String comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty!')),
      );
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    final int articleId = widget.articleData['id'];
    final String url = '${ApiConfig.baseUrl}/api/articles/commentaire/$articleId';

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required. Please log in.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'commentaire': comment}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully!')),
        );
        _commentController.clear();
        _fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: ${utf8.decode(response.bodyBytes)}')),
        );
      }
    } catch (e) {
      print('Error posting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error posting comment. Please try again.')),
      );
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  String _decodeUtf8(String? text) {
    return text != null ? utf8.decode(text.codeUnits) : '';
  }

  String _fixImageUrl(String imageUrl) {
    return imageUrl.replaceFirst('http://localhost', 'http://10.0.2.2').trim();
  }

  Future<Map<String, dynamic>> _fetchPlantDetails(int plantId) async {
    String baseUrl = ApiConfig.baseUrl;
    final String url = "$baseUrl/api/plantes/$plantId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print('Error fetching plant details: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> plantIds = widget.articleData['plante'] ?? [];
    final String articleTitle = _decodeUtf8(widget.articleData['title']);
    final String articleContent = _decodeUtf8(widget.articleData['content']);
    final String articleImage = _fixImageUrl(widget.articleData['image'] ?? '');
    final String articleDate = _decodeUtf8(widget.articleData['date'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          articleTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
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
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Article Date
                  Text(
                    'Published on: $articleDate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Article Content
                  Text(
                    articleContent,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Linked Plants Section
                  const Text(
                    'Linked Plants:',
                    style: TextStyle(
                      fontSize: 20,
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
                          final String plantImage = _fixImageUrl(plant['image'] ?? '');

                          return Card(
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._comments.map((comment) => ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(
                          comment['commentaire'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          comment['date'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
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
                        onPressed: _isPostingComment ? null : _postComment,
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
