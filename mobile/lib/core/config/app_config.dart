import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_flavor.dart';

/// PocketBase (CMS/content). Override with --dart-define=BACKEND_BASE_URL=...
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'https://onetour-backend-onetour.gtalg3.easypanel.host',
);

/// One Tour API (votes, telemetry, rankings). Override with --dart-define=API_BASE_URL=...
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://onetour-api-onetour.gtalg3.easypanel.host',
);

final appFlavorProvider = StateProvider<AppFlavor>((ref) => AppFlavor.pe);

final flavorConfigProvider = Provider<FlavorConfig>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  return FlavorConfig.of(flavor);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final localeProvider = StateProvider<Locale>((ref) => const Locale('pt'));
