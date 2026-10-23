import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_flavor.dart';

final appFlavorProvider = StateProvider<AppFlavor>((ref) => AppFlavor.pe);

final flavorConfigProvider = Provider<FlavorConfig>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  return FlavorConfig.of(flavor);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final localeProvider = StateProvider<Locale>((ref) => const Locale('pt'));
