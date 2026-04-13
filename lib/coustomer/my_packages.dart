import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/widget_support.dart';

class MyPackagesPage extends StatefulWidget {
  const MyPackagesPage({super.key});

  @override
  State<MyPackagesPage> createState() => _MyPackagesPageState();
}

class _MyPackagesPageState extends State<MyPackagesPage>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF0D7D8F);
  static const Color _bg = Color(0xFFF5F5F5);

  String? _userId;
  bool _loadingUser = true;
  late TabController _tabController;

  final List<String> _tabs = [
    'All',
    'Pending',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = await SharedpreferenceHelper().getUserId();
    if (mounted) {
      setState(() {
        _userId = uid;
        _loadingUser = false;
      });
    }
  }

  //  status helpers ─

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'in transit':
        return _primary;
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFFBEB);
      case 'confirmed':
        return const Color(0xFFEFF6FF);
      case 'in transit':
        return const Color(0xFFE8F5F7);
      case 'delivered':
        return const Color(0xFFF0FDF4);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return Colors.grey.shade50;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'in transit':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  int _statusStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'in transit':
        return 2;
      case 'delivered':
        return 3;
      default:
        return -1;
    }
  }

  String _formatDate(String iso) {
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  //  filter orders by tab

  List<QueryDocumentSnapshot> _filteredOrders(
    List<QueryDocumentSnapshot> docs,
    int tabIndex,
  ) {
    if (tabIndex == 0) return docs;
    final filter = _tabs[tabIndex].toLowerCase();
    return docs.where((d) {
      final status = ((d.data() as Map)['Status'] ?? '')
          .toString()
          .toLowerCase();
      return status == filter;
    }).toList();
  }

  //  build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          //  Header ─
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primary.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'My Packages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      padding: EdgeInsets.zero,
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //  Body ─
          Expanded(
            child: _loadingUser
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _userId == null
                ? _emptyState(
                    icon: Icons.person_off_outlined,
                    message: 'Please log in to view your packages',
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: DatabaseMethods().getUserOrders(_userId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _primary),
                        );
                      }
                      if (snapshot.hasError) {
                        return _emptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'Failed to load orders',
                        );
                      }
                      final allDocs = snapshot.data?.docs ?? [];
                      return TabBarView(
                        controller: _tabController,
                        children: List.generate(_tabs.length, (i) {
                          final filtered = _filteredOrders(allDocs, i);
                          if (filtered.isEmpty) {
                            return _emptyState(
                              icon: Icons.inbox_outlined,
                              message: i == 0
                                  ? 'No orders yet.\nTap Manage Parcels to get started!'
                                  : 'No ${_tabs[i].toLowerCase()} orders',
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) => _orderCard(
                              filtered[idx].data() as Map<String, dynamic>,
                            ),
                          );
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  //  order card ─

  Widget _orderCard(Map<String, dynamic> data) {
    final status = data['Status'] ?? 'Pending';
    final orderId = data['OrderId'] ?? '';
    final created = data['CreatedAt'] ?? '';
    final price = data['Price'] ?? '0';
    final pickup = data['PickupAddress'] ?? '';
    final dropoff = data['DropoffAddress'] ?? '';
    final sender = data['SenderName'] ?? '';
    final receiver = data['ReceiverName'] ?? '';
    final pkgSize = data['PackageSize'] ?? '';
    final distance = data['Distance'] ?? '';
    final photoUrl = data['PackagePhoto'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          //  card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _statusBg(status),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orderId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                _statusBadge(status),
              ],
            ),
          ),

          //  package image ─
          if (photoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: MyPackagesWidgets.packageImage(photoUrl),
            ),

          //  route
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _routeRow(pickup, dropoff),
          ),

          //  details grid ─
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _detailChip(Icons.person_outline_rounded, sender),
                const SizedBox(width: 8),
                _detailChip(Icons.person_pin_outlined, receiver),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _detailChip(Icons.inventory_2_outlined, pkgSize),
                const SizedBox(width: 8),
                _detailChip(Icons.route_outlined, distance),
              ],
            ),
          ),

          //  progress tracker ─
          if (status.toLowerCase() != 'cancelled')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _progressTracker(status),
            ),

          //  footer ─
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(created),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    '৳ $price',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  route widget ─

  Widget _routeRow(String pickup, String dropoff) =>
      MyPackagesWidgets.routeRow(pickup: pickup, dropoff: dropoff);

  //  progress tracker

  Widget _progressTracker(String status) {
    final steps = ['Pending', 'Confirmed', 'In Transit', 'Delivered'];
    final currentStep = _statusStep(status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone ? _primary : Colors.grey.shade200,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isDone = stepIdx <= currentStep;
        final isCurrent = stepIdx == currentStep;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? _primary : Colors.grey.shade100,
                border: Border.all(
                  color: isDone ? _primary : Colors.grey.shade300,
                  width: isCurrent ? 2.5 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isDone ? Icons.check_rounded : _stepIcon(stepIdx),
                size: 13,
                color: isDone ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIdx],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isDone ? _primary : Colors.grey.shade400,
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _stepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.access_time_rounded;
      case 1:
        return Icons.check_circle_outline_rounded;
      case 2:
        return Icons.local_shipping_outlined;
      case 3:
        return Icons.done_all_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  //  detail chip

  Widget _detailChip(IconData icon, String label) =>
      MyPackagesWidgets.detailChip(icon: icon, label: label);

  //  status badge ─

  Widget _statusBadge(String status) => MyPackagesWidgets.statusBadge(
    status: status,
    statusColor: _statusColor(status),
  );

  //  empty state

  Widget _emptyState({required IconData icon, required String message}) =>
      MyPackagesWidgets.emptyState(icon: icon, message: message);
}
