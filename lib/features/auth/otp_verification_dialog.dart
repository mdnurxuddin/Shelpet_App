import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationDialog extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationDialog({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends ConsumerState<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit verification code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiService.verifyOtp(widget.email, otp);

    setState(() => _isLoading = false);

    if (res['status'] == true && res['data'] != null) {
      final userProfile = UserProfile.fromJson(res['data']);
      await ref.read(userProvider.notifier).setUser(userProfile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! 🎉 Welcome to ShelPet.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Invalid verification code.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    final res = await ApiService.resendOtp(widget.email);
    setState(() => _isResending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Verification code resent.'),
          backgroundColor: res['status'] == true ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ShelPetTheme.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: ShelPetTheme.primaryAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Your Email',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter the 6-digit code sent to ${widget.email}',
                      style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
              color: ShelPetTheme.primaryAccent,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '──────',
              hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey[300], fontSize: 24),
              filled: true,
              fillColor: ShelPetTheme.lightBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: ShelPetTheme.primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Proceed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _isResending ? null : _resendOtp,
              child: _isResending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      "Didn't receive code? Resend",
                      style: TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
