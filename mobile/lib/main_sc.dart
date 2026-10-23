import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_flavor.dart';

/// Entrypoint específico para compilar e rodar o flavor Tour Santa Catarina (SC)
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        appFlavorProvider.overrideWith((ref) => AppFlavor.sc),
      ],
      child: const OneTourApp(),
    ),
  );
}
