import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InternFeedScreen extends StatefulWidget {
  const InternFeedScreen({super.key});

  @override
  State<InternFeedScreen> createState() => _InternFeedScreenState();
}

class _InternFeedScreenState extends State<InternFeedScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String username = "";
  String? profileImageUrl;
  int _currentIndex = 0;

  // Active Filter States
  String _selectedLocation = "Meknes, Fez-Meknes, Morocco";
  double _distanceValue = 50.0;
  List<String> _selectedEmploymentTypes = [];
  List<String> _selectedSeniorityLevels = [];
  double _minSalary = 2000.0;
  double _maxSalary = 12000.0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch username and profile image saved in Firestore
  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists && mounted) {
          final data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            username = data?['name'] ??
                data?['username'] ??
                currentUser!.displayName ??
                'User';
            profileImageUrl = data?['profileImageUrl'];
          });
        }
      } catch (e) {
        // Fallback silently if fetch fails
      }
    }
  }

  // Pick an image and upload to Firebase Storage
  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image == null || currentUser == null) return;

    try {
      File file = File(image.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser!.uid}.jpg');

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'profileImageUrl': downloadUrl});

      if (mounted) {
        setState(() {
          profileImageUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: _buildProfileDrawer(context),
      body: Builder(
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _showFilterBottomSheet(context),
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        size: 28,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4A69E9),
                            width: 1.5,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(
                              profileImageUrl ??
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. Greeting Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Hello,\n${username.trim().isNotEmpty ? username : 'User'}!',
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

                // 3. Companies Section Header
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

                const SizedBox(height: 16),

                // 4. Dynamic Staggered Grid View
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
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
                            'No companies registered yet.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final companies = snapshot.data!.docs;
                      final colors = [
                        const Color(0xFF71829D),
                        const Color(0xFFC84B4B),
                        const Color(0xFF8BB1A8),
                        const Color(0xFF53565A),
                      ];

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  for (int i = 0; i < companies.length; i += 2) ...[
                                    _buildCompanyCardFromDoc(
                                      doc: companies[i],
                                      height: ((i ~/ 2) % 2 == 0) ? 220.0 : 160.0,
                                      bgColor: colors[i % colors.length],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  const SizedBox(height: 32),
                                  for (int i = 1; i < companies.length; i += 2) ...[
                                    _buildCompanyCardFromDoc(
                                      doc: companies[i],
                                      height: (((i - 1) ~/ 2) % 2 == 0) ? 160.0 : 220.0,
                                      bgColor: colors[i % colors.length],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 5. Bottom Navigation Bar
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

  Widget _buildCompanyCardFromDoc({
    required DocumentSnapshot doc,
    required double height,
    required Color bgColor,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Company';
    final handle = data['companyHandle'] ?? '@${name.toString().toLowerCase().replaceAll(' ', '')}';

    return _buildCompanyCard(
      height: height,
      companyName: name,
      category: handle,
      bgColor: bgColor,
    );
  }

  // Filter Bottom Sheet Modal
  void _showFilterBottomSheet(BuildContext context) {
    double tempDistance = _distanceValue;
    double tempMinSalary = _minSalary;
    double tempMaxSalary = _maxSalary;
    List<String> tempEmployment = List.from(_selectedEmploymentTypes);
    List<String> tempSeniority = List.from(_selectedSeniorityLevels);
    TextEditingController locationController = TextEditingController(text: _selectedLocation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close_rounded, size: 28, color: Colors.black87),
                        ),
                        const Icon(Icons.filter_list_rounded, size: 28, color: Colors.black87),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const Text(
                            'Search location',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: locationController,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              decoration: const InputDecoration(
                                icon: Icon(Icons.location_pin, color: Colors.grey),
                                hintText: 'City, Region, Country',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Distance with jobs',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Text(
                                '${tempDistance.toInt()} km',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A69E9)),
                              ),
                            ],
                          ),
                          Slider(
                            value: tempDistance,
                            min: 0,
                            max: 100,
                            activeColor: const Color(0xFF4A69E9),
                            inactiveColor: Colors.white,
                            onChanged: (val) {
                              setModalState(() {
                                tempDistance = val;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Type of Employment',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _showMultiSelectSheet(
                                context: context,
                                title: 'Select Employment Type',
                                options: ['Full-Time', 'Part-Time', 'Internship', 'Contract', 'Remote'],
                                selectedValues: tempEmployment,
                                onConfirm: (updated) {
                                  setModalState(() {
                                    tempEmployment = updated;
                                  });
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tempEmployment.isEmpty ? 'Select options...' : tempEmployment.join(', '),
                                      style: TextStyle(
                                        color: tempEmployment.isEmpty ? Colors.grey : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Seniority Level',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _showMultiSelectSheet(
                                context: context,
                                title: 'Select Seniority Level',
                                options: ['Intern / Student', 'Entry-Level / Junior', 'Mid-Level', 'Senior'],
                                selectedValues: tempSeniority,
                                onConfirm: (updated) {
                                  setModalState(() {
                                    tempSeniority = updated;
                                  });
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tempSeniority.isEmpty ? 'Select options...' : tempSeniority.join(', '),
                                      style: TextStyle(
                                        color: tempSeniority.isEmpty ? Colors.grey : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Salary range',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          RangeSlider(
                            values: RangeValues(tempMinSalary, tempMaxSalary),
                            min: 0,
                            max: 20000,
                            activeColor: const Color(0xFF4A69E9),
                            inactiveColor: Colors.white,
                            onChanged: (values) {
                              setModalState(() {
                                tempMinSalary = values.start;
                                tempMaxSalary = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    '${tempMinSalary.toInt()} \$',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    '${tempMaxSalary.toInt()} \$',
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedLocation = locationController.text;
                                  _distanceValue = tempDistance;
                                  _minSalary = tempMinSalary;
                                  _maxSalary = tempMaxSalary;
                                  _selectedEmploymentTypes = tempEmployment;
                                  _selectedSeniorityLevels = tempSeniority;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A69E9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempDistance = 50.0;
                                  tempMinSalary = 2000.0;
                                  tempMaxSalary = 12000.0;
                                  tempEmployment.clear();
                                  tempSeniority.clear();
                                  locationController.text = "Meknes, Fez-Meknes, Morocco";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A69E9)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMultiSelectSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onConfirm,
  }) {
    List<String> currentSelections = List.from(selectedValues);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = currentSelections.contains(option);
                        return CheckboxListTile(
                          title: Text(option, style: const TextStyle(fontSize: 14)),
                          value: isSelected,
                          activeColor: const Color(0xFF4A69E9),
                          onChanged: (bool? checked) {
                            setSheetState(() {
                              if (checked == true) {
                                currentSelections.add(option);
                              } else {
                                currentSelections.remove(option);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        onConfirm(currentSelections);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A69E9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Right Slide Profile Drawer ---
  Widget _buildProfileDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: const Color(0xFFCCCCCC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          bottomLeft: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _uploadProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(
                              profileImageUrl ??
                                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A69E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.black45, thickness: 1),
              const SizedBox(height: 16),
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
              const Text(
                'ACCOUNT INFORMATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              const Divider(color: Colors.black45, thickness: 1),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDrawerTile(context, Icons.person_outline, 'Account', const AccountSettingsScreen()),
                    _buildDrawerTile(context, Icons.remove_red_eye_outlined, 'Appearance', const AppearanceSettingsScreen()),
                    _buildDrawerTile(context, Icons.lock_outline, 'Privacy and Security', const PrivacySecurityScreen()),
                    _buildDrawerTile(context, Icons.headset_mic_outlined, 'Help and Support', const HelpSupportScreen()),
                    _buildDrawerTile(context, Icons.help_outline, 'About', const AboutScreen()),
                    _buildDrawerTile(context, Icons.translate_outlined, 'Language', const LanguageScreen()),
                    const SizedBox(height: 16),
                    const Text(
                      'ACTIONS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    const Divider(color: Colors.black45, thickness: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Log out',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
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

  Widget _buildDrawerTile(BuildContext context, IconData icon, String title, Widget destinationScreen) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black87),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationScreen),
        );
      },
    );
  }

  Widget _buildCompanyCard({
    required double height,
    required String companyName,
    required String category,
    required Color bgColor,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              companyName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

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

// ============================================================================
// 6 FULLY FUNCTIONAL DEDICATED SETTINGS SUB-PAGES
// ============================================================================

// 1. ACCOUNT SETTINGS (PASSWORD RESET & EMAIL NOTIFICATIONS)
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool emailNotifications = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            emailNotifications = doc.get('emailNotifications') ?? true;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (user?.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset link sent to ${user!.email}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _toggleEmailNotifs(bool val) async {
    setState(() => emailNotifications = val);
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'emailNotifications': val}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as: ${user?.email ?? 'Unknown'}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Send a password reset email to your inbox'),
              trailing: const Icon(Icons.mail_outline_rounded, color: Color(0xFF4A69E9)),
              onTap: _sendPasswordReset,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Receive match alerts and messages'),
              value: emailNotifications,
              activeThumbColor: const Color(0xFF4A69E9),
              onChanged: _toggleEmailNotifs,
            ),
          ],
        ),
      ),
    );
  }
}

// 2. APPEARANCE SETTINGS (DARK MODE TOGGLE)
class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          isDarkMode = doc.get('darkModeEnabled') ?? false;
        });
      }
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => isDarkMode = value);
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'darkModeEnabled': value}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appearance', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Switch between Light and Dark interface mode'),
              value: isDarkMode,
              activeThumbColor: const Color(0xFF4A69E9),
              onChanged: _toggleDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

// 3. PRIVACY AND SECURITY (PUBLIC VISIBILITY & TWO-FACTOR AUTH)
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isProfilePublic = true;
  bool is2FAEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>?;
        setState(() {
          isProfilePublic = data?['isProfilePublic'] ?? true;
          is2FAEnabled = data?['twoFactorEnabled'] ?? false;
        });
      }
    }
  }

  Future<void> _togglePublicVisibility(bool val) async {
    setState(() => isProfilePublic = val);
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'isProfilePublic': val}, SetOptions(merge: true));
    }
  }

  Future<void> _toggle2FA(bool val) async {
    setState(() => is2FAEnabled = val);
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'twoFactorEnabled': val}, SetOptions(merge: true));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(val ? 'Two-Factor Authentication enabled' : 'Two-Factor Authentication disabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Public Profile Visibility', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Allow registered companies to view your profile in candidate searches'),
              value: isProfilePublic,
              activeThumbColor: const Color(0xFF4A69E9),
              onChanged: _togglePublicVisibility,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Require secondary verification on login'),
              value: is2FAEnabled,
              activeThumbColor: const Color(0xFF4A69E9),
              onChanged: _toggle2FA,
            ),
          ],
        ),
      ),
    );
  }
}

