import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:quick_parcel/firebase_options.dart';
import 'package:quick_parcel/introPage.dart';
import 'package:quick_parcel/slaph_screen.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/coustomer/signup.dart';
import 'package:quick_parcel/services/app_theme.dart';
import 'package:quick_parcel/admin/admin_login.dart';

// Driver app imports (commented out)
// import 'package:quick_parcel/driver/driver_login.dart';
// import 'package:quick_parcel/driver/driver_signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quick Parcel',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      home: SplashScreen(),
      builder: (context, child) {
        return WebMobileFrameWrapper(child: child ?? const SizedBox());
      },
      routes: {
        '/intro': (context) => const Intropage(),
        // Customer app routes
        '/customer-login': (context) => const LoginScreen(),
        '/customer-signup': (context) => const SignUpScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),

        // Driver app routes (commented out)
        // '/driver-login': (context) => const DriverLoginScreen(),
        // '/driver-signup': (context) => const DriverSignUpScreen(),
      },
    );
  }
}

class WebMobileFrameWrapper extends StatelessWidget {
  final Widget child;

  const WebMobileFrameWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If on actual mobile device or browser width <= 500px, show 100% full screen
        if (constraints.maxWidth <= 500) {
          return child;
        }

        // Standard modern smartphone physical resolution (Pixel 7 / iPhone 14)
        const double phoneWidth = 400.0;
        const double phoneHeight = 844.0;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          body: SizedBox.expand(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: Container(
                    width: phoneWidth,
                    height: phoneHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(46),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 35,
                          spreadRadius: 6,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF0D7D8F,
                          ).withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Stack(
                        children: [
                          // App Content with fixed standard mobile MediaQuery
                          Positioned.fill(
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                size: const Size(
                                  phoneWidth - 16,
                                  phoneHeight - 16,
                                ),
                                padding: const EdgeInsets.only(
                                  top: 26,
                                  bottom: 12,
                                ),
                              ),
                              child: child,
                            ),
                          ),

                          // Top Camera / Speaker Notch (Dynamic Island)
                          Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 90,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E293B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F172A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom Home Indicator Bar
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 120,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
