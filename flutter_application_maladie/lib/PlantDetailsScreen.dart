import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class PlantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;

  const PlantDetailsScreen({Key? key, required this.plantData}) : super(key: key);

  @override
  _PlantDetailsScreenState createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  List<dynamic> _associatedPlants = [];
  bool _isLoadingComments = false;
  bool _isLoadingAssociations = false;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _fetchAssociatedPlants();
  }

  String _fixImageUrl(String imageUrl) {
    // Replace 'localhost' with '10.0.2.2' and trim any trailing spaces or newline characters
    return imageUrl
        .replaceFirst('http://localhost', 'http://10.0.2.2')
        .trim();
  }

  String _decodeUtf8(dynamic text) {
    if (text is String) {
      try {
        return utf8.decode(text.codeUnits);
      } catch (e) {
        return text; // Fallback to original string
      }
    }
    return text.toString();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    final int plantId = widget.plantData['id'];
    final String url = '${ApiConfig.baseUrl}/api/plantes/commentaire/$plantId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _comments = data['content'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _fetchAssociatedPlants() async {
    setState(() {
      _isLoadingAssociations = true;
    });

    final int plantId = widget.plantData['id'];
    final String url = '${ApiConfig.baseUrl}/api/plantes/$plantId/associee';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _associatedPlants = data['content'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching associated plants: $e');
    } finally {
      setState(() {
        _isLoadingAssociations = false;
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

    final int plantId = widget.plantData['id'];
    final String url = '${ApiConfig.baseUrl}/api/plantes/commentaire/$plantId';

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
        body: utf8.encode(jsonEncode({'commentaire': comment})),
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

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _fixImageUrl(widget.plantData['image']);
    final String description = _decodeUtf8(widget.plantData['description']);
    final String usage = _decodeUtf8(widget.plantData['utilisation']);
    final String precautions = _decodeUtf8(widget.plantData['precautions']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _decodeUtf8(widget.plantData['name']),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Properties, Usage, Precautions
                _buildDetailSection('Properties', description),
                const SizedBox(height: 10),
                _buildDetailSection('Usage', usage),
                const SizedBox(height: 10),
                _buildDetailSection('Precautions', precautions),
                const SizedBox(height: 20),

                // Comments Section
                const Text(
                  'Comments:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildCommentInput(),
                const SizedBox(height: 10),
                _isLoadingComments
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCommentsList(),
                const SizedBox(height: 20),

                // Recommendations Section
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _isLoadingAssociations
                    ? const Center(child: CircularProgressIndicator())
                    : _buildRecommendationsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Add a comment',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isPostingComment ? null : _postComment,
          child: const Text('Post'),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: _comments
          .map(
            (comment) => ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(_decodeUtf8(comment['name'] ?? 'Anonymous')),
              subtitle: Text(_decodeUtf8(comment['commentaire'] ?? '')),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecommendationsList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _associatedPlants.length,
        itemBuilder: (context, index) {
          final plant = _associatedPlants[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantDetailsScreen(plantData: plant),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 120,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _fixImageUrl(plant['image']),
                      height: 100,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _decodeUtf8(plant['name']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
