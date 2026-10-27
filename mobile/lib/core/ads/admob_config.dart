import 'package:flutter/foundation.dart';

/// Configurações e mapeamento de IDs do Google AdMob por Estado (Flavor)
class AdMobUnitIds {
  final String appId;
  final String bannerId;
  final String interstitialId;
  final String nativeId;
  final String rewardedId;

  const AdMobUnitIds({
    required this.appId,
    required this.bannerId,
    required this.interstitialId,
    required this.nativeId,
    required this.rewardedId,
  });
}

class AdMobConfig {
  AdMobConfig._();

  // IDs Oficiais de Teste da Google (Universal para desenvolvimento seguro)
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static const AdMobUnitIds testUnits = AdMobUnitIds(
    appId: testAppId,
    bannerId: testBannerId,
    interstitialId: testInterstitialId,
    nativeId: testNativeId,
    rewardedId: testRewardedId,
  );

  /// Catálogo de IDs de Produção por Estado
  static const Map<String, AdMobUnitIds> _productionUnits = {
    // 1. Pernambuco (Piloto Oficial)
    'pe': AdMobUnitIds(
      appId: 'ca-app-pub-5133242303791049~4445477549',
      bannerId: 'ca-app-pub-5133242303791049/1923255989',
      interstitialId: 'ca-app-pub-5133242303791049/4252151837',
      nativeId: 'ca-app-pub-5133242303791049/6065468944',
      rewardedId: 'ca-app-pub-5133242303791049/6792439283',
    ),
    // Outros estados da Onda 1 serão adicionados aqui conforme forem criados no console
  };

  /// Obtém os blocos corretos para a UF solicitada.
  /// Em modo de depuração (kDebugMode), usa sempre os IDs de teste do Google
  /// para evitar suspensão da conta AdMob por auto-cliques ou impressões de teste.
  static AdMobUnitIds getUnitsForUf(String uf, {bool forceProduction = false}) {
    final normalizedUf = uf.toLowerCase().trim();

    if (kDebugMode && !forceProduction) {
      return testUnits;
    }

    final prod = _productionUnits[normalizedUf];
    if (prod != null) {
      return prod;
    }

    // Fallback para IDs de teste caso o estado ainda não tenha sido cadastrado
    return testUnits;
  }
}
