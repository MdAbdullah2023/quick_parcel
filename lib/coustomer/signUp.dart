import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quick_parcel/coustomer/bottomnav.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/coustomer/billing_page.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:random_string/random_string.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/services/shared_pref.dart';

class SignUpScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final String? orderId;
  final bool isFromOffer;

  const SignUpScreen({
    super.key,
    this.orderData,
    this.orderId,
    this.isFromOffer = false,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nidController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill form with order data if coming from offer
    if (widget.isFromOffer && widget.orderData != null) {
      _nameController.text = widget.orderData!['SenderName'] ?? '';
      _phoneController.text = widget.orderData!['SenderPhone'] ?? '';
      _nidController.text = widget.orderData!['SenderNID'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nidController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please fill all fields correctly'),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please agree to the terms & policy'),
        ),
      );
      return;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final String customId = randomAlphaNumeric(10);

      final userInfoMap = {
        'Id': customId,
        'FirebaseUid': credential.user?.uid ?? '',
        'Name': _nameController.text.trim(),
        'NID': _nidController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'CreatedAt': DateTime.now().toIso8601String(),
      };

      await DatabaseMethods().addUserDetail(userInfoMap, customId);

      await SharedpreferenceHelper().saveUserId(customId);
      await SharedpreferenceHelper().saveUserName(_nameController.text.trim());
      await SharedpreferenceHelper().saveUserEmail(
        _emailController.text.trim(),
      );

      // Link guest order to user account if coming from offer.
      if (widget.isFromOffer &&
          widget.orderId != null &&
          widget.orderId!.isNotEmpty) {
        try {
          await DatabaseMethods().linkOrderToUser(
            userId: customId,
            orderId: widget.orderId!,
            fallbackOrderData: widget.orderData,
          );
        } catch (e) {
          print('Error linking order to user: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ Registration successful!'),
            duration: Duration(seconds: 2),
          ),
        );

        // If coming from an offer with order data, go to billing page
        if (widget.isFromOffer && widget.orderData != null && widget.orderId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BillingPage(
                orderId: widget.orderId,
                amount: double.tryParse(
                  widget.orderData!['Price']?.toString() ?? '0',
                ),
                customerName: _nameController.text.trim(),
                customerPhone: _phoneController.text.trim(),
                customerEmail: _emailController.text.trim(),
                isFromOffer: true,
              ),
            ),
          );
        } else {
          // Normal signup, go to BottomNav
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BottomNav()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          message = 'This email is already registered. Try logging in.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          message = 'Email/Password authentication is not enabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D7D8F),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Image.asset("images/signup.png"),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Sign up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join Quick Parcel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Faster deliveries start here',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      CustomTextField(
                        label: 'Name',
                        hint: 'Enter your name',
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your name'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // NID Number Field
                      CustomTextField(
                        label: 'NID Number',
                        hint: 'Enter your NID number',
                        prefixIcon: Icons.badge_outlined,
                        controller: _nidController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter NID number';
                          if (value.length < 10) return 'Invalid NID number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Phone Field
                      CustomTextField(
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter phone number';
                          if (value.length < 6) return 'Invalid phone number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Email Field
                      CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter email';
                          final regex = RegExp(r'^.+@.+\..+$');
                          if (!regex.hasMatch(value)) return 'Invalid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Enter password';
                          if (value.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Confirm Password Field
                      CustomTextField(
                        label: 'Re-enter password',
                        hint: 'Confirm password',
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        isPassword: true,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Confirm password';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Terms Checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) => setState(
                                () => _agreeToTerms = value ?? false,
                              ),
                              activeColor: const Color(0xFF0D7D8F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: 'terms & policy',
                                  style: const TextStyle(
                                    color: Color(0xFF0D7D8F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      //  terms screen/url
                                    },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Sign Up Button
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 1.8,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D7D8F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sign In
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Have an account? ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: AppWidget.GreenTextfeildStyle(16.0),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
