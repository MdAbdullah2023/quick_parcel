import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_parcel/coustomer/billing_page.dart';
import 'package:quick_parcel/coustomer/profile.dart';
import 'package:quick_parcel/coustomer/sendPackage.dart';
import 'package:quick_parcel/coustomer/my_packages.dart';
import 'package:quick_parcel/coustomer/live_tracking.dart';
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

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _openBillingFromHome() async {
    try {
      final helper = SharedpreferenceHelper();
      final userId = await helper.getUserId();
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view billing.')),
        );
        return;
      }

      final ordersSnapshot = await DatabaseMethods().getUserOrders(userId).first;
      final unpaidBills = <UnpaidBillItem>[];

      for (final doc in ordersSnapshot.docs) {
        final data = (doc.data() as Map<String, dynamic>?) ?? {};
        final paymentStatus = (data['PaymentStatus'] ?? '').toString();
        if (paymentStatus == 'Paid') {
          continue;
        }

        final orderId = (data['OrderId'] ?? doc.id).toString();
        final amount = _parseAmount(data['Price']);
        final senderName =
          (data['SenderName'] ?? data['ReceiverName'] ?? userName).toString();
        final senderPhone =
          (data['SenderPhone'] ?? data['ReceiverPhone'] ?? '').toString();
        final receiverName =
          (data['ReceiverName'] ?? data['SenderName'] ?? 'Receiver').toString();
        final receiverPhone =
          (data['ReceiverPhone'] ?? data['SenderPhone'] ?? '').toString();
        final pickupAddress = (data['PickupAddress'] ?? '').toString();
        final dropoffAddress = (data['DropoffAddress'] ?? '').toString();
        final packageSize = (data['PackageSize'] ?? '').toString();
        final packageDescription = (data['PackageDescription'] ?? '').toString();
        final distance = (data['Distance'] ?? '').toString();
        final estimatedTime = (data['EstimatedTime'] ?? '').toString();
        final createdAt = (data['CreatedAt'] ?? '').toString();

        unpaidBills.add(
          UnpaidBillItem(
            orderId: orderId,
            amount: amount,
          senderName: senderName,
          senderPhone: senderPhone,
          receiverName: receiverName,
          receiverPhone: receiverPhone,
          pickupAddress: pickupAddress,
          dropoffAddress: dropoffAddress,
          packageSize: packageSize,
          packageDescription: packageDescription,
          distance: distance,
          estimatedTime: estimatedTime,
          createdAt: createdAt,
          ),
        );
      }

      if (!mounted) return;

      if (unpaidBills.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No unpaid bill found.')));
        return;
      }
      final customerEmail =
          FirebaseAuth.instance.currentUser?.email ??
          'customer@quickparcel.com';

      final result = await Navigator.push<BillingResult>(
        context,
        MaterialPageRoute(
          builder: (_) => BillingPage.unpaid(
            unpaidBills: unpaidBills,
            customerEmail: customerEmail,
          ),
        ),
      );

      if (!mounted || result == null) return;
      final orderId = result.orderId;

      final updateData = {
        'PaymentStatus': result.paymentStatus,
        'PaymentMethod': result.paymentMethod,
        'PaymentProvider': result.paymentProvider,
        'PaidAmount': result.paidAmount.toStringAsFixed(0),
        'TransactionId': result.transactionId ?? '',
        'UpdatedAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('Order')
          .doc(orderId)
          .update(updateData);

      await FirebaseFirestore.instance
          .collection('Order')
          .doc(orderId)
          .update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.paymentStatus == 'Paid'
                ? 'Payment successful for bill $orderId'
                : 'Billing updated for order $orderId',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Billing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                          // refresh profile data when returning
                          _loadUserInfo();
                        },
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

                  // search track
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track Your Package',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'Enter your tracking number to get live updates',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF0D7D8F,
                                    ).withOpacity(0.15),
                                  ),
                                ),
                                child: TextField(
                                  controller: _trackingController,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'e.g. QP-2026-XXXXXX',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D7D8F),
                                    Color(0xFF0A9BAF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0D7D8F,
                                    ).withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: () {
                                  final trackingNumber = _trackingController
                                      .text
                                      .trim();
                                  if (trackingNumber.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a tracking number',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tracking feature coming soon',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
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
                    label: 'Manage Parcels',
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPackagesPage(),
                        ),
                      );
                    },
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/live_traking.png',
                    label: 'Live tracking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiveTrackingPage(),
                        ),
                      );
                    },
                  ),

                  AppWidget.HomePagebuildMenuCard(
                    imagePath: 'images/billing.png',
                    label: 'Billing',
                    onTap: _openBillingFromHome,
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
