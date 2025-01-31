import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider(
  (ref) => AppConfig(
    appName: 'lote',
  ),
);

class AppConfig {
  final String appName;

  AppConfig({required this.appName});
}
