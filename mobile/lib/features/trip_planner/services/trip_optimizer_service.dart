import 'dart:math' as math;
import '../domain/trip_request.dart';
import '../domain/itinerary_models.dart';

/// Pure Dart Combinatorial Offline Trip Optimizer (VRP + 2-Opt + Time Windows)
/// Zero LLM cost (R$ 0,00), sub-second execution, 100% offline.
class TripOptimizerService {
  const TripOptimizerService();

  /// Calculate distance between two lat/lon points in meters using Haversine formula
  static int calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadius * c).round();
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Estimate travel segment (walking for <= 1500m, driving for > 1500m)
  static TravelSegment estimateSegment(Place from, Place to) {
    final dist = calculateDistanceMeters(from.lat, from.lon, to.lat, to.lon);
    if (dist <= 1500) {
      // Walk: ~4.5 km/h = 75 m/min + 2 min buffer
      final minutes = math.max(3, (dist / 75).ceil() + 2);
      return TravelSegment(
        distanceMeters: dist,
        durationMinutes: minutes,
        isWalk: true,
      );
    } else {
      // Drive: ~25 km/h urban traffic = 416 m/min + 5 min traffic/parking buffer
      final minutes = math.max(6, (dist / 416).ceil() + 5);
      return TravelSegment(
        distanceMeters: dist,
        durationMinutes: minutes,
        isWalk: false,
      );
    }
  }

  /// Score a place based on user preferences, companion, and popularity
  double scorePlace(Place place, TripRequest request) {
    double score = place.score * 0.3; // Base editorial score (0..30)

    // Category match
    final cleanCategory = place.category.toLowerCase().trim();
    final hasInterestMatch = request.interests.any((interest) {
      final i = interest.toLowerCase().trim();
      return cleanCategory.contains(i) || i.contains(cleanCategory);
    });
    if (hasInterestMatch) {
      score += 35.0;
    }

    // Must-see bonus
    if (place.mustSee) {
      score += 25.0;
    }

    // Social metrics
    score += (place.ratingAvg * 6.0); // 4.9 * 6 = ~29.4
    final logReviews = math.log(1 + place.ratingCount);
    score += math.min(15.0, logReviews * 1.8);
    score += math.min(10.0, place.likesCount * 0.001);

    // Rank bonus
    final rankBonus = math.max(0.0, (20 - place.rankPosicao) * 1.5);
    score += rankBonus;

    // Companion profile rules
    if (request.companion == TripCompanion.family) {
      if (place.kidFriendly) {
        score += 35.0;
      } else {
        score -= 60.0; // Strongly deprioritize bars, adult-only venues
      }
    }

    return score;
  }

  /// Target stops per day based on pace
  int stopsPerDayForPace(TripPace pace) {
    switch (pace) {
      case TripPace.relaxed:
        return 2;
      case TripPace.moderate:
        return 3;
      case TripPace.intense:
        return 4;
    }
  }

  /// Generate optimized multi-day trip plan
  TripPlan optimizeTrip({
    required TripRequest request,
    required List<Place> allPlaces,
  }) {
    if (allPlaces.isEmpty) {
      return TripPlan(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Roteiro ${request.cityName}',
        cityName: request.cityName,
        daysCount: request.days,
        pace: request.pace,
        companion: request.companion,
        interests: request.interests,
        days: const [],
        createdAt: DateTime.now(),
      );
    }

    final int targetDays = math.max(1, math.min(7, request.days));
    final int stopsPerDay = stopsPerDayForPace(request.pace);
    final int totalTargetSightseeing = targetDays * stopsPerDay;

    // 1. Separate regular sightseeing candidates and lunch candidates
    final List<Place> lunchCandidates = allPlaces
        .where((p) => p.isLunch || p.category.toLowerCase().contains('gastro'))
        .toList();

    final List<Place> sightCandidates =
        allPlaces.where((p) => !p.isLunch).toList();

    // Sort sightseeing places by priority score
    sightCandidates.sort((a, b) {
      final scoreA = scorePlace(a, request);
      final scoreB = scorePlace(b, request);
      return scoreB.compareTo(scoreA);
    });

    // Select top candidates
    final int poolSize = math.min(sightCandidates.length, totalTargetSightseeing);
    final List<Place> selectedPlaces = sightCandidates.take(poolSize).toList();

    // 2. Spatial Clustering into N Days (Geographic partition)
    final List<List<Place>> dayClusters = _clusterPlacesByDay(
      places: selectedPlaces,
      numDays: targetDays,
      targetPerDay: stopsPerDay,
    );

    // 3. For each day, solve TSP (2-Opt) and inject lunch
    final List<ItineraryDay> itineraryDays = [];
    final Set<String> usedLunchIds = {};

    for (int dayIdx = 0; dayIdx < targetDays; dayIdx++) {
      final dayNumber = dayIdx + 1;
      List<Place> dayPlaces = dayClusters[dayIdx];

      if (dayPlaces.isEmpty) {
        // Fallback if pool is small: pick any available remaining place
        final remaining = sightCandidates.where((p) => !selectedPlaces.contains(p)).toList();
        if (remaining.isNotEmpty) {
          dayPlaces = [remaining.first];
        }
      }

      // Order stops with 2-Opt
      final orderedStops = _solveTsp2Opt(dayPlaces);

      // Schedule timeline and inject lunch
      final dayItinerary = _buildDaySchedule(
        dayNumber: dayNumber,
        places: orderedStops,
        lunchCandidates: lunchCandidates,
        usedLunchIds: usedLunchIds,
      );

      itineraryDays.add(dayItinerary);
    }

    final title = 'Roteiro Otimizado ${request.cityName} ($targetDays ${targetDays == 1 ? 'Dia' : 'Dias'})';

    return TripPlan(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      cityName: request.cityName,
      daysCount: targetDays,
      pace: request.pace,
      companion: request.companion,
      interests: request.interests,
      days: itineraryDays,
      createdAt: DateTime.now(),
    );
  }

  /// Spatial clustering: groups places into geographically compact days
  List<List<Place>> _clusterPlacesByDay({
    required List<Place> places,
    required int numDays,
    required int targetPerDay,
  }) {
    final List<List<Place>> clusters = List.generate(numDays, (_) => []);
    if (places.isEmpty) return clusters;
    if (numDays == 1) {
      clusters[0].addAll(places);
      return clusters;
    }

    // Pick seeds maximizing distance between each other (Farthest First Heuristic)
    final List<Place> seeds = [];
    seeds.add(places.first);

    while (seeds.length < numDays && seeds.length < places.length) {
      Place bestCandidate = places.first;
      int maxMinDist = -1;

      for (final p in places) {
        if (seeds.contains(p)) continue;
        int minDistToSeeds = 999999999;
        for (final s in seeds) {
          final d = calculateDistanceMeters(p.lat, p.lon, s.lat, s.lon);
          if (d < minDistToSeeds) minDistToSeeds = d;
        }
        if (minDistToSeeds > maxMinDist) {
          maxMinDist = minDistToSeeds;
          bestCandidate = p;
        }
      }
      seeds.add(bestCandidate);
    }

    // Initialize clusters with seeds
    final List<Place> unassigned = List.from(places);
    for (int i = 0; i < seeds.length; i++) {
      clusters[i].add(seeds[i]);
      unassigned.remove(seeds[i]);
    }

    // Assign remaining places to nearest cluster with remaining capacity
    for (final p in unassigned) {
      int bestClusterIdx = 0;
      int bestDist = 999999999;

      for (int i = 0; i < numDays; i++) {
        // Soft capacity constraint
        if (clusters[i].length >= targetPerDay + 1) continue;

        // Calculate average distance to places currently in cluster i
        int sumDist = 0;
        for (final cp in clusters[i]) {
          sumDist += calculateDistanceMeters(p.lat, p.lon, cp.lat, cp.lon);
        }
        final avgDist = clusters[i].isEmpty ? 0 : (sumDist ~/ clusters[i].length);

        if (avgDist < bestDist) {
          bestDist = avgDist;
          bestClusterIdx = i;
        }
      }

      clusters[bestClusterIdx].add(p);
    }

    return clusters;
  }

  /// TSP 2-Opt local search solver to minimize travel distance within a day
  List<Place> _solveTsp2Opt(List<Place> places) {
    if (places.length <= 2) return List.from(places);

    // Initial Greedy Nearest-Neighbor route
    final List<Place> route = [];
    final List<Place> pool = List.from(places);

    route.add(pool.removeAt(0));
    while (pool.isNotEmpty) {
      final current = route.last;
      int nearestIdx = 0;
      int minDist = 999999999;
      for (int i = 0; i < pool.length; i++) {
        final d = calculateDistanceMeters(
          current.lat,
          current.lon,
          pool[i].lat,
          pool[i].lon,
        );
        if (d < minDist) {
          minDist = d;
          nearestIdx = i;
        }
      }
      route.add(pool.removeAt(nearestIdx));
    }

    // 2-Opt heuristic optimization
    bool improved = true;
    int iterations = 0;
    while (improved && iterations < 50) {
      improved = false;
      iterations++;
      for (int i = 0; i < route.length - 1; i++) {
        for (int k = i + 1; k < route.length; k++) {
          final int currentDist = _totalRouteDistance(route);
          final List<Place> newRoute = _twoOptSwap(route, i, k);
          final int newDist = _totalRouteDistance(newRoute);

          if (newDist < currentDist) {
            route.clear();
            route.addAll(newRoute);
            improved = true;
            break;
          }
        }
        if (improved) break;
      }
    }

    return route;
  }

  static List<Place> _twoOptSwap(List<Place> route, int i, int k) {
    final List<Place> newRoute = [];
    // 1. Take from 0 to i-1
    for (int c = 0; c < i; c++) {
      newRoute.add(route[c]);
    }
    // 2. Take from i to k in reverse order
    for (int c = k; c >= i; c--) {
      newRoute.add(route[c]);
    }
    // 3. Take from k+1 to end
    for (int c = k + 1; c < route.length; c++) {
      newRoute.add(route[c]);
    }
    return newRoute;
  }

  static int _totalRouteDistance(List<Place> route) {
    int total = 0;
    for (int i = 0; i < route.length - 1; i++) {
      total += calculateDistanceMeters(
        route[i].lat,
        route[i].lon,
        route[i + 1].lat,
        route[i + 1].lon,
      );
    }
    return total;
  }

  /// Construct the timed itinerary day, injecting lunch at ~12:30
  ItineraryDay _buildDaySchedule({
    required int dayNumber,
    required List<Place> places,
    required List<Place> lunchCandidates,
    required Set<String> usedLunchIds,
  }) {
    if (places.isEmpty) {
      return ItineraryDay(dayNumber: dayNumber, stops: const []);
    }

    // Day starts at 09:00 AM (540 minutes from midnight)
    int currentMinutes = 9 * 60; // 540
    final List<ItineraryStop> stops = [];
    int totalVisitMin = 0;
    int totalTransitMin = 0;
    int totalMeters = 0;

    bool lunchInjected = false;
    Place? lastPlace;

    for (int i = 0; i < places.length; i++) {
      final currentPlace = places[i];

      // Check if we should inject lunch before this stop (between 12:00 and 13:30)
      if (!lunchInjected && currentMinutes >= 12 * 60 && lastPlace != null) {
        final lunchStop = _findBestLunchStop(
          nearPlace: lastPlace,
          lunchCandidates: lunchCandidates,
          usedLunchIds: usedLunchIds,
          currentMinutes: currentMinutes,
          order: stops.length + 1,
        );

        if (lunchStop != null) {
          // Connect last stop to lunch
          final segToLunch = estimateSegment(lastPlace, lunchStop.place);
          if (stops.isNotEmpty) {
            stops[stops.length - 1] =
                stops.last.copyWith(transitToNext: segToLunch);
            totalTransitMin += segToLunch.durationMinutes;
            totalMeters += segToLunch.distanceMeters;
            currentMinutes += segToLunch.durationMinutes;
          }

          // Lunch visit
          final lunchStartStr = _formatMinutes(currentMinutes);
          currentMinutes += lunchStop.place.durationMin;
          final lunchEndStr = _formatMinutes(currentMinutes);
          totalVisitMin += lunchStop.place.durationMin;

          // Segment from lunch to currentPlace
          final segFromLunch = estimateSegment(lunchStop.place, currentPlace);
          totalTransitMin += segFromLunch.durationMinutes;
          totalMeters += segFromLunch.distanceMeters;

          stops.add(ItineraryStop(
            order: stops.length + 1,
            place: lunchStop.place,
            startTime: lunchStartStr,
            endTime: lunchEndStr,
            isLunch: true,
            transitToNext: segFromLunch,
          ));

          currentMinutes += segFromLunch.durationMinutes;
          lunchInjected = true;
          lastPlace = lunchStop.place;
        }
      }

      // Add current sightseeing stop
      final startStr = _formatMinutes(currentMinutes);
      currentMinutes += currentPlace.durationMin;
      final endStr = _formatMinutes(currentMinutes);
      totalVisitMin += currentPlace.durationMin;

      TravelSegment? segToNext;
      if (i < places.length - 1) {
        final nextPlace = places[i + 1];
        segToNext = estimateSegment(currentPlace, nextPlace);
        totalTransitMin += segToNext.durationMinutes;
        totalMeters += segToNext.distanceMeters;
        currentMinutes += segToNext.durationMinutes;
      }

      stops.add(ItineraryStop(
        order: stops.length + 1,
        place: currentPlace,
        startTime: startStr,
        endTime: endStr,
        isLunch: false,
        transitToNext: segToNext,
      ));

      lastPlace = currentPlace;
    }

    return ItineraryDay(
      dayNumber: dayNumber,
      stops: stops,
      totalVisitMinutes: totalVisitMin,
      totalTransitMinutes: totalTransitMin,
      totalDistanceMeters: totalMeters,
    );
  }

  ItineraryStop? _findBestLunchStop({
    required Place nearPlace,
    required List<Place> lunchCandidates,
    required Set<String> usedLunchIds,
    required int currentMinutes,
    required int order,
  }) {
    if (lunchCandidates.isEmpty) return null;

    Place? bestLunch;
    int minDist = 999999999;

    for (final lunch in lunchCandidates) {
      if (usedLunchIds.contains(lunch.id)) continue;
      final dist = calculateDistanceMeters(
        nearPlace.lat,
        nearPlace.lon,
        lunch.lat,
        lunch.lon,
      );
      if (dist < minDist) {
        minDist = dist;
        bestLunch = lunch;
      }
    }

    bestLunch ??= lunchCandidates.first;

    usedLunchIds.add(bestLunch.id);

    return ItineraryStop(
      order: order,
      place: bestLunch,
      startTime: _formatMinutes(currentMinutes),
      endTime: _formatMinutes(currentMinutes + bestLunch.durationMin),
      isLunch: true,
    );
  }

  static String _formatMinutes(int minutes) {
    final int h = (minutes ~/ 60) % 24;
    final int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
