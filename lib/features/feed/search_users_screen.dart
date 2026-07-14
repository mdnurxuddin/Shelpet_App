import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:go_router/go_router.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await ApiService.searchUsers(query);
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearch,
          decoration: const InputDecoration(
            hintText: 'Search by name or category...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _searchResults.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return _buildUserTile(user);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: ShelPetTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Type to search for users' : 'No users found',
            style: const TextStyle(color: ShelPetTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => context.push('/user-profile/${user['id']}'),
        leading: CircleAvatar(
          backgroundColor: ShelPetTheme.primaryAccent.withOpacity(0.1),
          backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
          child: user['avatar'] == null 
            ? Text(user['name'][0].toUpperCase(), style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold))
            : null,
        ),
        title: Row(
          children: [
            Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            if (user['verification_status'] == 'verified') ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: ShelPetTheme.secondaryAccent, size: 14),
            ],
          ],
        ),
        subtitle: Text(user['user_category'] ?? 'Adoptor', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 14),
            Text(' ${user['rating'] ?? 5.0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: ShelPetTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
