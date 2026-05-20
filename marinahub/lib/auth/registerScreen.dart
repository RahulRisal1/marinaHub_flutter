import 'package:flutter/material.dart';
import 'package:marinahub/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinahub/Dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/auth/loginScreen.dart';
import 'package:marinahub/dashboardscreen/dashboardscreen.dart';
import 'package:marinahub/adminscreens/adminsplash.dart';
import 'package:marinahub/serviceScreen/serviceScreen.dart';
import 'package:marinahub/provider/userProvider.dart';

class registerScreen extends StatefulWidget {
  const registerScreen({super.key});

  @override
  State<registerScreen> createState() => registerScreenState();
}

class registerScreenState extends State<registerScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  // static const Color goldColor = Color(0xFFC9A84C);
  // static const Color navy = Color(0xFF0D1B2A);
  // static const Color fieldColor = Color(0xFF1A2B3D);
  // static const Color textPrimary = Color(0xFF8A9BB0);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final dio = await MyDio().getDio();
      final response = await dio.post(
        "/auth/register",
        data: {
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "role": "boater",
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
        destination = const DashboardScreen();
        break;
      case "admin":
        destination = AdminSplash();
        break;
      case "service":
        destination = serviceSplash();
        break;
      default:
        destination = DashboardScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double labelSize,
    required double inputSize,
    required double verticalPad,
    required double iconSize,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textPrimary, fontSize: labelSize),
        ),
        SizedBox(height: verticalPad * 0.4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(color: Colors.white, fontSize: inputSize),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textPrimary.withOpacity(0.5),
              fontSize: inputSize - 1,
            ),
            filled: true,
            fillColor: fieldColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verticalPad,
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
              borderSide: const BorderSide(color: gold, width: 1),
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final bool isTiny = screenWidth < 320;
    final bool isSmall = screenWidth < 375;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;

    final double formWidth = isLargeTablet
        ? 500
        : (isTablet ? 460 : screenWidth);
    final double hPadding = isLargeTablet
        ? 48
        : (isTablet ? 40 : (isSmall ? screenWidth * 0.05 : screenWidth * 0.06));

    final double anchorSize = isLargeTablet
        ? 110
        : (isTablet ? 95 : (isSmall ? screenWidth * 0.18 : screenWidth * 0.20));

    final double titleSize = isLargeTablet
        ? 32
        : (isTablet ? 28 : (isTiny ? 20 : (isSmall ? 22 : 26)));
    final double subtitleSize = isLargeTablet
        ? 15
        : (isTablet ? 14 : (isSmall ? 12 : 13));
    final double labelSize = isLargeTablet
        ? 14
        : (isTablet ? 13 : (isSmall ? 11 : 12));
    final double inputSize = isLargeTablet
        ? 16
        : (isTablet ? 15 : (isSmall ? 13 : 14));
    final double verticalPad = isLargeTablet
        ? 20
        : (isTablet ? 18 : (isSmall ? 13 : 15));
    final double iconSize = isTablet ? 22 : (isSmall ? 18 : 20);
    final double buttonHeight = isLargeTablet
        ? 58
        : (isTablet ? 54 : (isSmall ? 46 : 50));
    final double buttonFontSize = isLargeTablet
        ? 17
        : (isTablet ? 16 : (isSmall ? 14 : 15));
    final double fieldSpacing = screenHeight * (isSmall ? 0.016 : 0.02);
    final double topSpacing = screenHeight * (isSmall ? 0.015 : 0.025);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: formWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topSpacing),
                      IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: iconSize - 2,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(height: topSpacing),
                      Center(
                        child: Image.asset(
                          'assets/images/anchor.png',
                          width: anchorSize,
                          height: anchorSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: topSpacing),
                      Center(
                        child: Text(
                          'Create account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Join MarineHub today',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: subtitleSize,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * (isSmall ? 0.025 : 0.035),
                      ),
                      buildTextField(
                        controller: nameController,
                        label: 'Full name',
                        hint: 'John Doe',
                        labelSize: labelSize,
                        inputSize: inputSize,
                        verticalPad: verticalPad,
                        iconSize: iconSize,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Name is required';
                          if (value.trim().length < 2)
                            return 'Name must be at least 2 characters';
                          return null;
                        },
                      ),
                      SizedBox(height: fieldSpacing),
                      buildTextField(
                        controller: emailController,
                        label: 'Email address',
                        hint: 'name@email.com',
                        labelSize: labelSize,
                        inputSize: inputSize,
                        verticalPad: verticalPad,
                        iconSize: iconSize,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Email is required';
                          if (!value.contains('@'))
                            return 'Enter a valid email';
                          return null;
                        },
                      ),
                      SizedBox(height: fieldSpacing),
                      buildTextField(
                        controller: passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        labelSize: labelSize,
                        inputSize: inputSize,
                        verticalPad: verticalPad,
                        iconSize: iconSize,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: textPrimary,
                            size: iconSize,
                          ),
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Password is required';
                          if (value.length < 4)
                            return 'Password must be at least 4 characters';
                          return null;
                        },
                      ),
                      SizedBox(height: fieldSpacing),
                      buildTextField(
                        controller: confirmPasswordController,
                        label: 'Confirm password',
                        hint: '••••••••',
                        labelSize: labelSize,
                        inputSize: inputSize,
                        verticalPad: verticalPad,
                        iconSize: iconSize,
                        obscureText: obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: textPrimary,
                            size: iconSize,
                          ),
                          onPressed: () =>
                              setState(() => obscureConfirm = !obscureConfirm),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please confirm your password';
                          if (value != passwordController.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                      SizedBox(
                        height: screenHeight * (isSmall ? 0.025 : 0.035),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            disabledBackgroundColor: gold.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: navy,
                                  ),
                                )
                              : Text(
                                  'Create account',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (isSmall ? 0.025 : 0.03)),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: subtitleSize,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: Text(
                                'Log in',
                                style: TextStyle(
                                  color: gold,
                                  fontSize: subtitleSize,
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
