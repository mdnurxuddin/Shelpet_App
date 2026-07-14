import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedCategory = 'Adoptor';
  final List<String> _categories = ['Adoptor', 'Adoption Giver', 'Rescuer', 'Vet Doctor'];

  Future<void> _handleAuth() async {
    if (_isLoading) return;

    if (_isLogin) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        _showError('Please fill all fields');
        return;
      }
    } else {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty || _addressController.text.isEmpty) {
        _showError('Please fill all fields');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;
      if (_isLogin) {
        response = await ApiService.login(_emailController.text.trim(), _passwordController.text);
      } else {
        response = await ApiService.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          userCategory: _selectedCategory,
          address: _addressController.text.trim(),
        );
      }

      setState(() => _isLoading = false);

      if (response['status'] == true) {
        if (response['data'] == null || response['data'] == false) {
          _showError('Invalid user data received');
          return;
        }
        final userProfile = UserProfile.fromJson(response['data']);
        await ref.read(userProvider.notifier).setUser(userProfile);
        
        if (mounted) {
          context.go('/');
        }
      } else {
        _showError(response['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Authentication error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ShelPetTheme.secondaryAccent.withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 1200),
                      child: SizedBox(
                        height: 180,
                        width: 180,
                        child: Image.asset(
                          'assets/logo.png',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.pets, size: 80, color: ShelPetTheme.primaryAccent);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? 'Welcome back' : 'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: ShelPetTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin ? 'You\'ve been missed!' : 'Join our community today.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: ShelPetTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ShelPetTheme.primaryAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: Column(
                      children: [
                        if (_isLogin) ...[
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                        ] else ...[
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            hint: 'Residential Address',
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildCategorySelector(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                        ],
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [ShelPetTheme.primaryAccent, ShelPetTheme.secondaryAccent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ShelPetTheme.primaryAccent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : Text(_isLogin ? 'Sign In' : 'Complete Registration'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: ShelPetTheme.textSecondary),
                              children: [
                                TextSpan(text: _isLogin ? 'Don\'t have an account? ' : 'Already have an account? '),
                                TextSpan(
                                  text: _isLogin ? 'Sign Up' : 'Sign In',
                                  style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Your Role', style: TextStyle(color: ShelPetTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : ShelPetTheme.textSecondary, fontSize: 12)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: ShelPetTheme.primaryAccent,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: ShelPetTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: ShelPetTheme.textMuted),
          prefixIcon: Icon(icon, color: ShelPetTheme.primaryAccent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
