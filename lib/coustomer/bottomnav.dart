import 'package:flutter/material.dart';
import 'package:quick_parcel/coustomer/homepage.dart';
import 'package:quick_parcel/coustomer/my_packages.dart';
import 'package:quick_parcel/coustomer/live_tracking.dart';
import 'package:quick_parcel/coustomer/sendPackage.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SendPackage(),
    LiveTrackingPage(),
    MyPackagesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

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
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 40),
                activeIcon: Icon(Icons.home, size: 40),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/send_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                activeIcon: Image.asset(
                  'images/send_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Send',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/live_traking.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                activeIcon: Image.asset(
                  'images/live_traking.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Tracking',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'images/my_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                activeIcon: Image.asset(
                  'images/my_package.png',
                  height: 34,
                  width: 34,
                  color: Theme.of(context).primaryColor,
                ),
                label: 'Packages',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Packages Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
