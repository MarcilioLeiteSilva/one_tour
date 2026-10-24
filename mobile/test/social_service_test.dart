import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/social/domain/place_stats.dart';
import 'package:one_tour_app/features/social/services/social_service.dart';
import 'package:one_tour_app/features/trip_planner/services/local_db_service.dart';

void main() {
  group('SocialService & Offline Outbox', () {
    final social = SocialService.instance;
    final db = LocalDbService.instance;

    setUp(() async {
      await db.init();
    });

    tearDown(() {
      social.stop();
    });

    test('generates persistent anonymous device_id', () async {
      final id1 = await social.deviceId();
      expect(id1.startsWith('dev_'), true);
      expect(id1.length >= 16, true);

      // Subsequent call must return the exact same device ID
      final id2 = await social.deviceId();
      expect(id2, id1);
    });

    test('enqueues social like in offline pending_events outbox', () async {
      final initialCount = await db.pendingEventsCount();

      await social.recordLike('marco_zero', liked: true, citySlug: 'recife');
      final newCount = await db.pendingEventsCount();
      expect(newCount >= initialCount + 1, true);

      final events = await db.getPendingEvents(limit: 10);
      expect(events.isNotEmpty, true);
      expect(events.last['payload'].toString().contains('marco_zero'), true);
    });

    test('enqueues review and ad telemetry in offline outbox', () async {
      await social.submitReview('piscinas_porto', 5.0, citySlug: 'porto_de_galinhas');
      await social.recordAdClick('ad_catamara', 'home_card', citySlug: 'recife', uf: 'PE');

      final count = await db.pendingEventsCount();
      expect(count >= 2, true);
    });

    test('SocialStatsRegistry updates and provides score/ranking to models', () {
      final registry = SocialStatsRegistry.instance;

      registry.replaceAll([
        const PlaceStats(
          placeId: 'marco_zero',
          likesCount: 15420,
          ratingAvg: 4.95,
          ratingCount: 3820,
          score: 4.98,
          rankState: 1,
          rankCity: 1,
        ),
      ]);

      final stats = registry.of('marco_zero');
      expect(stats, isNotNull);
      expect(stats!.likesCount, 15420);
      expect(stats.ratingAvg, 4.95);
      expect(stats.rankState, 1);
    });
  });
}