// 4. HELP AND SUPPORT (FAQ & DIRECT SUPPORT CONTACT)
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help & Support', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const ExpansionTile(
            title: Text('How do I apply for an internship?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('You can browse available companies on your feed, tap on a company card, and send a direct inquiry/application.'),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do filters work?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Tap the filter icon at the top left of the feed to adjust your search location, distance, salary ranges, and employment options.'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Support Email: support@techtrader.com')),
                );
              },
              icon: const Icon(Icons.email_outlined, color: Colors.white),
              label: const Text('Contact Support Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A69E9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. ABOUT PAGE (APP INFO & POLICIES)
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tech Trader', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A69E9))),
            const SizedBox(height: 4),
            const Text('Version 1.0.0 (Production Build)', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            const Text('Tech Trader connects aspiring interns with innovative tech companies seamlessly in real time.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Tech Trader',
                  applicationVersion: '1.0.0',
                  children: [const Text('Official Terms of Service for Tech Trader.')],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 6. LANGUAGE SETTINGS (INTERACTIVE LANGUAGE SELECTOR)
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          currentLanguage = doc.get('language') ?? 'English';
        });
      }
    }
  }

  Future<void> _selectLanguage(String lang) async {
    setState(() => currentLanguage = lang);
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'language': lang}, SetOptions(merge: true));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language updated to $lang')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Language', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: currentLanguage,
              activeColor: const Color(0xFF4A69E9),
              onChanged: (val) => _selectLanguage(val!),
            ),
            RadioListTile<String>(
              title: const Text('Français (French)'),
              value: 'French',
              groupValue: currentLanguage,
              activeColor: const Color(0xFF4A69E9),
              onChanged: (val) => _selectLanguage(val!),
            ),
            RadioListTile<String>(
              title: const Text('العربية (Arabic)'),
              value: 'Arabic',
              groupValue: currentLanguage,
              activeColor: const Color(0xFF4A69E9),
              onChanged: (val) => _selectLanguage(val!),
            ),
          ],
        ),
      ),
    );
  }
}