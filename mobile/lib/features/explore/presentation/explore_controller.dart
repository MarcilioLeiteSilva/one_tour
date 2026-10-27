import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../data/mock_pe_data.dart';
import '../services/explore_repository.dart';
import '../../trip_planner/services/local_db_service.dart';

/// Provider returning the list of cities (from PocketBase with SQLite fallback)
final citiesProvider = FutureProvider<List<CityModel>>((ref) async {
  final config = ref.watch(flavorConfigProvider);
  return ExploreRepository.instance.getCities(uf: config.uf);
});

/// Provider returning all curated attractions across all destinations in the state
final curatedAttractionsProvider = FutureProvider<List<AttractionModel>>((ref) async {
  final config = ref.watch(flavorConfigProvider);
  return ExploreRepository.instance.getAttractions(uf: config.uf);
});

/// Provider returning attractions specifically for a given city
final cityAttractionsProvider =
    FutureProvider.family<List<AttractionModel>, String>((ref, citySlug) async {
  final config = ref.watch(flavorConfigProvider);
  return ExploreRepository.instance.getAttractions(uf: config.uf, citySlug: citySlug);
});

/// Provider returning the set of offline city pack slugs downloaded on the device
final downloadedPacksProvider = FutureProvider<Set<String>>((ref) async {
  return LocalDbService.instance.getDownloadedCities();
});
