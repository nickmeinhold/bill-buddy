import 'package:bill_buddy/shared/models/statement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatementModel', () {
    group('status getters', () {
      test('isProcessing returns true when status is processing', () {
        final statement = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.processing,
          storagePath: 'users/123/statements/statement.pdf',
        );

        expect(statement.isProcessing, isTrue);
        expect(statement.isCompleted, isFalse);
        expect(statement.isFailed, isFalse);
      });

      test('isCompleted returns true when status is completed', () {
        final statement = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.completed,
          storagePath: 'users/123/statements/statement.pdf',
          transactionCount: 25,
        );

        expect(statement.isCompleted, isTrue);
        expect(statement.isProcessing, isFalse);
        expect(statement.isFailed, isFalse);
      });

      test('isFailed returns true when status is failed', () {
        final statement = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.failed,
          storagePath: 'users/123/statements/statement.pdf',
          errorMessage: 'Failed to parse PDF',
        );

        expect(statement.isFailed, isTrue);
        expect(statement.isProcessing, isFalse);
        expect(statement.isCompleted, isFalse);
      });

      test('uploading status returns false for all getters', () {
        final statement = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.uploading,
          storagePath: 'users/123/statements/statement.pdf',
        );

        expect(statement.isProcessing, isFalse);
        expect(statement.isCompleted, isFalse);
        expect(statement.isFailed, isFalse);
      });
    });

    group('serialization', () {
      test('toMap and fromMap round-trip correctly', () {
        final original = StatementModel(
          id: '1',
          fileName: 'bank_statement_jan.pdf',
          uploadedAt: DateTime(2024, 1, 15, 10, 30),
          status: StatementStatus.completed,
          transactionCount: 42,
          storagePath: 'users/abc123/statements/bank_statement_jan.pdf',
        );

        final map = original.toMap();
        final restored = StatementModel.fromMap(map, '1');

        expect(restored, equals(original));
      });

      test('handles null optional fields', () {
        final statement = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.processing,
          storagePath: 'path/to/file.pdf',
        );

        final map = statement.toMap();
        expect(map['transactionCount'], isNull);
        expect(map['errorMessage'], isNull);

        final restored = StatementModel.fromMap(map, '1');
        expect(restored.transactionCount, isNull);
        expect(restored.errorMessage, isNull);
      });

      test('handles error message for failed status', () {
        final statement = StatementModel(
          id: '1',
          fileName: 'corrupted.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.failed,
          storagePath: 'path/to/file.pdf',
          errorMessage: 'Unsupported bank format',
        );

        final map = statement.toMap();
        final restored = StatementModel.fromMap(map, '1');

        expect(restored.errorMessage, equals('Unsupported bank format'));
        expect(restored.isFailed, isTrue);
      });

      test('defaults to processing status if unknown', () {
        final map = {
          'fileName': 'test.pdf',
          'uploadedAt': '2024-01-15T00:00:00.000',
          'status': 'unknown_status',
          'storagePath': 'path/to/file.pdf',
        };

        final statement = StatementModel.fromMap(map, '1');
        expect(statement.status, equals(StatementStatus.processing));
      });

      test('toMap includes all status types correctly', () {
        for (final status in StatementStatus.values) {
          final statement = StatementModel(
            id: '1',
            fileName: 'test.pdf',
            uploadedAt: DateTime(2024, 1, 15),
            status: status,
            storagePath: 'path/to/file.pdf',
          );

          final map = statement.toMap();
          expect(map['status'], equals(status.name));
        }
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final original = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.processing,
          storagePath: 'path/to/file.pdf',
        );

        final updated = original.copyWith(
          status: StatementStatus.completed,
          transactionCount: 15,
        );

        expect(updated.status, equals(StatementStatus.completed));
        expect(updated.transactionCount, equals(15));
        expect(updated.fileName, equals(original.fileName));
        expect(updated.storagePath, equals(original.storagePath));
      });

      test('preserves unchanged fields', () {
        final original = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: DateTime(2024, 1, 15),
          status: StatementStatus.completed,
          storagePath: 'path/to/file.pdf',
          transactionCount: 10,
        );

        final updated = original.copyWith(errorMessage: 'Some error');

        expect(updated.transactionCount, equals(10));
        expect(updated.status, equals(StatementStatus.completed));
      });

      test('can update all fields', () {
        final original = StatementModel(
          id: '1',
          fileName: 'old.pdf',
          uploadedAt: DateTime(2024, 1, 1),
          status: StatementStatus.uploading,
          storagePath: 'old/path.pdf',
        );

        final newDate = DateTime(2024, 2, 1);
        final updated = original.copyWith(
          id: '2',
          fileName: 'new.pdf',
          uploadedAt: newDate,
          status: StatementStatus.completed,
          storagePath: 'new/path.pdf',
          transactionCount: 50,
          errorMessage: null,
        );

        expect(updated.id, equals('2'));
        expect(updated.fileName, equals('new.pdf'));
        expect(updated.uploadedAt, equals(newDate));
        expect(updated.status, equals(StatementStatus.completed));
        expect(updated.storagePath, equals('new/path.pdf'));
        expect(updated.transactionCount, equals(50));
      });
    });

    group('equality', () {
      test('equal statements are equal', () {
        final date = DateTime(2024, 1, 15);
        final stmt1 = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: date,
          status: StatementStatus.completed,
          storagePath: 'path/to/file.pdf',
          transactionCount: 10,
        );
        final stmt2 = StatementModel(
          id: '1',
          fileName: 'statement.pdf',
          uploadedAt: date,
          status: StatementStatus.completed,
          storagePath: 'path/to/file.pdf',
          transactionCount: 10,
        );

        expect(stmt1, equals(stmt2));
        expect(stmt1.hashCode, equals(stmt2.hashCode));
      });

      test('different statements are not equal', () {
        final date = DateTime(2024, 1, 15);
        final stmt1 = StatementModel(
          id: '1',
          fileName: 'statement1.pdf',
          uploadedAt: date,
          status: StatementStatus.completed,
          storagePath: 'path/to/file1.pdf',
        );
        final stmt2 = StatementModel(
          id: '2',
          fileName: 'statement2.pdf',
          uploadedAt: date,
          status: StatementStatus.processing,
          storagePath: 'path/to/file2.pdf',
        );

        expect(stmt1, isNot(equals(stmt2)));
      });
    });
  });
}
