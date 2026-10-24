import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../social/services/social_service.dart';
import '../domain/itinerary_models.dart';
import '../domain/trip_request.dart';
import '../services/local_db_service.dart';
import '../services/trip_optimizer_service.dart';

final localDbServiceProvider = Provider<LocalDbService>((ref) {
  return LocalDbService.instance;
});

final tripOptimizerServiceProvider = Provider<TripOptimizerService>((ref) {
  return const TripOptimizerService();
});

/// Current active trip plan being viewed or generated
final currentTripPlanProvider =
    StateNotifierProvider<CurrentTripNotifier, AsyncValue<TripPlan?>>((ref) {
  return CurrentTripNotifier(ref);
});

class CurrentTripNotifier extends StateNotifier<AsyncValue<TripPlan?>> {
  final Ref _ref;

  CurrentTripNotifier(this._ref) : super(const AsyncValue.data(null));

  void setPlan(TripPlan plan) {
    state = AsyncValue.data(plan);
  }

  Future<TripPlan?> generateTrip(TripRequest request) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(localDbServiceProvider);
      final optimizer = _ref.read(tripOptimizerServiceProvider);

      // 1. Fetch offline places for the city
      final places = await db.getPlacesForCity(request.cityName.toLowerCase());

      // 2. Run local combinatorial VRP optimizer (pure Dart, zero latency)
      final plan = optimizer.optimizeTrip(
        request: request,
        allPlaces: places,
      );

      // 3. Save to local SQLite
      await db.saveTrip(plan);

      // 4. Update state and refresh saved list
      state = AsyncValue.data(plan);
      _ref.invalidate(savedTripsProvider);

      return plan;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> loadTripById(String id) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(localDbServiceProvider);
      final plan = await db.getSavedTripById(id);
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for all saved trips in local SQLite
final savedTripsProvider = FutureProvider<List<TripPlan>>((ref) async {
  final db = ref.read(localDbServiceProvider);
  return db.getSavedTrips();
});

/// Notifier for liked place IDs (Offline-first social proof)
final userLikesProvider =
    StateNotifierProvider<UserLikesNotifier, Set<String>>((ref) {
  return UserLikesNotifier(ref);
});

class UserLikesNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;

  UserLikesNotifier(this._ref) : super(const {}) {
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final db = _ref.read(localDbServiceProvider);
    final likes = await db.getLikedPlaceIds();
    state = likes;
  }

  Future<bool> toggleLike(String placeId) async {
    final db = _ref.read(localDbServiceProvider);
    final isLikedNow = await db.toggleLike(placeId);
    if (isLikedNow) {
      state = {...state, placeId};
    } else {
      state = state.where((id) => id != placeId).toSet();
    }
    await SocialService.instance.recordLike(placeId, liked: isLikedNow);
    return isLikedNow;
  }

  bool isLiked(String placeId) {
    return state.contains(placeId);
  }
}
