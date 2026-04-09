import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  static const Color _primary = Color(0xFF0D7D8F);
  static const Color _bg = Color(0xFFF5F5F5);

  // Dummy raider info for demo; replace with real data from Firestore if available
  final String raiderName = 'Abdullah';
  final String raiderPhone = '+88017xxxxxxx';
  final String raiderEmail = 'abd@email.com';
  final LatLng startLatLng = LatLng(24.3636, 88.6241);
  final LatLng endLatLng = LatLng(24.3736, 88.6341);

  String? _userId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
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

  //  stream helpers ─

  Stream<QuerySnapshot<Map<String, dynamic>>> _parcelStream() {
    if (_userId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('Order')
        .orderBy('CreatedAt', descending: true)
        .snapshots();
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
        return const Color(0xFF10B981);
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Live Tracking',
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
                        'Active',
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
                    message: 'Please log in to view live tracking',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _parcelStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _primary),
                        );
                      }
                      if (snapshot.hasError) {
                        return _emptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'Failed to load tracking data',
                        );
                      }
                      final allDocs = snapshot.data?.docs ?? [];
                      if (allDocs.isEmpty) {
                        return _emptyState(
                          icon: Icons.inbox_outlined,
                          message:
                              'No active deliveries.\nSend a package to get started!',
                        );
                      }

                      // Show first order only for live tracking
                      final data = allDocs.first.data();
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: _trackingCard(data),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  //  tracking card ─

  Widget _trackingCard(Map<String, dynamic> data) {
    final status = data['Status'] ?? 'Pending';
    final orderId = data['OrderId'] ?? 'No Tracking ID';
    final createdAt = data['CreatedAt'] ?? '';
    final statusHistory = data['statusHistory'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _statusBg(status),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(status).withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: _statusColor(status),
                    size: 16,
                  ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildTimeline(statusHistory, status, createdAt),
          ),
        ],
      ),
    );
  }

  //  timeline

  Widget _buildTimeline(
    List<dynamic>? statusHistory,
    String status,
    String createdAt,
  ) {
    final List<Map<String, dynamic>> timeline =
        (statusHistory != null && statusHistory.isNotEmpty)
        ? statusHistory.cast<Map<String, dynamic>>()
        : [
            {'status': status, 'time': createdAt},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Tracking Updates',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(timeline.length, (i) {
            final entry = timeline[i];
            final s = (entry['status'] ?? '').toString();
            final t = entry['time'] ?? '';
            final color = _statusColor(s);

            String formattedTime = '';
            try {
              final dt = DateTime.parse(t);
              formattedTime = DateFormat('dd MMM, hh:mm a').format(dt);
            } catch (_) {
              formattedTime = t;
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i != timeline.length - 1)
                      Container(
                        width: 2,
                        height: 28,
                        color: color.withOpacity(0.2),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  //  status badge ─

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  //  empty state

  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
