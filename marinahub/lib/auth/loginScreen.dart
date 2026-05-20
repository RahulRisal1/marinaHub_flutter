import 'package:flutter/material.dart';
import 'package:marinahub/auth/registerScreen.dart';
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
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool isLoading = false;

  static const Color goldColor = Color(0xFFC9A84C);
  static const Color bgColor = Color(0xFF0D1B2A);
  static const Color fieldColor = Color(0xFF1A2B3D);
  static const Color subtleText = Color(0xFF8A9BB0);

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
      if (mounted) setState(() => isLoading = false);
    }
  }

  void navigateBasedOnRole() {
    final role = context.read<UserProvider>().userData?["role"];
    Widget destination;
    switch (role) {
      case "boater":
        destination = DashboardScreen();
        break;
      case "admin":
        destination = AdminSplash();
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

  Widget buildTextField({
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;

    final double formWidth = isLargeTablet
        ? 500
        : (isTablet ? 460 : screenWidth);
    final double anchorSize = isLargeTablet
        ? 120
        : (isTablet ? 100 : screenWidth * 0.22);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: formWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 48 : screenWidth * 0.06,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Center(
                        child: Image.asset(
                          'assets/images/anchor.png',
                          width: anchorSize,
                          height: anchorSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Center(
                        child: Text(
                          'Welcome back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isLargeTablet ? 34 : (isTablet ? 30 : 28),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Log in to your account',
                          style: TextStyle(
                            color: subtleText,
                            fontSize: isTablet ? 15 : 14,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      const Text(
                        'Email address',
                        style: TextStyle(color: subtleText, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      buildTextField(
                        controller: emailController,
                        hint: 'name@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Email is required';
                          if (!value.contains('@'))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      const Text(
                        'Password',
                        style: TextStyle(color: subtleText, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      buildTextField(
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
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Password is required';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
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
                      SizedBox(height: screenHeight * 0.025),
                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 58 : 54,
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
                              : Text(
                                  'Log in',
                                  style: TextStyle(
                                    color: bgColor,
                                    fontSize: isTablet ? 17 : 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
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
                      SizedBox(height: screenHeight * 0.03),
                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 58 : 54,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Image.network(
                            'https://www.google.com/favicon.ico',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                            ),
                          ),
                          label: Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 15 : 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: subtleText.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: subtleText,
                                fontSize: isTablet ? 15 : 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => registerScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  color: goldColor,
                                  fontSize: isTablet ? 15 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
