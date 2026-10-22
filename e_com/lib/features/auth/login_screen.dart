import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  final String role; // 'intern' or 'company'

  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _nameController = TextEditingController(); // Handles Name / Company Name
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _rememberDevice = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Validation Logic ---
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return widget.role == 'company'
          ? 'Please enter your company name'
          : 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Must be at least 2 characters long';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final trimmedEmail = value.trim().toLowerCase();

    // Standard email format check
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    // Common free/personal email domains
    final publicDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
    ];

    final domain = trimmedEmail.split('@').last;

    if (widget.role == 'company') {
      // 🏢 COMPANY VALIDATION: Must use corporate email (reject @gmail.com, etc.)
      if (publicDomains.contains(domain)) {
        return 'Companies must sign up with an official business email (e.g. name@company.com)';
      }
    } else {
      // 🎓 INTERN VALIDATION: Encouraged/Required to use personal or student email
      // If you want to require ONLY personal emails like gmail:
      if (!publicDomains.contains(domain) && !domain.endsWith('.edu') && !domain.endsWith('.ma')) {
        return 'Please use a personal email address (e.g. @gmail.com)';
      }
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'(?=.*[!@#\$&*~%^()_+\-=\[\]{};:"\\|,.<>/?])').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _navigateToHome(String role) {
    if (!mounted) return;

    // Let's print to see which route it's trying to take
    print("Navigating for role: $role");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Test Page for $role")),
          body: Center(
            child: Text("Successfully navigated as $role!"),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print("Attempting to sign up..."); // 👈 Check your debug console

        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: widget.role,
          name: _nameController.text.trim(),
        );

        print("Sign up successful! Navigating..."); // 👈 Check your debug console

        if (!mounted) return;
        _navigateToHome(widget.role);

      } catch (e) {
        print("SIGN UP ERROR: ${e.toString()}"); // 👈 Prints exact error to console

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // 👈 Ensures loading spinner stops spinning
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Top Gradient Background with Decorative Circles
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B62D2),
                  Color(0xFF36DFF1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Background Circles
          Positioned(
            top: -40,
            left: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),

          // 2. White Sheet Container with Slide Transition
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.78,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Arrow / Triangle Icon & Title Row
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Transform.rotate(
                                  angle: 1.5708, // Facing down
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Color(0xFF4A69E9),
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              widget.role == 'company' ? 'Company Sign Up' : 'Get Started',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A69E9),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Dynamic Name / Company Name Field
                        _buildCustomTextField(
                          controller: _nameController,
                          hintText: widget.role == 'company' ? 'Company Name' : 'Full Name',
                          validator: _validateName,
                        ),

                        const SizedBox(height: 16),

                        // Email Field
                        _buildCustomTextField(
                          controller: _emailController,
                          hintText: widget.role == 'company' ? 'Company Email' : 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        _buildCustomTextField(
                          controller: _passwordController,
                          hintText: 'password',
                          obscureText: !_isPasswordVisible,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confirm Password Field
                        _buildCustomTextField(
                          controller: _confirmPasswordController,
                          hintText: 'confirm password',
                          obscureText: !_isPasswordVisible,
                          validator: _validateConfirmPassword,
                        ),

                        const SizedBox(height: 16),

                        // Remember Device Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberDevice,
                                activeColor: const Color(0xFF2764E7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberDevice = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'remember this device',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A69E9),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Text(
                              'Sign up',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(role: widget.role),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2764E7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD9D9D9).withValues(alpha: 0.8),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFC1B5B5),
          fontSize: 15,
          fontWeight: FontWeight.w300,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}