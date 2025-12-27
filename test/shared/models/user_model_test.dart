import 'package:bill_buddy/shared/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    group('serialization', () {
      test('toMap and fromMap round-trip correctly with all fields', () {
        final original = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        final map = original.toMap();
        final restored = UserModel.fromMap(map, 'user_123');

        expect(restored, equals(original));
      });

      test('handles null displayName', () {
        final user = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 15),
        );

        final map = user.toMap();
        expect(map['displayName'], isNull);

        final restored = UserModel.fromMap(map, 'user_123');
        expect(restored.displayName, isNull);
      });

      test('toMap does not include uid', () {
        final user = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 15),
        );

        final map = user.toMap();
        expect(map.containsKey('uid'), isFalse);
      });

      test('fromMap uses provided id parameter for uid', () {
        final map = {
          'email': 'test@example.com',
          'createdAt': '2024-01-15T00:00:00.000',
        };

        final user = UserModel.fromMap(map, 'provided_uid');
        expect(user.uid, equals('provided_uid'));
      });

      test('serializes createdAt as ISO8601 string', () {
        final user = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 6, 15, 14, 30, 45),
        );

        final map = user.toMap();
        expect(map['createdAt'], equals('2024-06-15T14:30:45.000'));
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final original = UserModel(
          uid: 'user_123',
          email: 'old@example.com',
          displayName: 'Old Name',
          createdAt: DateTime(2024, 1, 15),
        );

        final updated = original.copyWith(
          email: 'new@example.com',
          displayName: 'New Name',
        );

        expect(updated.email, equals('new@example.com'));
        expect(updated.displayName, equals('New Name'));
        expect(updated.uid, equals(original.uid));
        expect(updated.createdAt, equals(original.createdAt));
      });

      test('preserves unchanged fields', () {
        final original = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime(2024, 1, 15),
        );

        final updated = original.copyWith(displayName: 'Updated Name');

        expect(updated.uid, equals('user_123'));
        expect(updated.email, equals('test@example.com'));
        expect(updated.createdAt, equals(DateTime(2024, 1, 15)));
      });

      test('can update uid', () {
        final original = UserModel(
          uid: 'old_uid',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 15),
        );

        final updated = original.copyWith(uid: 'new_uid');
        expect(updated.uid, equals('new_uid'));
      });

      test('can update createdAt', () {
        final original = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          createdAt: DateTime(2024, 1, 15),
        );

        final newDate = DateTime(2024, 6, 1);
        final updated = original.copyWith(createdAt: newDate);
        expect(updated.createdAt, equals(newDate));
      });
    });

    group('equality', () {
      test('equal users are equal', () {
        final date = DateTime(2024, 1, 15);
        final user1 = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: date,
        );
        final user2 = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: date,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('different users are not equal', () {
        final date = DateTime(2024, 1, 15);
        final user1 = UserModel(
          uid: 'user_123',
          email: 'test1@example.com',
          createdAt: date,
        );
        final user2 = UserModel(
          uid: 'user_456',
          email: 'test2@example.com',
          createdAt: date,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('users with different displayName are not equal', () {
        final date = DateTime(2024, 1, 15);
        final user1 = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Name 1',
          createdAt: date,
        );
        final user2 = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Name 2',
          createdAt: date,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('user with null displayName not equal to user with displayName', () {
        final date = DateTime(2024, 1, 15);
        final user1 = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: null,
          createdAt: date,
        );
        final user2 = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Some Name',
          createdAt: date,
        );

        expect(user1, isNot(equals(user2)));
      });
    });

    group('props', () {
      test('props contains all fields', () {
        final date = DateTime(2024, 1, 15);
        final user = UserModel(
          uid: 'user_123',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: date,
        );

        expect(
          user.props,
          containsAll(['user_123', 'test@example.com', 'Test User', date]),
        );
      });
    });
  });
}
