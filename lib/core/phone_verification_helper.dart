import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneVerificationHelper {
  /// Checks if the user has a phone number. Returns true if present, 
  /// otherwise prompts user with modal bottom sheet and returns false.
  static bool checkPhoneAndPrompt(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    if (user == null) return false;

    if (user.hasPhone) {
      return true;
    }

    // Phone number is missing, prompt user
    showPhoneRequiredDialog(context, ref);
    return false;
  }

  static void showPhoneRequiredDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    if (user == null) return;

    final phoneController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
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
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone_locked_rounded, color: Colors.amber.shade800, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number Required',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You must add a valid phone number to post, adopt, or buy items.',
                          style: const TextStyle(color: ShelPetTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. +8801700000000',
                  prefixIcon: const Icon(Icons.phone, color: ShelPetTheme.primaryAccent),
                  filled: true,
                  fillColor: ShelPetTheme.lightBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final phone = phoneController.text.trim();
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid phone number.')),
                      );
                      return;
                    }

                    setBottomSheetState(() => isLoading = true);
                    final res = await ApiService.updatePhone(user.id, phone);
                    if (res['status'] == true && res['data'] != null) {
                      final updatedUser = UserProfile.fromJson(res['data']);
                      await ref.read(userProvider.notifier).setUser(updatedUser);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phone number updated successfully! 🎉'), backgroundColor: Colors.green),
                        );
                      }
                    } else {
                      setBottomSheetState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Failed to update phone number.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShelPetTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Contact Phone'),
              content: SelectableText('Call or save: $cleanPhone'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contact Phone'),
            content: SelectableText('Call or save: $cleanPhone'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }
}
