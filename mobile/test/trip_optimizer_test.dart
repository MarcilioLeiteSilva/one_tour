import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/trip_planner/domain/itinerary_models.dart';
import 'package:one_tour_app/features/trip_planner/domain/trip_request.dart';
import 'package:one_tour_app/features/trip_planner/services/trip_optimizer_service.dart';

void main() {
  group('TripOptimizerService', () {
    const optimizer = TripOptimizerService();

    final testPlaces = [
      const Place(
        id: 'marco_zero',
        citySlug: 'recife',
        name: 'Praça do Marco Zero',
        category: 'cultura',
        lat: -8.0631,
        lon: -34.8711,
        durationMin: 90,
        score: 98,
        ratingAvg: 4.9,
        mustSee: true,
        kidFriendly: true,
        rankPosicao: 1,
      ),
      const Place(
        id: 'cais_sertao',
        citySlug: 'recife',
        name: 'Museu Cais do Sertão',
        category: 'cultura',
        lat: -8.0608,
        lon: -34.8706,
        durationMin: 90,
        score: 96,
        ratingAvg: 4.8,
        mustSee: true,
        kidFriendly: true,
        rankPosicao: 2,
      ),
      const Place(
        id: 'restaurante_leite',
        citySlug: 'recife',
        name: 'Restaurante Leite',
        category: 'gastronomia',
        lat: -8.0612,
        lon: -34.8835,
        durationMin: 75,
        score: 95,
        ratingAvg: 4.8,
        isLunch: true,
        kidFriendly: false,
        rankPosicao: 5,
      ),
      const Place(
        id: 'alto_da_se',
        citySlug: 'recife',
        name: 'Alto da Sé Olinda',
        category: 'cultura',
        lat: -8.0139,
        lon: -34.8519,
        durationMin: 90,
        score: 97,
        ratingAvg: 4.9,
        mustSee: true,
        kidFriendly: true,
        rankPosicao: 3,
      ),
      const Place(
        id: 'boa_viagem',
        citySlug: 'recife',
        name: 'Praia de Boa Viagem',
        category: 'praias',
        lat: -8.1275,
        lon: -34.9011,
        durationMin: 120,
        score: 95,
        ratingAvg: 4.7,
        mustSee: false,
        kidFriendly: true,
        rankPosicao: 6,
      ),
      const Place(
        id: 'brennand_castelo',
        citySlug: 'recife',
        name: 'Instituto Ricardo Brennand',
        category: 'cultura',
        lat: -8.0645,
        lon: -34.9642,
        durationMin: 150,
        score: 99,
        ratingAvg: 4.9,
        mustSee: true,
        kidFriendly: true,
        rankPosicao: 4,
      ),
    ];

    test('calculates accurate Haversine distance in meters', () {
      // Marco Zero (-8.0631, -34.8711) to Cais do Sertão (-8.0608, -34.8706) is ~260m
      final dist = TripOptimizerService.calculateDistanceMeters(
        -8.0631,
        -34.8711,
        -8.0608,
        -34.8706,
      );
      expect(dist, greaterThan(200));
      expect(dist, lessThan(350));
    });

    test('generates valid 1-day itinerary with 09:00 start time', () {
      const request = TripRequest(
        cityName: 'Recife',
        days: 1,
        pace: TripPace.relaxed,
        companion: TripCompanion.couple,
        interests: {'cultura'},
      );

      final plan = optimizer.optimizeTrip(
        request: request,
        allPlaces: testPlaces,
      );

      expect(plan.daysCount, 1);
      expect(plan.days.length, 1);
      expect(plan.days[0].stops.isNotEmpty, true);
      expect(plan.days[0].stops[0].startTime, '09:00');
    });

    test('generates multi-day itinerary with proper day clustering and lunch', () {
      const request = TripRequest(
        cityName: 'Recife',
        days: 2,
        pace: TripPace.moderate,
        companion: TripCompanion.couple,
        interests: {'cultura', 'praias', 'gastronomia'},
      );

      final plan = optimizer.optimizeTrip(
        request: request,
        allPlaces: testPlaces,
      );

      expect(plan.daysCount, 2);
      expect(plan.days.length, 2);
      expect(plan.days[0].stops.isNotEmpty, true);
      expect(plan.days[1].stops.isNotEmpty, true);

      // Verify lunch was injected in at least one day
      final hasLunch = plan.days.any((d) => d.stops.any((s) => s.isLunch));
      expect(hasLunch, true);
    });

    test('family companion prioritizes kid-friendly attractions', () {
      const familyReq = TripRequest(
        cityName: 'Recife',
        days: 1,
        pace: TripPace.relaxed,
        companion: TripCompanion.family,
        interests: {'cultura'},
      );

      final kidFriendlyScore = optimizer.scorePlace(testPlaces[0], familyReq);
      final adultOnlyScore = optimizer.scorePlace(testPlaces[2], familyReq);

      expect(kidFriendlyScore, greaterThan(adultOnlyScore));
    });
  });
}
