import 'package:flutter_test/flutter_test.dart';

import 'package:drug/features/profiles/data/models/caregiver_profile_model.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';

void main() {
  final tProfile = CaregiverProfile(
    id: '1',
    ownerUid: 'owner-1',
    displayName: 'Self',
    relationship: Relationship.self,
    avatarUrl: 'https://example.com/avatar.png',
    color: 0xFF4CAF50,
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 20),
  );

  group('fromDomain / toDomain', () {
    test('round-trips correctly', () {
      final model = CaregiverProfileModel.fromDomain(tProfile);
      final entity = model.toDomain();

      expect(entity.id, equals(tProfile.id));
      expect(entity.ownerUid, equals(tProfile.ownerUid));
      expect(entity.displayName, equals(tProfile.displayName));
      expect(entity.relationship, equals(tProfile.relationship));
      expect(entity.avatarUrl, equals(tProfile.avatarUrl));
      expect(entity.color, equals(tProfile.color));
      expect(entity.createdAt, equals(tProfile.createdAt));
      expect(entity.updatedAt, equals(tProfile.updatedAt));
    });
  });

  group('toJson / fromJson', () {
    test('round-trips correctly', () {
      final model = CaregiverProfileModel.fromDomain(tProfile);
      final json = model.toJson();
      final deserialized = CaregiverProfileModel.fromJson(json);

      expect(deserialized.id, equals(model.id));
      expect(deserialized.ownerUid, equals(model.ownerUid));
      expect(deserialized.displayName, equals(model.displayName));
      expect(deserialized.relationship, equals(model.relationship));
      expect(deserialized.avatarUrl, equals(model.avatarUrl));
      expect(deserialized.color, equals(model.color));
      expect(deserialized.createdAt, equals(model.createdAt));
      expect(deserialized.updatedAt, equals(model.updatedAt));
    });

    test('handles null avatarUrl and color', () {
      final model = CaregiverProfileModel(
        id: '2',
        ownerUid: 'owner-2',
        displayName: 'Spouse',
        relationship: 'spouse',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final json = model.toJson();
      final deserialized = CaregiverProfileModel.fromJson(json);

      expect(deserialized.avatarUrl, isNull);
      expect(deserialized.color, isNull);
    });
  });
}
