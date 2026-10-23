import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_flavor.dart';

/// Entrypoint específico para compilar e rodar o flavor Tour Rio Grande do Norte (RN)
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        appFlavorProvider.overrideWith((ref) => AppFlavor.rn),
      ],
      child: const OneTourApp(),
    ),
  );
}
