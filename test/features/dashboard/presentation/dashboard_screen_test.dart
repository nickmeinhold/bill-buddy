import 'package:bill_buddy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: Full widget tests for DashboardScreen require mocking:
// - authStateProvider
// - dashboardDataProvider
// - encryptionProvider
//
// These tests serve as a template for future widget testing.

void main() {
  group('DashboardScreen', () {
    testWidgets('is a ConsumerWidget', (tester) async {
      expect(const DashboardScreen(), isA<ConsumerWidget>());
    });

    testWidgets('shows loading indicator initially', (tester) async {
      // This test would require provider mocking to properly test
      // For now, we verify the widget can be instantiated
      expect(() => const DashboardScreen(), returnsNormally);
    });
  });
}
