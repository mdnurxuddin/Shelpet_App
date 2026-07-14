import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shelpet/features/feed/post_provider.dart';
import 'package:shelpet/core/constants.dart';

class CreatePostDialog extends ConsumerStatefulWidget {
  final String defaultType;
  const CreatePostDialog({super.key, this.defaultType = 'feed'});

  @override
  ConsumerState<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<CreatePostDialog> {
  final _contentController = TextEditingController();
  final _priceController = TextEditingController();
  late String _selectedType;
  bool _isLoading = false;
  File? _image;

  String? _selectedDistrict;
  String? _selectedCity;
  List<String> _availableCities = [];

  @override
  void dispose() {
    _contentController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    
    // Default selection logic for non-verified users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      if (user?.status != 'verified' && (_selectedType == 'feed' || _selectedType == 'rescue')) {
        setState(() {
          _selectedType = 'adoption';
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write something')));
       return;
    }

    if (_selectedDistrict == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your District and City')));
      return;
    }

    setState(() => _isLoading = true);
    final user = ref.read(userProvider);
    String? imageUrl;

    if (_image != null) {
      imageUrl = await ApiService.uploadImage(_image!.path);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image. Post creation aborted.')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final location = "$_selectedCity, $_selectedDistrict";

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/posts/create_post.php"),
        body: jsonEncode({
          "user_id": user?.id,
          "content": _contentController.text,
          "type": _selectedType,
          "location": location,
          "image": imageUrl,
          "price": price,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        ref.invalidate(postsProvider);
        if (user != null) {
          ref.invalidate(userStatsProvider(user.id));
        }
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to create post')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      avatar: Icon(icon, color: isSelected ? Colors.white : ShelPetTheme.primaryAccent, size: 14),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : ShelPetTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedType = value);
      },
      selectedColor: ShelPetTheme.primaryAccent,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 16),
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create a Post', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary)),
                IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20),
                  )
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Post Category', style: TextStyle(color: ShelPetTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Consumer(builder: (context, ref, child) {
              final user = ref.watch(userProvider);
              final isVerified = user?.status == 'verified';
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isVerified) _buildTypeChip('Feed', 'feed', Icons.feed_outlined),
                  _buildTypeChip('Adoption', 'adoption', Icons.pets_outlined),
                  if (isVerified) _buildTypeChip('Rescue', 'rescue', Icons.emergency_share_outlined),
                  _buildTypeChip('Paid Fostering', 'fostering', Icons.volunteer_activism_outlined),
                ],
              );
            }),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160, 
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: Colors.grey.shade200, width: 1.5)
                ),
                child: _image != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_image!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 40, color: ShelPetTheme.primaryAccent.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text('Add photos of your pet', style: TextStyle(color: ShelPetTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Story Details', style: TextStyle(color: ShelPetTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _contentController,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 15, color: ShelPetTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(color: ShelPetTheme.textMuted, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select Location', style: TextStyle(color: ShelPetTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    hint: const Text('District', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: AppConstants.allDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDistrict = val;
                        _selectedCity = null;
                        _availableCities = AppConstants.bdDistricts[val!]!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    hint: const Text('City/Area', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: _availableCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setState(() => _selectedCity = val),
                  ),
                ),
              ],
            ),
            if (_selectedType == 'fostering') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Daily fostering rate (৳/day)",
                  filled: true, fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShelPetTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text('Share Story', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
