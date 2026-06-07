import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:drug/core/di/injection_container.config.dart';

final GetIt sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => sl.init();
