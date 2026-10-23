import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/house_ads/domain/house_ad_model.dart';
import 'package:one_tour_app/features/house_ads/services/house_ads_service.dart';

void main() {
  group('HouseAdsService', () {
    final service = HouseAdsService.instance;

    test('retrieves targeted ads by UF', () async {
      final ads = await service.getAds(uf: 'PE');
      expect(ads.isNotEmpty, true);
      expect(ads.every((ad) => ad.targetUf == 'PE'), true);
    });

    test('filters ads by position (home_card, attraction_banner, interstitial)', () async {
      final bannerAds = await service.getAds(uf: 'PE', position: 'attraction_banner');
      expect(bannerAds.isNotEmpty, true);
      expect(bannerAds.every((ad) => ad.position == 'attraction_banner'), true);

      final interstitialAds = await service.getAds(uf: 'PE', position: 'interstitial');
      expect(interstitialAds.isNotEmpty, true);
      expect(interstitialAds.every((ad) => ad.position == 'interstitial'), true);
    });

    test('distinguishes cross_promotion and direct_sponsor types', () async {
      final allAds = await service.getAds(uf: 'PE');
      final hasCrossPromo = allAds.any((ad) => ad.type == 'cross_promotion');
      final hasDirectSponsor = allAds.any((ad) => ad.type == 'direct_sponsor');

      expect(hasCrossPromo, true);
      expect(hasDirectSponsor, true);
    });

    test('tracks impression and click telemetry gracefully', () async {
      final ad = HouseAdModel(
        id: 'test_ad',
        type: 'cross_promotion',
        title: 'Test Ad',
        subtitle: 'Test Subtitle',
        tag: 'TEST',
        imageUrl: 'https://example.com/ad.jpg',
        actionLabel: 'Click Me',
        targetUrl: 'https://onetour.app',
        targetUf: 'PE',
        position: 'home_card',
      );

      // Should complete without exceptions
      await service.trackImpression(ad);
      await service.trackClick(ad);
    });
  });
}
