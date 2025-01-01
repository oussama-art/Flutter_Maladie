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
  String _searchType = "search"; // Default search type is by article
  String _searchQuery = ""; // Current search query

  Future<void> _fetchArticles({String? searchQuery, String? searchType}) async {
    setState(() {
      _isLoading = true;
    });

    String baseUrl = ApiConfig.baseUrl;
    String url = "$baseUrl/api/articles?page=0&size=10";

    // Append the appropriate query parameter based on the search type
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (searchType == "search") {
        url += "&search=$searchQuery";
      } else if (searchType == "plante") {
        url += "&plante=$searchQuery";
      }
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _articles = data['content'] ?? [];
        });
      }
    } catch (_) {
      // Handle errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchArticles(); // Initial fetch with no search
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar with Dropdown
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _fetchArticles(searchQuery: query, searchType: _searchType);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    hintText: 'Search by article or plant',
                    filled: true,
                    fillColor: Colors.green[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _searchType,
                onChanged: (value) {
                  setState(() {
                    _searchType = value!;
                  });
                  _fetchArticles(searchQuery: _searchQuery, searchType: _searchType);
                },
                items: const [
                  DropdownMenuItem(
                    value: "search",
                    child: Text("Article"),
                  ),
                  DropdownMenuItem(
                    value: "plante",
                    child: Text("Plant"),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                )
              : _articles.isEmpty
                  ? const Center(
                      child: Text(
                        'No articles found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _articles.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Display 2 items per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
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
                          child: _buildArticleCard(
                              utf8.decode(article['title'].toString().codeUnits),
                              formattedImageUrl),
                        );
                      },
                    ),
        ),
      ],
    );
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
            flex: 3,
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
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                title,
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
