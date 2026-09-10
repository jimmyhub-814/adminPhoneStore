import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool password = true;

  Future signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your email and password.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      if (!mounted) {
        _showErrorDialog('Failed to navigate to home page.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        default:
          errorMessage = 'An unexpected error occurred. Please try again.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đăng nhập thất bại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đã hiểu',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/img/a.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: AppColors.dark.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Admin\nApp',
                        style: AppTextstyles.headingH3.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter your email";
                            } else if (!val.contains('@') ||
                                !val.contains('.')) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                          controller: _emailController,
                          style: AppTextstyles.headingH6
                              .copyWith(color: AppColors.surface),
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: AppTextstyles.headingH6.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.8),
                            ),
                            filled: true,
                            fillColor:
                                AppColors.surface.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Please enter your password";
                            }
                            if (val.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                          controller: _passController,
                          style: AppTextstyles.headingH6
                              .copyWith(color: AppColors.surface),
                          obscureText: password,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              color: AppColors.surface.withValues(alpha: 0.7),
                              iconSize: 22,
                              icon: Icon(password
                                  ? Icons.visibility_off_outlined
                                  : Icons.remove_red_eye),
                              onPressed: () {
                                setState(
                                  () {
                                    password = !password;
                                  },
                                );
                              },
                            ),
                            hintText: "Password",
                            hintStyle: AppTextstyles.headingH6.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.8),
                            ),
                            filled: true,
                            fillColor:
                                AppColors.surface.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.surfaceLight
                                      .withValues(alpha: 0.5),
                                  blurRadius: 50,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            width: 160,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : signIn,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.surface,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Đăng nhập',
                                      style: AppTextstyles.headingH6
                                          .copyWith(color: AppColors.surface),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class LoginForm extends StatelessWidget {
  TextEditingController inputController;

  String hintText;
  String message;
  IconButton? suffix;
  Icon? prefix;
  bool? readOnly;
  bool? obscureText;
  LoginForm({
    super.key,
    required this.inputController,
    required this.hintText,
    required this.message,
    this.readOnly,
    this.suffix,
    this.prefix,
    this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          obscureText: obscureText ?? false,
          obscuringCharacter: '*',
          readOnly: readOnly ?? false,
          controller: inputController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return message;
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: prefix,
            suffixIcon: suffix,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                width: 1,
                color: Color.fromARGB(255, 135, 135, 135),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                width: 2,
                color: Color.fromARGB(255, 109, 109, 109),
              ),
            ),
            hintText: hintText,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
