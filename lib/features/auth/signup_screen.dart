import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // Top Gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkGreen, Color(0xFF081C15)],
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(80),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join FarmNex',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start sourcing premium tractor parts today.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Signup Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (authState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Text(
                              authState.error!,
                              style: GoogleFonts.outfit(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _buildFieldHeader('FULL NAME'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Enter your name',
                          icon: Icons.person_outline,
                        ),
                        
                        const SizedBox(height: 20),
                        _buildFieldHeader('EMAIL ADDRESS'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'e.g. john@example.com',
                          icon: Icons.email_outlined,
                          onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                        ),
                        
                        const SizedBox(height: 20),
                        _buildFieldHeader('PASSWORD'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                          obscureText: !_isPasswordVisible,
                          style: GoogleFonts.outfit(color: AppColors.black),
                          decoration: InputDecoration(
                            hintText: 'Minimum 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.metallicGray,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            filled: true,
                            fillColor: AppColors.scaffoldBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Signup Button
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : () async {
                              final name = _nameController.text.trim();
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              
                              // Clear previous errors
                              ref.read(authProvider.notifier).clearError();

                              if (name.isEmpty) {
                                _showError(context, 'Please enter your full name');
                                return;
                              }
                              
                              if (email.isEmpty) {
                                _showError(context, 'Please enter your email address');
                                return;
                              }

                              // Email Validation
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(email)) {
                                _showError(context, 'Please enter a valid email address');
                                return;
                              }

                              if (password.isEmpty) {
                                _showError(context, 'Please create a password');
                                return;
                              }

                              if (password.length < 6) {
                                _showError(context, 'Password must be at least 6 characters');
                                return;
                              }
                              
                              final success = await ref.read(authProvider.notifier).signup(
                                name,
                                email,
                                password,
                                'buyer',
                              );
                              
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Welcome to FarmNex! Account created successfully.'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                if (mounted) context.go('/profile');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkGreen,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            child: authState.isLoading 
                              ? const CircularProgressIndicator(color: AppColors.white)
                              : Text(
                                  'CREATE ACCOUNT',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(color: AppColors.metallicGray),
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: 'Sign In',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFieldHeader(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.darkGreen,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.outfit(color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.darkGreen),
        filled: true,
        fillColor: AppColors.scaffoldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
