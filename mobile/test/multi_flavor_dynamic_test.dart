import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_tour_app/core/config/app_config.dart';
import 'package:one_tour_app/core/config/app_flavor.dart';
import 'package:one_tour_app/features/explore/presentation/explore_controller.dart';
import 'package:one_tour_app/features/explore/services/explore_repository.dart';
import 'package:one_tour_app/features/trip_planner/services/local_db_service.dart';
import 'package:one_tour_app/features/house_ads/services/house_ads_service.dart';

void main() {
  group('Multi-Flavor Dynamic Architecture Tests', () {
    test('FlavorConfig dynamically reflects overridden AppFlavor for Alagoas (AL)', () {
      final container = ProviderContainer(
        overrides: [
          appFlavorProvider.overrideWith((ref) => AppFlavor.al),
        ],
      );
      addTearDown(container.dispose);

      final config = container.read(flavorConfigProvider);
      expect(config.uf, 'AL');
      expect(config.appName, 'Tour Alagoas');
      expect(config.capital, 'Maceió');
      expect(config.stateName, 'Alagoas');
      expect(config.hasCoastline, isTrue);
    });

    test('ExploreRepository returns Alagoas cities when UF is AL', () async {
      final cities = await ExploreRepository.instance.getCities(uf: 'AL');
      expect(cities.isNotEmpty, isTrue);
      expect(cities.any((c) => c.id == 'maceio'), isTrue);
      expect(cities.any((c) => c.name.contains('Maceió')), isTrue);
    });

    test('ExploreRepository returns Alagoas attractions without leaking PE POIs', () async {
      final attractions = await ExploreRepository.instance.getAttractions(uf: 'AL');
      expect(attractions.isNotEmpty, isTrue);
      expect(attractions.any((a) => a.id.contains('pajucara') || a.id.contains('maceio') || a.id.contains('ponta_verde')), isTrue);
      // Ensure Pernambuco POIs like Marco Zero are not leaked into AL list
      expect(attractions.any((a) => a.id == 'marco_zero'), isFalse);
    });

    test('LocalDbService provides curated offline POIs for Maceió', () async {
      final places = await LocalDbService.instance.getPlacesForCity('maceio');
      expect(places.isNotEmpty, isTrue);
      expect(places.length, greaterThanOrEqualTo(4));
      expect(places.first.citySlug, 'maceio');
      expect(places.first.lat, lessThan(0)); // Southern hemisphere
    });

    test('HouseAdsService delivers Alagoas targeted ads or resilient fallback', () async {
      final ads = await HouseAdsService.instance.getAds(uf: 'AL');
      expect(ads.isNotEmpty, isTrue);
      expect(ads.any((ad) => ad.targetUf == 'AL' || ad.type == 'cross_promotion'), isTrue);
    });

    test('Riverpod citiesProvider dynamically resolves for Alagoas container', () async {
      final container = ProviderContainer(
        overrides: [
          appFlavorProvider.overrideWith((ref) => AppFlavor.al),
        ],
      );
      addTearDown(container.dispose);

      final cities = await container.read(citiesProvider.future);
      expect(cities.isNotEmpty, isTrue);
      expect(cities.any((c) => c.id == 'maceio'), isTrue);
    });
  });
}
