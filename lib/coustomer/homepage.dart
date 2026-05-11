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

  Future<Map<String, dynamic>?> _findMyOrderByTrackingNumber(
    String userId,
    String trackingNumber,
  ) async {
    final userOrderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Order');

    // First try document id lookup, because many orders use orderId as doc id.
    final byDocId = await userOrderRef.doc(trackingNumber).get();
    if (byDocId.exists) {
      return byDocId.data();
    }

    // Fallback: lookup by OrderId field.
    final byField = await userOrderRef
        .where('OrderId', isEqualTo: trackingNumber)
        .limit(1)
        .get();
    if (byField.docs.isNotEmpty) {
      return byField.docs.first.data();
    }

    return null;
  }

  Color _trackingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'in transit':
        return const Color(0xFF0D7D8F);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _trackingStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'confirmed':
        return Icons.verified_rounded;
      case 'in transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatTrackingDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _trackMyPackage() async {
    final trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tracking number'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final helper = SharedpreferenceHelper();
      final userId = await helper.getUserId();

      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to track your order'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final orderData = await _findMyOrderByTrackingNumber(
        userId,
        trackingNumber,
      );

      if (!mounted) return;

      if (orderData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No order found with this tracking number'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final orderId = (orderData['OrderId'] ?? trackingNumber).toString();
      final status = (orderData['Status'] ?? 'Pending').toString();
      final pickup = (orderData['PickupAddress'] ?? '').toString();
      final dropoff = (orderData['DropoffAddress'] ?? '').toString();
      final amount = (orderData['Price'] ?? '0').toString();
      final createdAt = (orderData['CreatedAt'] ?? '').toString();
      final statusColor = _trackingStatusColor(status);
      final statusIcon = _trackingStatusIcon(status);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D7D8F), Color(0xFF0A9BAF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          orderId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _formatTrackingDate(createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '৳ $amount',
                          style: const TextStyle(
                            color: Color(0xFF0D7D8F),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.radio_button_checked_rounded,
                              color: Color(0xFF0D7D8F),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pickup.isEmpty ? 'Pickup address not found' : pickup,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 1.6,
                              height: 20,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dropoff.isEmpty ? 'Dropoff address not found' : dropoff,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) => const LiveTrackingPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('Live Tracking'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D7D8F),
                            side: const BorderSide(color: Color(0xFF0D7D8F)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) => const MyPackagesPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.inventory_2_rounded, size: 18),
                          label: const Text('My Packages'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7D8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tracking failed: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        if (paymentStatus == 'Paid' || paymentStatus == 'CashOnDelivery') {
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
                errorBuilder: (_, _, _) => const Icon(
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
                                onPressed: _trackMyPackage,
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
