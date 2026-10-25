import 'package:flutter_test/flutter_test.dart';
import 'package:one_tour_app/features/trip_planner/services/local_db_service.dart';
import 'package:one_tour_app/features/trip_planner/services/city_pack_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CityPackDownloadService & Offline Packs', () {
    final db = LocalDbService.instance;
    final packService = CityPackDownloadService.instance;

    setUp(() async {
      await db.init();
    });

    test('verifies pack paths are properly formatted', () async {
      final dbPath = await packService.getPackDbPath('recife');
      expect(dbPath.contains('pack_recife.sqlite'), true);

      final mapPath = await packService.getMapPmtilesPath('recife');
      expect(mapPath.contains('recife.pmtiles'), true);
    });

    test('downloads city pack with fallback and marks downloaded', () async {
      int reportedProgress = 0;
      final success = await packService.downloadCityPack(
        'recife',
        onProgress: (p) => reportedProgress = p,
      );

      expect(success, true);
      expect(reportedProgress, 100);

      final isDownloaded = await db.isCityDownloaded('recife');
      expect(isDownloaded, true);

      final places = await db.getPlacesForCity('recife');
      expect(places.isNotEmpty, true);
      expect(places.any((p) => p.id == 'marco_zero'), true);
    });

    test('removes city pack cleanly', () async {
      await packService.removeCityPack('recife');
      final isDownloaded = await db.isCityDownloaded('recife');
      expect(isDownloaded, false);
    });
  });
}
