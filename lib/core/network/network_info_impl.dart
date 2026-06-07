import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/network/network_info.dart';

@LazySingleton(as: NetworkInfo)
final class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map((results) => results.any((r) => r != ConnectivityResult.none));
}
