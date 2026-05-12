import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinahub/Dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/dashboardscreen/dashboardscreen.dart';
import 'package:marinahub/adminscreens/adminsplash.dart';
import 'package:marinahub/serviceScreen/serviceScreen.dart';
import 'package:marinahub/provider/userProvider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool isLoading = false;

  static const goldColor = Color(0xFFC9A84C);
  static const bgColor = Color(0xFF0D1B2A);
  static const fieldColor = Color(0xFF1A2B3D);
  static const subtleText = Color(0xFF8A9BB0);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final dio = await MyDio().getDio();
      final response = await dio.post(
        "/auth/login",
        data: {
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      final token = response.data["token"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("accessToken", token);

      if (!mounted) return;
      await context.read<UserProvider>().getUser();

      if (!mounted) return;
      navigateBasedOnRole();
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void navigateBasedOnRole() {
    final role = context.read<UserProvider>().userData?["role"];

    Widget destination;
    switch (role) {
      case "boater":
        destination = const DashboardScreen();
        break;
      case "admin":
        destination = adminSplash();
        break;
      case "service":
        destination = serviceSplash();
        break;
      default:
        destination = const DashboardScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height * 0.02),

                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),

                SizedBox(height: height * 0.04),

                Center(
                  child: Image.asset(
                    'assets/images/anchor.png',
                    width: width * 0.15,
                    height: width * 0.15,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: height * 0.025),

                const Center(
                  child: Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Log in to your account',
                    style: TextStyle(color: subtleText, fontSize: 14),
                  ),
                ),

                SizedBox(height: height * 0.05),

                const Text(
                  'Email address',
                  style: TextStyle(color: subtleText, fontSize: 13),
                ),

                const SizedBox(height: 8),

                _buildTextField(
                  controller: emailController,
                  hint: 'name@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: height * 0.025),

                const Text(
                  'Password',
                  style: TextStyle(color: subtleText, fontSize: 13),
                ),

                const SizedBox(height: 8),

                _buildTextField(
                  controller: passwordController,
                  hint: '••••••••',
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: subtleText,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: goldColor, fontSize: 13),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.025),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      disabledBackgroundColor: goldColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: bgColor,
                            ),
                          )
                        : const Text(
                            'Log in',
                            style: TextStyle(
                              color: bgColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: height * 0.03),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: subtleText.withOpacity(0.3),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: subtleText, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: subtleText.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.03),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata, color: Colors.white),
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: subtleText.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.04),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: subtleText, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: goldColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: subtleText.withOpacity(0.5), fontSize: 14),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: goldColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}
