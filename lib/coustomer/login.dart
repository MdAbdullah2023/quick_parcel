import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quick_parcel/coustomer/bottomnav.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quick_parcel/coustomer/forgot_password.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/coustomer/signUp.dart';
import 'package:quick_parcel/coustomer/billing_page.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  final String? orderId;
  final bool isFromOffer;

  const LoginScreen({
    super.key,
    this.orderData,
    this.orderId,
    this.isFromOffer = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    try {
      setState(() => _loading = true);

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final helper = SharedpreferenceHelper();
      final firebaseUid = cred.user?.uid ?? '';
      final email = cred.user?.email ?? _emailController.text.trim();

      String? resolvedUserDocId;
      Map<String, dynamic>? resolvedUserData;

      if (firebaseUid.isNotEmpty) {
        final byUid = await DatabaseMethods().getUserByFirebaseUid(firebaseUid);
        if (byUid.docs.isNotEmpty) {
          resolvedUserDocId = byUid.docs.first.id;
          resolvedUserData = byUid.docs.first.data();
        }
      }

      if (resolvedUserDocId == null && email.isNotEmpty) {
        final byEmail = await DatabaseMethods().getUserByEmail(email);
        if (byEmail.docs.isNotEmpty) {
          resolvedUserDocId = byEmail.docs.first.id;
          resolvedUserData = byEmail.docs.first.data();
        }
      }

      await helper.saveUserId(resolvedUserDocId ?? firebaseUid);
      await helper.saveUserEmail(resolvedUserData?['Email'] ?? email);
      await helper.saveUserName(resolvedUserData?['Name'] ?? '');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Logged in successfully'),
        ),
      );

      // If user came from offer/guest-order flow, link order to this account
      // and continue to billing instead of jumping straight to home.
      if (widget.isFromOffer &&
          widget.orderId != null &&
          widget.orderId!.isNotEmpty) {
        final currentUserId = resolvedUserDocId ?? firebaseUid;

        await DatabaseMethods().linkOrderToUser(
          userId: currentUserId,
          orderId: widget.orderId!,
          fallbackOrderData: widget.orderData,
        );

        final senderName =
            (widget.orderData?['SenderName'] ?? resolvedUserData?['Name'] ?? '')
                .toString();
        final senderPhone =
            (widget.orderData?['SenderPhone'] ?? resolvedUserData?['Phone'] ?? '')
                .toString();
        final amount = double.tryParse(
          (widget.orderData?['Price'] ?? '0').toString(),
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BillingPage(
              orderId: widget.orderId,
              amount: amount,
              customerName: senderName,
              customerPhone: senderPhone,
              customerEmail: email,
              isFromOffer: true,
            ),
          ),
        );
        return;
      }

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const BottomNav()));
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          msg = 'No user found with this email.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        case 'user-disabled':
          msg = 'This user has been disabled.';
          break;
        default:
          msg = e.message ?? msg;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _loading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);

      final helper = SharedpreferenceHelper();
      await helper.saveUserId(cred.user?.uid ?? '');
      await helper.saveUserEmail(cred.user?.email ?? '');
      await helper.saveUserName(cred.user?.displayName ?? '');

      await DatabaseMethods().addUserDetail({
        'Id': cred.user?.uid,
        'FirebaseUid': cred.user?.uid,
        'Name': cred.user?.displayName,
        'Email': cred.user?.email,
        'Phone': cred.user?.phoneNumber,
        'PhotoUrl': cred.user?.photoURL,
        'Provider': 'google',
        'UpdatedAt': DateTime.now().toIso8601String(),
      }, cred.user?.uid ?? '');

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const BottomNav()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.message ?? 'Google sign-in failed'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D7D8F),
      body: Column(
        children: [
          SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: Image.asset(
              "images/51374-removebg-preview.png",
              fit: BoxFit.contain,
            ),
          ),

          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Your Parcel are waiting',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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

                      const SizedBox(height: 15),

                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter password' : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPassword(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: AppWidget.GreenTextfeildStyle(14),
                          ),
                        ),
                      ),

                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width / 1.8,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D7D8F).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signInWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D7D8F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0, 
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
                                        'Log in',
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
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or Log in with',
                              style: TextStyle(
                                color: Color(0xFF0D7D8F),
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _signInWithGoogle,
                              icon: const FaIcon(
                                FontAwesomeIcons.google,
                                size: 20,
                                color: Color(0xFF0D7D8F),
                              ),
                              label: const Text(
                                'Google',
                                style: TextStyle(
                                  color: Color(0xFF0D7D8F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF0D7D8F,
                                  ).withOpacity(0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                //  fb login
                              },
                              icon: const FaIcon(
                                FontAwesomeIcons.facebook,
                                size: 20,
                                color: Color(0xFF0D7D8F),
                              ),
                              label: const Text(
                                'Facebook',
                                style: TextStyle(
                                  color: Color(0xFF0D7D8F),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF0D7D8F,
                                  ).withOpacity(0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Don't you have an account? ",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: AppWidget.GreenTextfeildStyle(16.0),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SignUpScreen(
                                          orderData: widget.orderData,
                                          orderId: widget.orderId,
                                          isFromOffer: widget.isFromOffer,
                                        ),
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
