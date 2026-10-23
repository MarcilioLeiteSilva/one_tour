import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_tour_app/app.dart';

void main() {
  testWidgets('OneTourApp smoke test', (WidgetTester tester) async {
    // Em testes de widget sem internet, o Flutter simula 400 para Image.network.
    // Ignoramos especificamente a exceção de imagem de rede para o teste de fumaça da UI.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) {
        return;
      }
      originalOnError?.call(details);
    };

    await tester.pumpWidget(
      const ProviderScope(
        child: OneTourApp(),
      ),
    );

    // Aguarda montagem da árvore de widgets
    await tester.pump();

    FlutterError.onError = originalOnError;
  });
}
