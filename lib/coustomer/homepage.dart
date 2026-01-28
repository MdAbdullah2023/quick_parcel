import 'package:flutter/material.dart';
import 'package:quick_parcel/coustomer/sendPackage.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _trackingController = TextEditingController();

  String userName = 'User';
  String userType = 'Customer';
  String? profileImageUrl;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final helper = SharedpreferenceHelper();
      final name = await helper.getUserName();
      final userId = await helper.getUserId();

      if (mounted) {
        setState(() {
          userName = name ?? 'User';
        });
      }

      if (userId != null) {
        final doc = await DatabaseMethods().getUserDetail(userId);
        if (doc.exists && mounted) {
          setState(() {
            profileImageUrl = doc.data()?['PhotoUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  // profile pic
  Widget _buildProfilePicture() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _loadingProfile
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF0D7D8F)),
                  ),
                ),
              )
            : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
            ? Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 35,
                  color: Color(0xFF0D7D8F),
                ),
              )
            : const Icon(Icons.person, size: 35, color: Color(0xFF0D7D8F)),
      ),
    );
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D7D8F),
                    const Color(0xFF0D7D8F).withOpacity(0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      // profile pic
                      GestureDetector(
                        onTap: () {},
                        child: _buildProfilePicture(),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userType,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  //search track
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track your package',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your package tracking number',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F7),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: TextField(
                                  controller: _trackingController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Tracking number',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: Color(0xFF0D7D8F),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // menu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/send_package.png',
                    label: 'Send package',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SendPackage()),
                      );
                    },
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/my_package.png',
                    label: 'My package',
                    onTap: () {},
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/live_traking.png',
                    label: 'Live tracking',
                    onTap: () {},
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/billing.png',
                    label: 'Billing',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
