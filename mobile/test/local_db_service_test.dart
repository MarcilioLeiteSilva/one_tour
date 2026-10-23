import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/trip_planner/domain/itinerary_models.dart';
import 'package:one_tour_app/features/trip_planner/domain/trip_request.dart';
import 'package:one_tour_app/features/trip_planner/services/local_db_service.dart';

void main() {
  group('LocalDbService', () {
    final db = LocalDbService.instance;

    setUp(() async {
      await db.init();
    });

    test('retrieves curated places for city offline', () async {
      final places = await db.getPlacesForCity('recife');
      expect(places.isNotEmpty, true);
      expect(places.any((p) => p.id == 'marco_zero'), true);
      expect(places.any((p) => p.isLunch), true);
    });

    test('saves, retrieves and deletes trip plans', () async {
      final plan = TripPlan(
        id: 'test_trip_123',
        title: 'Roteiro Teste Recife',
        cityName: 'Recife',
        daysCount: 1,
        pace: TripPace.moderate,
        companion: TripCompanion.couple,
        interests: const {'cultura'},
        days: const [
          ItineraryDay(
            dayNumber: 1,
            stops: [
              ItineraryStop(
                order: 1,
                place: Place(
                  id: 'marco_zero',
                  citySlug: 'recife',
                  name: 'Marco Zero',
                  category: 'cultura',
                  lat: -8.0631,
                  lon: -34.8711,
                  durationMin: 90,
                ),
                startTime: '09:00',
                endTime: '10:30',
              ),
            ],
          ),
        ],
        createdAt: DateTime.now(),
      );

      await db.saveTrip(plan);

      final retrieved = await db.getSavedTripById('test_trip_123');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test_trip_123');
      expect(retrieved.cityName, 'Recife');

      final allSaved = await db.getSavedTrips();
      expect(allSaved.any((t) => t.id == 'test_trip_123'), true);

      await db.deleteSavedTrip('test_trip_123');
      final afterDelete = await db.getSavedTripById('test_trip_123');
      expect(afterDelete, isNull);
    });

    test('toggles social likes offline', () async {
      final initialLiked = await db.isLiked('marco_zero');
      if (initialLiked) {
        await db.toggleLike('marco_zero');
      }

      // First toggle: like
      final liked = await db.toggleLike('marco_zero');
      expect(liked, true);
      expect(await db.isLiked('marco_zero'), true);

      // Second toggle: unlike
      final unliked = await db.toggleLike('marco_zero');
      expect(unliked, false);
      expect(await db.isLiked('marco_zero'), false);
    });
  });
}
