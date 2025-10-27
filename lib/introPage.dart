import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Intropage extends StatefulWidget {
  const Intropage({super.key});

  @override
  State<Intropage> createState() => _IntropageState();
}

class _IntropageState extends State<Intropage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D7D8F),

      body: Center(
        child: Lottie.network(
          "https://lottie.host/1fa15ee0-de39-4204-b521-8596beea2086/pjxFE3sdzL.json",
        ),
      ),
    );
  }
}
