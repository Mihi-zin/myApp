import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InternFeedScreen extends StatefulWidget {
  const InternFeedScreen({super.key});

  @override
  State<InternFeedScreen> createState() => _InternFeedScreenState();
}

class _InternFeedScreenState extends State<InternFeedScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String username = "";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch the username saved during sign up from Firestore
  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            username = userDoc.get('name') ?? 'User';
          });
        }
      } catch (e) {
        // Fallback if fetch fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar (Filter Icon & Profile Avatar)[cite: 2]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Icon
                  IconButton(
                    onPressed: () {
                      // TODO: Open Filter Modal
                    },
                    icon: const Icon(
                      Icons.filter_list_rounded,
                      size: 28,
                      color: Colors.black87,
                    ),
                  ),
                  // Profile Avatar
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4A69E9), width: 1.5),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100', // Placeholder profile image
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Greeting Header ("Hello, [Username]! 👋")[cite: 2]
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Hello,\n$username!',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2764E7),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    ' 👋',
                    style: TextStyle(fontSize: 28),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 3. Companies Section Header ("Companies" & "see all")[cite: 2]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Companies',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to All Companies view
                    },
                    child: const Text(
                      'see all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Staggered Grid View for Company Cards[cite: 2]
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        child: Column(
                          children: [
                            _buildCompanyCard(height: 220), // Tall card
                            const SizedBox(height: 16),
                            _buildCompanyCard(height: 160), // Short card
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Column
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 30), // Offset for stagger effect
                            _buildCompanyCard(height: 160), // Short card
                            const SizedBox(height: 16),
                            _buildCompanyCard(height: 220), // Tall card
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 5. Bottom Navigation Bar[cite: 2]
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.grid_view_rounded, 0),
            _buildNavItem(Icons.favorite_border_rounded, 1),
            _buildNavItem(Icons.chat_bubble_outline_rounded, 2),
            _buildNavItem(Icons.notifications_outlined, 3),
          ],
        ),
      ),
    );
  }

  // Widget builder for individual Company Cards[cite: 2]
  Widget _buildCompanyCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFC84B4B), // Coral/Red card background from mockup
        borderRadius: BorderRadius.circular(20),
      ),
      // Inside here you can later add company logos, titles, or descriptions
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Placeholder for card content
          ],
        ),
      ),
    );
  }

  // Widget builder for bottom navigation icons[cite: 2]
  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.black : Colors.grey,
      ),
    );
  }
}