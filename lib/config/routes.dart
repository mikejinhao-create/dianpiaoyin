import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/invoice_list/invoice_list_screen.dart';
import '../screens/invoice_detail/invoice_detail_screen.dart';
import '../screens/print_preview/print_preview_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/supabase.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // TODO: 临时开放所有页面，方便测试。正式上线前改回下面这段：
      return null;
      // final loggedIn = authState;
      // final goingToLogin = state.matchedLocation == '/login';
      // if (goingToLogin) return null;
      // if (!loggedIn) return '/login';
      // return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'invoice/:id',
                builder: (context, state) => InvoiceDetailScreen(
                  invoiceId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'print',
                builder: (context, state) {
                  final ids = state.extra as List<int>?;
                  return PrintPreviewScreen(invoiceIds: ids ?? []);
                },
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoiceListScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/invoices');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '发票',
          ),
        ],
      ),
    );
  }
}
