import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/symptoms/data/models/symptom_entry_model.dart';

abstract interface class SymptomLocalDataSource {
  List<SymptomEntryModel> getSymptoms(String profileId);
  Stream<List<SymptomEntryModel>> watchSymptoms(String profileId);
  Future<void> saveSymptom(SymptomEntryModel symptom);
  Future<void> deleteSymptom(String id);
}

@LazySingleton(as: SymptomLocalDataSource)
final class SymptomLocalDataSourceImpl implements SymptomLocalDataSource {
  @visibleForTesting
  SymptomLocalDataSourceImpl(this._box);

  @factoryMethod
  static SymptomLocalDataSourceImpl create() {
    return SymptomLocalDataSourceImpl(Hive.box(HiveBoxNames.symptoms));
  }

  final Box _box;

  @override
  List<SymptomEntryModel> getSymptoms(String profileId) {
    return _allSymptoms().where((s) => s.profileId == profileId).toList();
  }

  @override
  Stream<List<SymptomEntryModel>> watchSymptoms(String profileId) async* {
    yield getSymptoms(profileId);
    yield* _box.watch().map((_) => getSymptoms(profileId));
  }

  @override
  Future<void> saveSymptom(SymptomEntryModel symptom) async {
    await _box.put(symptom.id, jsonEncode(symptom.toJson()));
  }

  @override
  Future<void> deleteSymptom(String id) async {
    await _box.delete(id);
  }

  List<SymptomEntryModel> _allSymptoms() {
    return _box.values.map((raw) {
      return SymptomEntryModel.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    }).toList();
  }
}
