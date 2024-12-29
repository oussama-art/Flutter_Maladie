import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import './PlantDetailsScreen.dart'; // Import the PlantDetailsScreen

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => PlantScreenState();
}

class PlantScreenState extends State<PlantScreen> {
  List<dynamic> _data = [];
  bool _isLoading = false;

  Future<void> _fetchPlants() async {
    setState(() {
      _isLoading = true;
    });

    String baseUrl = ApiConfig.baseUrl;
    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = ApiConfig.baseUrl.replaceFirst('localhost', '10.0.2.2');
    }

    final String url = "$baseUrl/api/plantes";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('content')) {
          setState(() {
            _data = data['content'];
          });
        }
      }
    } catch (_) {
      // Handle errors if needed
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
    _fetchPlants(); // Fetch plants on initialization
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
            itemCount: _data.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Display 2 items per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7, // Decreased ratio to make the cards taller
            ),
            itemBuilder: (context, index) {
              final item = _data[index];
              final String formattedImageUrl = _formatImageUrl(item['image']);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailsScreen(plantData: item),
                    ),
                  );
                },
                child: _buildPlantCard(item['name'], formattedImageUrl),
              );
            },
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
                utf8.decode(name.codeUnits),
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
