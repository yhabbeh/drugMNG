import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/network/network_info_impl.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity mockConnectivity;
  late NetworkInfoImpl networkInfo;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = NetworkInfoImpl(mockConnectivity);
  });

  group('isConnected', () {
    test('returns true when connectivity result is wifi', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
    });

    test('returns true when connectivity result is mobile', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
    });

    test('returns false when connectivity result is none', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await networkInfo.isConnected;

      expect(result, isFalse);
    });
  });

  group('onConnectivityChanged', () {
    test('emits true when connectivity changes to wifi', () {
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

      expect(
        networkInfo.onConnectivityChanged,
        emits(true),
      );
    });

    test('emits false when connectivity changes to none', () {
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value([ConnectivityResult.none]));

      expect(
        networkInfo.onConnectivityChanged,
        emits(false),
      );
    });
  });
}
