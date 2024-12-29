import 'package:flutter/material.dart';
import './planteScreen.dart'; // Import the PlantScreen
import './ArticleScreen.dart'; // Import the ArticleScreen
import './ProfileScreen.dart'; // Import the ProfileScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track the current tab
  bool _isPlantTab = true; // Default to Plant tab

  final List<Widget> _screens = [
    const PlantScreen(), // Home tab shows PlantScreen
    const ArticleScreen(), // Articles tab
    const UserProfileScreen(), // Profile tab
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Let\'s find your plants'),
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
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      hintText: 'Search',
                      filled: true,
                      fillColor: Colors.green[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
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
                        ? const PlantScreen() // Display PlantScreen
                        : const ArticleScreen(), // Display ArticleScreen
                  ),
                ],
              ),
            )
          : _screens[_currentIndex], // Display ProfileScreen if currentIndex is 2
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
              Icons.favorite,
              color: _currentIndex == 1 ? Colors.green : Colors.black,
            ),
            label: 'Favorite',
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
