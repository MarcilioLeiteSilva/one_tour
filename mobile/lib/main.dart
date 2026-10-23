import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_flavor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        // Estado Piloto inicial padrão: Pernambuco
        appFlavorProvider.overrideWith((ref) => AppFlavor.pe),
      ],
      child: const OneTourApp(),
    ),
  );
}
