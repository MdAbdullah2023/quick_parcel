import 'package:flutter/material.dart';
import 'package:quick_parcel/driver/driver_all_orders.dart';
import 'package:quick_parcel/driver/driver_homepage.dart';
import 'package:quick_parcel/driver/driver_profile.dart';

class DriverBottomNav extends StatefulWidget {
  const DriverBottomNav({super.key});

  @override
  State<DriverBottomNav> createState() => _DriverBottomNavState();
}

class _DriverBottomNavState extends State<DriverBottomNav> {
  static const Color _primary = Color(0xFFF57C00);

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DriverHomeScreen(),
    const DriverAllOrdersPage(),
    const DriverProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.1),
              blurRadius: isDark ? 20 : 14,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 40),
                activeIcon: Icon(Icons.home, size: 40),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined, size: 40),
                activeIcon: Icon(Icons.receipt_long, size: 40),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined, size: 40),
                activeIcon: Icon(Icons.person, size: 40),
                label: 'Profile',
              ),
            ],
            selectedItemColor: _primary,
            unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
            backgroundColor: Theme.of(context).colorScheme.surface,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
