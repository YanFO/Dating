import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/auth/login_page.dart';
import '../pages/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: MainShell(),
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),
  ],
);

extension GoRouterExtension on BuildContext {
  void goHome() => go('/');
  void goLogin() => go('/login');
}
