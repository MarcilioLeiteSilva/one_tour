import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/core/ads/admob_config.dart';
import 'package:one_tour_app/core/ads/admob_service.dart';

void main() {
  group('Google AdMob Architecture & Multi-Flavor Configuration Tests', () {
    test('AdMobConfig returns authentic production IDs for Pernambuco when in production mode', () {
      final units = AdMobConfig.getUnitsForUf('pe', forceProduction: true);

      expect(units.appId, 'ca-app-pub-5133242303791049~4445477549');
      expect(units.bannerId, 'ca-app-pub-5133242303791049/1923255989');
      expect(units.interstitialId, 'ca-app-pub-5133242303791049/4252151837');
      expect(units.nativeId, 'ca-app-pub-5133242303791049/6065468944');
      expect(units.rewardedId, 'ca-app-pub-5133242303791049/6792439283');
    });

    test('AdMobConfig returns safe Google Test IDs by default in test/debug to protect account from bans', () {
      final units = AdMobConfig.getUnitsForUf('pe');

      expect(units.appId, AdMobConfig.testAppId);
      expect(units.bannerId, AdMobConfig.testBannerId);
      expect(units.interstitialId, AdMobConfig.testInterstitialId);
      expect(units.nativeId, AdMobConfig.testNativeId);
      expect(units.rewardedId, AdMobConfig.testRewardedId);
    });

    test('AdMobConfig gracefully falls back to test units for unconfigured states', () {
      final units = AdMobConfig.getUnitsForUf('sp', forceProduction: true);

      expect(units.appId, AdMobConfig.testAppId);
      expect(units.bannerId, AdMobConfig.testBannerId);
    });

    test('AdMobService singleton instance is accessible', () {
      final service = AdMobService.instance;
      expect(service, isNotNull);
    });
  });
}
