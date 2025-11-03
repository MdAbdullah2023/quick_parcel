import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quick_parcel/coustomer/bottomnav.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quick_parcel/services/CustomTextField.dart';
import 'package:quick_parcel/services/widget_support.dart';
import 'package:quick_parcel/services/shared_pref.dart';
import 'package:quick_parcel/services/database.dart';
import 'package:quick_parcel/coustomer/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      final customId = await helper.getUserId();

      if (customId != null) {
        final doc = await DatabaseMethods().getUserDetail(customId);
        if (doc.exists) {
          await helper.saveUserName(doc.data()?['Name'] ?? '');
          await helper.saveUserEmail(
            doc.data()?['Email'] ?? cred.user?.email ?? '',
          );
        }
      } else {
        await helper.saveUserId(cred.user?.uid ?? '');
        await helper.saveUserEmail(cred.user?.email ?? '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Logged in successfully'),
        ),
      );

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

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email to reset password')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Password reset link sent to email.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.message ?? 'Failed to send reset email'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D7D8F),
      body: Column(
        children: [
          const SizedBox(height: 220),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: const Text(
              'Log in',
              style: TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w500,
              ),
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
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Email Field 👇
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

                      const SizedBox(height: 18),

                      // Password Field 👇
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
                          onPressed: _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width / 1.5,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signInWithEmail,
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

                      const SizedBox(height: 32),
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
                                fontSize: 18,
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

                      const SizedBox(height: 24),
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
                                  vertical: 16,
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
                                // TODO: Implement Facebook login
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
                                  vertical: 16,
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

                      const SizedBox(height: 24),
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
                                        builder: (_) => const SignUpScreen(),
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
