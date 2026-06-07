import 'package:flutter_test/flutter_test.dart';

import 'package:drug/features/auth/data/models/user_profile_model.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';

void main() {
  final tUserProfile = UserProfile(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    isAnonymous: false,
    createdAt: DateTime(2024, 1, 15),
  );

  group('fromDomain', () {
    test('creates UserProfileModel from UserProfile', () {
      final model = UserProfileModel.fromDomain(tUserProfile);

      expect(model.uid, equals('test-uid'));
      expect(model.email, equals('test@example.com'));
      expect(model.displayName, equals('Test User'));
      expect(model.photoUrl, equals('https://example.com/photo.jpg'));
      expect(model.isAnonymous, isFalse);
      expect(model.createdAt, equals(DateTime(2024, 1, 15)));
    });
  });

  group('toDomain', () {
    test('creates UserProfile from UserProfileModel', () {
      final model = UserProfileModel(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        isAnonymous: false,
        createdAt: DateTime(2024, 1, 15),
      );

      final entity = model.toDomain();

      expect(entity.uid, equals('test-uid'));
      expect(entity.email, equals('test@example.com'));
      expect(entity.displayName, equals('Test User'));
      expect(entity.photoUrl, equals('https://example.com/photo.jpg'));
      expect(entity.isAnonymous, isFalse);
      expect(entity.createdAt, equals(DateTime(2024, 1, 15)));
    });
  });

  group('toJson / fromJson', () {
    test('round-trips correctly', () {
      final model = UserProfileModel.fromDomain(tUserProfile);
      final json = model.toJson();
      final deserialized = UserProfileModel.fromJson(json);

      expect(deserialized.uid, equals(model.uid));
      expect(deserialized.email, equals(model.email));
      expect(deserialized.displayName, equals(model.displayName));
      expect(deserialized.photoUrl, equals(model.photoUrl));
      expect(deserialized.isAnonymous, equals(model.isAnonymous));
      expect(deserialized.createdAt, equals(model.createdAt));
    });

    test('handles null email and photoUrl', () {
      final model = UserProfileModel(
        uid: 'anon-uid',
        email: null,
        displayName: 'Guest',
        photoUrl: null,
        isAnonymous: true,
        createdAt: DateTime(2024),
      );

      final json = model.toJson();
      final deserialized = UserProfileModel.fromJson(json);

      expect(deserialized.uid, equals('anon-uid'));
      expect(deserialized.email, isNull);
      expect(deserialized.photoUrl, isNull);
      expect(deserialized.isAnonymous, isTrue);
    });
  });
}
