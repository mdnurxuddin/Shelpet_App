import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  File? _image;
  bool _isProcessing = false;
  String? _detectedName;
  String? _detectedNid;
  final _nameController = TextEditingController();
  final _nidController = TextEditingController();

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    _nameController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      print("OCR Text: $fullText");

      // More Precise NID extraction logic
      String? foundNid;
      String? foundName;

      List<String> lines = fullText.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        String lowerLine = line.toLowerCase();

        // 1. Better NID Detection (Looking for sequences near ID keywords)
        if (lowerLine.contains('id no') || lowerLine.contains('nid') || lowerLine.contains('no.')) {
           // Look for numbers in this line or the next line
           RegExp numRegex = RegExp(r'(\d\s*){10,17}');
           var match = numRegex.firstMatch(line);
           if (match != null) {
              foundNid = match.group(0)!.replaceAll(RegExp(r'\s+'), '');
           } else if (i + 1 < lines.length) {
              var nextLineMatch = numRegex.firstMatch(lines[i+1]);
              if (nextLineMatch != null) {
                 foundNid = nextLineMatch.group(0)!.replaceAll(RegExp(r'\s+'), '');
              }
           }
        }

        // 2. Name Detection (Looking for 'Name' or 'নাম' labels)
        if (lowerLine.contains('name') || lowerLine.contains('নাম')) {
           if (i + 1 < lines.length) {
              String nameLine = lines[i+1].trim();
              // Clean common OCR artifacts from name
              if (nameLine.length > 3 && !RegExp(r'^\d+$').hasMatch(nameLine)) {
                 foundName = nameLine;
              }
           }
        }
      }

      // Fallback: If no keyword match, look for any 10, 13, or 17 digit number
      if (foundNid == null) {
        RegExp fallbackRegex = RegExp(r'\b\d{10}\b|\b\d{13}\b|\b\d{17}\b');
        final match = fallbackRegex.firstMatch(fullText.replaceAll(' ', ''));
        foundNid = match?.group(0);
      }

      setState(() {
        _detectedNid = foundNid;
        _detectedName = foundName;
        if (_detectedNid != null) _nidController.text = _detectedNid!;
        if (_detectedName != null) _nameController.text = _detectedName!;
        _isProcessing = false;
      });

      if (_detectedNid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auto-detection failed. Please ensure the image is clear or type manually."))
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      print("OCR Error: $e");
    }
  }

  Future<void> _submitVerification() async {
    if (_image == null || _nidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload NID front and enter NID number"))
      );
      return;
    }

    setState(() => _isProcessing = true);
    final user = ref.read(userProvider);

    try {
      // 1. Upload NID Image
      final imageUrl = await ApiService.uploadImage(_image!.path);
      if (imageUrl == null) throw "Image upload failed";

      // 2. Submit to Backend
      final response = await ApiService.submitVerification(
        userId: user!.id,
        nidNumber: _nidController.text,
        nidImage: imageUrl,
      );

      if (response['status'] == true) {
        // Update local status to pending
        await ref.read(userProvider.notifier).refreshUser();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Success"),
              content: const Text("Your NID verification request has been submitted to Admin."),
              actions: [
                TextButton(onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }, child: const Text("OK"))
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(title: const Text("Verify Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("NID Verification", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Upload a clear photo of your NID FRONT side. Our system will try to auto-detect your info.",
              style: TextStyle(color: ShelPetTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickAndProcessImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ShelPetTheme.primaryAccent.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
                ),
                child: _image != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_image!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 64, color: ShelPetTheme.primaryAccent.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text("Upload NID Front Side", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text("Processing Image...", style: TextStyle(fontSize: 12))),
            ],
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name on NID",
                hintText: "System will detect name...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "NID Number",
                hintText: "System will detect NID...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitVerification,
                child: const Text("Submit for Verification"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
