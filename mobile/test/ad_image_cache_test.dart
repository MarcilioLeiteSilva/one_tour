import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/house_ads/services/ad_image_cache_service.dart';

void main() {
  group('House Ads Persistent Image Cache Tests', () {
    test('AdImageCacheService singleton is available', () {
      final service = AdImageCacheService.instance;
      expect(service, isNotNull);
    });

    test('getLocalImageFile returns null safely for empty or invalid URLs', () async {
      final service = AdImageCacheService.instance;
      final resultEmpty = await service.getLocalImageFile('');
      final resultInvalid = await service.getLocalImageFile('not-a-valid-url');

      expect(resultEmpty, isNull);
      expect(resultInvalid, isNull);
    });

    test('downloadAndCacheImage gracefully handles empty or invalid URLs without throwing', () async {
      final service = AdImageCacheService.instance;
      final result = await service.downloadAndCacheImage('');
      expect(result, isNull);
    });

    test('prefetchImages executes without unhandled exceptions on invalid or empty lists', () async {
      final service = AdImageCacheService.instance;
      await expectLater(service.prefetchImages([]), completes);
      await expectLater(service.prefetchImages(['']), completes);
    });
  });
}
