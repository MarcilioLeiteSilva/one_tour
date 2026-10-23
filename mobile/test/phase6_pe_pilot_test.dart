import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/trip_planner/services/local_db_service.dart';
import 'package:one_tour_app/features/trip_planner/services/trip_optimizer_service.dart';
import 'package:one_tour_app/features/trip_planner/domain/trip_request.dart';
import 'package:one_tour_app/features/house_ads/services/house_ads_service.dart';
import 'package:one_tour_app/features/notifications/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6: Pernambuco Pilot & Polo Destinations Validation', () {
    late LocalDbService dbService;
    const optimizer = TripOptimizerService();
    late HouseAdsService adsService;
    late NotificationService notificationService;

    setUp(() {
      dbService = LocalDbService.instance;
      adsService = HouseAdsService.instance;
      notificationService = NotificationService.instance;
    });

    test('Pernambuco packs catalog lists all 4 polo destinations with assets', () {
      final packs = dbService.getAvailableCityPacks();
      expect(packs.length, equals(4));

      final slugs = packs.map((p) => p['slug']).toList();
      expect(slugs, containsAll(['recife', 'porto_de_galinhas', 'carneiros', 'noronha']));

      final porto = packs.firstWhere((p) => p['slug'] == 'porto_de_galinhas');
      expect(porto['placesCount'], equals(10));
      expect(porto['packageSize'], equals('48 KB'));
      expect(porto['assetPath'], equals('assets/packs/pack_porto_de_galinhas.sqlite'));
    });

    test('Loads authentic curated POIs for Recife & Olinda', () async {
      final places = await dbService.getPlacesForCity('recife');
      expect(places.length, equals(15));
      expect(places.first.id, equals('marco_zero'));
      expect(places.first.rankPosicao, equals(1));
      expect(places.any((p) => p.isLunch), isTrue);
    });

    test('Loads authentic curated POIs for Porto de Galinhas', () async {
      final places = await dbService.getPlacesForCity('porto_de_galinhas');
      expect(places.length, equals(10));
      expect(places.first.id, equals('piscinas_porto'));
      expect(places.first.name, contains('Piscinas Naturais'));
      expect(places.any((p) => p.id == 'muro_alto'), isTrue);
      expect(places.any((p) => p.id == 'barcaxeira' && p.isLunch), isTrue);
    });

    test('Loads authentic curated POIs for Praia dos Carneiros', () async {
      final places = await dbService.getPlacesForCity('carneiros');
      expect(places.length, equals(8));
      expect(places.first.id, equals('capela_sao_benedito'));
      expect(places.any((p) => p.id == 'bora_bora_carneiros' && p.isLunch), isTrue);
      expect(places.any((p) => p.id == 'banho_argila_guadalupe'), isTrue);
    });

    test('Loads authentic curated POIs for Fernando de Noronha', () async {
      final places = await dbService.getPlacesForCity('noronha');
      expect(places.length, equals(10));
      expect(places.first.id, equals('baia_do_sancho'));
      expect(places.first.ratingAvg, equals(5.0));
      expect(places.any((p) => p.id == 'mirante_golfinhos'), isTrue);
      expect(places.any((p) => p.id == 'restaurante_varanda' && p.isLunch), isTrue);
    });

    test('Generates valid 3-day itinerary for Porto de Galinhas without LLM costs', () async {
      final places = await dbService.getPlacesForCity('porto_de_galinhas');
      const request = TripRequest(
        cityName: 'Porto de Galinhas',
        days: 3,
        pace: TripPace.moderate,
        companion: TripCompanion.couple,
        interests: {'praias', 'natureza', 'gastronomia'},
      );

      final plan = optimizer.optimizeTrip(request: request, allPlaces: places);

      expect(plan.daysCount, equals(3));
      expect(plan.days.length, equals(3));
      final totalStops = plan.days.fold<int>(0, (sum, d) => sum + d.stops.length);
      expect(totalStops, greaterThanOrEqualTo(6));

      for (final day in plan.days) {
        expect(day.stops.isNotEmpty, isTrue);
        expect(day.stops.first.startTime, equals('09:00'));
        // Check for injected lunch
        expect(day.stops.any((s) => s.isLunch), isTrue);
      }
    });

    test('Generates 5-day itinerary for Fernando de Noronha with day clustering', () async {
      final places = await dbService.getPlacesForCity('noronha');
      const request = TripRequest(
        cityName: 'Fernando de Noronha',
        days: 5,
        pace: TripPace.intense,
        companion: TripCompanion.solo,
        interests: {'praias', 'natureza', 'aventura', 'cultura'},
      );

      final plan = optimizer.optimizeTrip(request: request, allPlaces: places);

      expect(plan.days.length, equals(5));
      expect(plan.cityName, equals('Fernando de Noronha'));
      final totalStops = plan.days.fold<int>(0, (sum, d) => sum + d.stops.length);
      expect(totalStops, greaterThanOrEqualTo(8));
    });

    test('Kid-friendly filtering works correctly in Porto de Galinhas for families', () async {
      final places = await dbService.getPlacesForCity('porto_de_galinhas');
      const request = TripRequest(
        cityName: 'Porto de Galinhas',
        days: 2,
        pace: TripPace.relaxed,
        companion: TripCompanion.family,
        interests: {'praias', 'natureza'},
      );

      final plan = optimizer.optimizeTrip(request: request, allPlaces: places);

      // Verify non-lunch stops are kid friendly
      for (final day in plan.days) {
        for (final stop in day.stops.where((s) => !s.isLunch)) {
          expect(stop.place.kidFriendly, isTrue);
        }
      }
    });

    test('Regional FCM push subscriptions work for all Pernambuco polo cities', () async {
      expect(notificationService.subscribedTopics.contains('pe_geral'), isTrue);
      expect(notificationService.subscribedTopics.contains('pe_promocoes'), isTrue);

      await notificationService.subscribeToCity('PE', 'recife');
      expect(notificationService.subscribedTopics.contains('pe_recife'), isTrue);

      await notificationService.subscribeToCity('PE', 'porto_de_galinhas');
      expect(notificationService.subscribedTopics.contains('pe_porto_de_galinhas'), isTrue);

      await notificationService.subscribeToCity('PE', 'carneiros');
      expect(notificationService.subscribedTopics.contains('pe_carneiros'), isTrue);

      await notificationService.subscribeToCity('PE', 'noronha');
      expect(notificationService.subscribedTopics.contains('pe_noronha'), isTrue);
    });

    test('House Ads targeting delivers regional ads for Pernambuco', () async {
      final peAds = await adsService.getAds(uf: 'PE');
      expect(peAds.isNotEmpty, isTrue);

      // Verify regional PE ads exist
      expect(peAds.any((ad) => ad.targetUf == 'PE'), isTrue);
    });
  });
}
