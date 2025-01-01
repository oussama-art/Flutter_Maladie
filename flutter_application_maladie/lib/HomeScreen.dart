import 'package:flutter/material.dart';
import './planteScreen.dart' as plante; // Alias the planteScreen import
import './ArticleScreen.dart' as article; // Alias the ArticleScreen import
import './ProfileScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isPlantTab = true;
  bool _isWelcomeMessageShown = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _showWelcomeMessage();
  }

  void _showWelcomeMessage() {
    Future.delayed(Duration.zero, () {
      if (!_isWelcomeMessageShown) {
        setState(() {
          _isWelcomeMessageShown = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Welcome to the app!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Let\'s find your plants or articles'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Toggle Tabs (Plant and Article)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildToggleButton('Plant', _isPlantTab, () {
                        setState(() {
                          _isPlantTab = true;
                        });
                      }),
                      const SizedBox(width: 10),
                      _buildToggleButton('Article', !_isPlantTab, () {
                        setState(() {
                          _isPlantTab = false;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Display Content Based on Selected Tab
                  Expanded(
                    child: _isPlantTab
                        ? plante.PlantScreen( // Use the alias for PlantScreen
                            searchQuery: _searchQuery,
                          )
                        : article.ArticleScreen( // Use the alias for ArticleScreen
                           
                          ),
                  ),
                ],
              ),
            )
          : _currentIndex == 1
              ? const UserProfileScreen()
              : const Center(
                  child: Text('Profile Screen'),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: _currentIndex == 0 ? Colors.green : Colors.black,
            ),
            label: 'Home',
          ),
        
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _currentIndex == 2 ? Colors.green : Colors.black,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
