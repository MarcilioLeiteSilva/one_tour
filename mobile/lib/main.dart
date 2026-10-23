import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_flavor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Reads flavor from --dart-define=FLAVOR=... or defaults to PE
  const flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'pe');
  final currentFlavor = AppFlavor.fromString(flavorString);

  runApp(
    ProviderScope(
      overrides: [
        appFlavorProvider.overrideWith((ref) => currentFlavor),
      ],
      child: const OneTourApp(),
    ),
  );
}
