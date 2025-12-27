import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/encryption/encryption_provider.dart';
import '../features/auth/presentation/encryption_setup_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/recovery_codes_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/subscriptions/presentation/subscriptions_screen.dart';
import '../features/budgets/presentation/budgets_screen.dart';
import '../features/bills/presentation/bills_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/statements/presentation/statements_screen.dart';
import '../shared/widgets/main_scaffold.dart';
import '../features/auth/domain/auth_provider.dart';

/// Holds recovery codes temporarily for passing to the recovery codes screen
final pendingRecoveryCodesProvider = StateProvider<List<String>?>(
  (ref) => null,
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final pendingCodes = ref.watch(pendingRecoveryCodesProvider);
  // Only watch isUnlocked to avoid rebuilds on every encryption state change
  final isEncryptionUnlocked = ref.watch(
    encryptionProvider.select((s) => s.isUnlocked),
  );

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isRecoveryCodesRoute = state.matchedLocation == '/recovery-codes';
      final isEncryptionSetupRoute =
          state.matchedLocation == '/encryption-setup';

      debugPrint(
        'ROUTER: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, pendingCodes=${pendingCodes?.length}, encryptionUnlocked=$isEncryptionUnlocked',
      );

      // Don't redirect away from recovery codes screen
      if (isRecoveryCodesRoute) {
        debugPrint('ROUTER: On recovery codes, no redirect');
        return null;
      }

      // Don't redirect away from encryption setup screen
      if (isEncryptionSetupRoute && isLoggedIn) {
        debugPrint('ROUTER: On encryption setup, no redirect');
        return null;
      }

      // If we have pending recovery codes, go there instead of dashboard
      if (isLoggedIn && pendingCodes != null && pendingCodes.isNotEmpty) {
        debugPrint('ROUTER: Redirecting to recovery-codes');
        return '/recovery-codes';
      }

      if (!isLoggedIn && !isAuthRoute) {
        debugPrint('ROUTER: Not logged in, redirecting to login');
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        // User just logged in - always go to encryption setup first
        // The encryption setup screen will check status and redirect appropriately
        debugPrint(
          'ROUTER: Logged in on auth route, redirecting to encryption-setup',
        );
        return '/encryption-setup';
      }

      debugPrint('ROUTER: No redirect');
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/recovery-codes',
        builder: (context, state) {
          final codes = ref.read(pendingRecoveryCodesProvider) ?? [];
          return RecoveryCodesScreen(
            recoveryCodes: codes,
            onAcknowledged: () {
              ref.read(pendingRecoveryCodesProvider.notifier).state = null;
              GoRouter.of(context).go('/dashboard');
            },
          );
        },
      ),
      GoRoute(
        path: '/encryption-setup',
        builder: (context, state) => const EncryptionSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/bills',
            builder: (context, state) => const BillsScreen(),
          ),
          GoRoute(
            path: '/import',
            builder: (context, state) => const StatementsScreen(),
          ),
        ],
      ),
    ],
  );
});
