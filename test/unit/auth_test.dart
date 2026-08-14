import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/models/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('UserModel serializes and deserializes correctly', () {
      final user = UserModel(
        id: 'usr_123',
        name: 'Alex Developer',
        email: 'alex@example.com',
        isGuest: false,
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );

      final map = user.toMap();
      expect(map['id'], 'usr_123');
      expect(map['name'], 'Alex Developer');
      expect(map['email'], 'alex@example.com');
      expect(map['isGuest'], 0);

      final fromMap = UserModel.fromMap(map);
      expect(fromMap.id, user.id);
      expect(fromMap.name, user.name);
      expect(fromMap.email, user.email);
      expect(fromMap.isGuest, false);
    });

    test('UserModel guest factory creates valid guest user', () {
      final guest = UserModel.guest();
      expect(guest.isGuest, true);
      expect(guest.name, 'Guest User');
      expect(guest.email, 'guest@offline.local');
    });

    test('UserModel copyWith updates fields correctly', () {
      final user = UserModel.guest();
      final updated = user.copyWith(
        name: 'Jane Doe',
        avatarUrl: '👩‍🎨',
        bio: 'Designing the future 🎨',
        isGuest: false,
      );

      expect(updated.name, 'Jane Doe');
      expect(updated.avatarUrl, '👩‍🎨');
      expect(updated.bio, 'Designing the future 🎨');
      expect(updated.isGuest, false);
      expect(updated.id, user.id);
    });
  });
}
