import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/role_selection_screen.dart'; // Adjust path as needed

class ProfileDrawer extends StatelessWidget {
  final String userName;

  const ProfileDrawer({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75, // Takes ~75% width
      backgroundColor: const Color(0xFFCCCCCC), // Light grey background like Figma
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. Large Profile Image Avatar
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 66,
                    backgroundColor: const Color(0xFF4A69E9),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.black45, thickness: 1),
              const SizedBox(height: 16),

              // 2. Search for a setting...
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for a setting....',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. ACCOUNT INFORMATION Header
              const Text(
                'ACCOUNT INFORMATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: Colors.black38, thickness: 1),

              // 4. Settings List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDrawerItem(Icons.person_outline, 'Account'),
                    _buildDrawerItem(Icons.remove_red_eye_outlined, 'Appearance'),
                    _buildDrawerItem(Icons.lock_outline, 'Privacy and Security'),
                    _buildDrawerItem(Icons.headset_mic_outlined, 'Help and Support'),
                    _buildDrawerItem(Icons.help_outline, 'About'),
                    _buildDrawerItem(Icons.translate_outlined, 'Language'),

                    const SizedBox(height: 16),

                    // ACTIONS Header
                    const Text(
                      'ACTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(color: Colors.black38, thickness: 1),

                    // Log Out Action
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Log out',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                                (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.black87,
      ),
      onTap: () {},
    );
  }
}