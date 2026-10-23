import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  int _selectedTab = 0; // 0 = Profiles (Interns), 1 = Other Companies
  int _currentIndex = 0;
  String companyName = "Company";

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
  }

  // Safely fetch company name without blocking screen rendering
  Future<void> _fetchCompanyData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get()
            .timeout(const Duration(seconds: 4));

        if (doc.exists && mounted) {
          setState(() {
            companyName = doc.get('name') ?? 'Company';
          });
        }
      } catch (e) {
        // Fallback silently if network is slow
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
              // 1. Top Bar (Filter, Bookmark, Company Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list_rounded, size: 28, color: Colors.black87),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border_rounded, size: 26, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      // Company Avatar Circle
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF4A69E9),
                        child: Text(
                          companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Tab Switcher ("Profiles" vs "Other Companies")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildTabButton('Profiles', 0),
                      const SizedBox(width: 24),
                      _buildTabButton('Other Companies', 1),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
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

              const SizedBox(height: 20),

              // 3. Dynamic Grid Content based on Selected Tab
              Expanded(
                child: _selectedTab == 0 ? _buildInternsGrid() : _buildCompaniesGrid(),
              ),
            ],
          ),
        ),
      ),

      // 4. Bottom Navigation Bar
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

  // --- Stream for Interns (Tab 0) ---
  Widget _buildInternsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'intern')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No interns registered yet.',
              style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          );
        }

        final interns = snapshot.data!.docs;
        final colors = [
          const Color(0xFF8E7C81),
          const Color(0xFF8BB1A8),
          const Color(0xFF6B725B),
          const Color(0xFF9E9296),
        ];

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: interns.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final data = interns[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Intern';
            final bgColor = colors[index % colors.length];

            return _buildProfileCard(
              name: name,
              bgColor: bgColor,
              icon: Icons.person,
            );
          },
        );
      },
    );
  }

  // --- Stream for Other Companies (Tab 1) ---
  Widget _buildCompaniesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'company')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No other companies registered yet.',
              style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          );
        }

        // Filter out the currently logged-in company from the list
        final companies = snapshot.data!.docs
            .where((doc) => doc.id != currentUser?.uid)
            .toList();

        if (companies.isEmpty) {
          return const Center(
            child: Text(
              'No other companies found.',
              style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          );
        }

        final colors = [
          const Color(0xFF71829D),
          const Color(0xFFC84B4B),
          const Color(0xFF8BB1A8),
          const Color(0xFF53565A),
        ];

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: companies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final data = companies[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Company';
            final handle = data['companyHandle'] ?? '@company';
            final bgColor = colors[index % colors.length];

            return _buildProfileCard(
              name: name,
              subtitle: handle,
              bgColor: bgColor,
              icon: Icons.business,
            );
          },
        );
      },
    );
  }

  // Tab Button with Indicator
  Widget _buildTabButton(String title, int index) {
    bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  // Card Builder (Supports both intern profiles and other companies)
  Widget _buildProfileCard({
    required String name,
    String? subtitle,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar Circle
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(icon, size: 36, color: Colors.white),
            ),

            // Name / Handle Pill
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),

            // Button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4E51),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'See Profile',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Nav Builder
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