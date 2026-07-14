import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/features/auth/login_screen.dart';
import 'package:shelpet/features/home/home_wrapper.dart';
import 'package:shelpet/features/chat/chat_list_screen.dart';
import 'package:shelpet/features/chat/chat_screen.dart';
import 'package:shelpet/features/profile/my_activity_screen.dart';
import 'package:shelpet/features/profile/my_favorites_screen.dart';
import 'package:shelpet/features/profile/profile_screen.dart';
import 'package:shelpet/features/admin/admin_dashboard.dart';
import 'package:shelpet/features/feed/search_users_screen.dart';
import 'package:shelpet/features/profile/verification_screen.dart';
import 'package:shelpet/features/profile/settings_screen.dart';
import 'package:shelpet/features/profile/reviews_list_screen.dart';
import 'package:shelpet/features/feed/post_details_screen.dart';
import 'package:shelpet/core/notification_service.dart';
import 'package:shelpet/features/notifications/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: ShelPetApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(userProvider);
          if (user == null) {
            return const LoginScreen();
          } else if (user.role == 'admin') {
            return const AdminDashboard();
          } else {
            return const HomeWrapper();
          }
        },
      ),
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat/:userId/:userName',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        final userName = state.pathParameters['userName']!;
        return ChatScreen(receiverId: userId, receiverName: userName);
      },
    ),
    GoRoute(
      path: '/my-activity',
      builder: (context, state) => const MyActivityScreen(),
    ),
    GoRoute(
      path: '/my-favorites',
      builder: (context, state) => const MyFavoritesScreen(),
    ),
    GoRoute(
      path: '/user-profile/:userId',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        return ProfileScreen(targetUserId: userId);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchUsersScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/verify-account',
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/user-reviews/:userId',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        final userName = state.uri.queryParameters['name'] ?? 'User';
        return ReviewsListScreen(userId: userId, userName: userName);
      },
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PostDetailsScreen(postId: id);
      },
    ),
  ],
);

class ShelPetApp extends StatelessWidget {
  const ShelPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShelPet',
      debugShowCheckedModeBanner: false,
      theme: ShelPetTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
