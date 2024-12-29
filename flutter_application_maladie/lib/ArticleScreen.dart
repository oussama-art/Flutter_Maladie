import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import './articleDetailsScreen.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = false;

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
    });

    String baseUrl = ApiConfig.baseUrl;
    final String url = "$baseUrl/api/articles?page=0&size=10";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _articles = data['content'] ?? [];
        });
      }
    } catch (_) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Helper function to format the image URL
  String _formatImageUrl(String rawUrl) {
    final RegExp filenameRegex = RegExp(r'[\\/]([^\\/]+)$');
    final Match? match = filenameRegex.firstMatch(rawUrl);
    if (match != null) {
      final String filename = match.group(1) ?? '';
      return '${ApiConfig.baseUrl}/api/image/article/$filename';
    }
    return '${ApiConfig.baseUrl}/api/image/article/default.jpg';
  }

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _articles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Display 2 items per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7, // Decreased ratio to make the cards taller
            ),
            itemBuilder: (context, index) {
              final article = _articles[index];
              final String formattedImageUrl = _formatImageUrl(article['image'] ?? '');
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailsScreen(articleData: article),
                    ),
                  );
                },
                child: _buildArticleCard(article['title'], formattedImageUrl),
              );
            },
          );
  }

  Widget _buildArticleCard(String title, String imageUrl) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3, // Increase the flex for the image section
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 1, // Use less space for the text
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                utf8.decode(title.codeUnits),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
