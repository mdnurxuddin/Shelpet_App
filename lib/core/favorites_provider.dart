import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favList = prefs.getStringList('favorite_posts');
    if (favList != null) {
      state = favList.map((id) => int.parse(id)).toSet();
    }
  }

  Future<void> toggleFavorite(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = Set<int>.from(state);
    if (updated.contains(postId)) {
      updated.remove(postId);
    } else {
      updated.add(postId);
    }
    state = updated;
    await prefs.setStringList('favorite_posts', updated.map((id) => id.toString()).toList());
  }

  bool isFavorite(int postId) {
    return state.contains(postId);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  return FavoritesNotifier();
});
