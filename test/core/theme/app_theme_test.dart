import 'package:bill_buddy/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    group('custom colors', () {
      test('incomeColor is green (success color)', () {
        expect(AppTheme.incomeColor, isA<Color>());
        expect(AppTheme.incomeColor, equals(const Color(0xFF388E3C)));
      });

      test('expenseColor is red (error color)', () {
        expect(AppTheme.expenseColor, isA<Color>());
        expect(AppTheme.expenseColor, equals(const Color(0xFFD32F2F)));
      });

      test('warningColor is orange', () {
        expect(AppTheme.warningColor, isA<Color>());
        expect(AppTheme.warningColor, equals(const Color(0xFFF57C00)));
      });

      test('subscriptionColor is purple', () {
        expect(AppTheme.subscriptionColor, isA<Color>());
        expect(AppTheme.subscriptionColor, equals(const Color(0xFF7B1FA2)));
      });

      test('billColor is deep orange', () {
        expect(AppTheme.billColor, isA<Color>());
        expect(AppTheme.billColor, equals(const Color(0xFFE65100)));
      });

      test('all custom colors are different', () {
        final colors = {
          AppTheme.incomeColor,
          AppTheme.expenseColor,
          AppTheme.warningColor,
          AppTheme.subscriptionColor,
          AppTheme.billColor,
        };
        expect(colors.length, equals(5), reason: 'All colors should be unique');
      });
    });

    // Note: Theme generation tests are skipped because GoogleFonts
    // requires Flutter bindings and makes network calls which are
    // difficult to mock in unit tests. The themes are covered by
    // integration/widget tests instead.
  });
}
