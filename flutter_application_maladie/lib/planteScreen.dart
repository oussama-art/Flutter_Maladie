import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import './PlantDetailsScreen.dart';

class PlantScreen extends StatefulWidget {
  final String searchQuery; // Accept search query as a parameter

  const PlantScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<PlantScreen> createState() => PlantScreenState();
}

class PlantScreenState extends State<PlantScreen> {
  List<dynamic> _plants = [];
  bool _isLoading = false;
  String _searchType = "plant"; // Default search type
  String _searchQuery = ""; // Current search query

  Future<void> _fetchPlants({String? searchQuery, String? searchType}) async {
    setState(() {
      _isLoading = true;
    });

    String baseUrl = ApiConfig.baseUrl;
    String url = "$baseUrl/api/plantes?page=0&size=10";

    // Append `search` or `maladie` based on the selected search type
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (searchType == "plant") {
        url += "&search=$searchQuery";
      } else if (searchType == "maladie") {
        url += "&maladie=$searchQuery";
      }
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _plants = data['content'] ?? [];
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

  String _formatImageUrl(String rawUrl) {
    final RegExp filenameRegex = RegExp(r'[\\/]([^\\/]+)$');
    final Match? match = filenameRegex.firstMatch(rawUrl);
    if (match != null) {
      final String filename = match.group(1) ?? '';
      return '${ApiConfig.baseUrl}/api/image/plante/$filename';
    }
    return '${ApiConfig.baseUrl}/api/image/plante/default.jpg';
  }

  @override
  void initState() {
    super.initState();
    _fetchPlants(searchQuery: widget.searchQuery, searchType: _searchType);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar and Dropdown
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
                    _fetchPlants(searchQuery: query, searchType: _searchType);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    hintText: 'Search by plant or maladie',
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
                  _fetchPlants(searchQuery: _searchQuery, searchType: _searchType);
                },
                items: const [
                  DropdownMenuItem(
                    value: "plant",
                    child: Text("Plant"),
                  ),
                  DropdownMenuItem(
                    value: "maladie",
                    child: Text("Maladie"),
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
              : _plants.isEmpty
                  ? const Center(
                      child: Text(
                        'No plants found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _plants.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Display 2 items per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        final plant = _plants[index];
                        final String formattedImageUrl = _formatImageUrl(plant['image'] ?? '');
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantDetailsScreen(plantData: plant),
                              ),
                            );
                          },
                          child: _buildPlantCard(
                              utf8.decode(plant['name'].toString().codeUnits),
                              formattedImageUrl),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(String name, String imageUrl) {
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
                name,
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
