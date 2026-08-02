import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';

class WelcomeDashboardScreen extends StatelessWidget {
  const WelcomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), // Soft Natural Warm Neutral
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C81).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                FontAwesomeIcons.paw,
                color: Color(0xFF0F4C81),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ShelPet',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F4C81),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () => context.push('/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F4C81),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Pet care & paid fostering\nmade simple for everyone',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect with verified pet owners, rescuers, vet doctors, and foster hosts across Bangladesh.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 24),

                // FEATURE HIGHLIGHT CARD: Paid Pet Fostering
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6F0), // Organic Warm Sand/Cream
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8DFD1), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07A5F), // Warm Terracotta
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'EARN WITH SHELPET',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Text(
                            '৳300 – ৳1,500 / day',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9C4A2F),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Paid Pet Fostering Program 🐾',
                        style: GoogleFonts.outfit(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D261D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Offer temporary shelter for pets in your home while owners are away and earn money daily.',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: const Color(0xFF6E4D40),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _buildFeatureBullet(
                        title: 'Flexible Schedule',
                        desc: 'You choose when you are free to host pets and set your accepted pet types.',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureBullet(
                        title: 'Direct Payouts & Daily Rates',
                        desc: 'Charge per day or per night according to your preferences and space.',
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureBullet(
                        title: 'Verified Pet Community',
                        desc: 'In-app chat, rating system, and account verification for safe fostering.',
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context.push('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE07A5F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Become a Foster Host',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Other Features Section
                Text(
                  'Everything ShelPet Offers',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),

                _buildMinimalCard(
                  icon: FontAwesomeIcons.heart,
                  iconColor: const Color(0xFFDB2777),
                  title: 'Pet Adoption',
                  desc: 'Adopt animals or find safe, loving homes for pets in need.',
                ),
                const SizedBox(height: 10),

                _buildMinimalCard(
                  icon: FontAwesomeIcons.truckMedical,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Emergency Rescue SOS',
                  desc: 'Report stray or injured animals with location for quick rescue team alert.',
                ),
                const SizedBox(height: 10),

                _buildMinimalCard(
                  icon: FontAwesomeIcons.userDoctor,
                  iconColor: const Color(0xFF0D9488),
                  title: 'Vet Doctor Consultations',
                  desc: 'Connect with certified veterinarians for medical checkups and guidance.',
                ),
                const SizedBox(height: 10),

                _buildMinimalCard(
                  icon: FontAwesomeIcons.store,
                  iconColor: const Color(0xFF4F46E5),
                  title: 'Pet Essentials Store',
                  desc: 'Buy and sell quality pet food, accessories, and supplies directly.',
                ),

                const SizedBox(height: 28),

                // Community Trust Stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('5,000+', 'Pet Lovers'),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      _buildStatColumn('৳150K+', 'Earned by Fosters'),
                      Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                      _buildStatColumn('1,200+', 'Pets Adopted'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign In Banner
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Get Started / Sign In',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ShelPet Community',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Earn by fostering or adopt pets',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFE07A5F),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: const Color(0xFF3D261D),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF6E4D40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F4C81),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
