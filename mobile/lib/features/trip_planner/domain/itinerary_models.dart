import 'dart:convert';
import 'trip_request.dart';

class Place {
  final String id;
  final String citySlug;
  final String name;
  final String category;
  final double lat;
  final double lon;
  final int durationMin;
  final int costLevel;
  final bool kidFriendly;
  final bool mustSee;
  final bool isLunch;
  final double score;
  final double ratingAvg;
  final int ratingCount;
  final int likesCount;
  final int rankPosicao;
  final String description;
  final String imageUrl;
  final String openingTime;
  final String closingTime;

  const Place({
    required this.id,
    required this.citySlug,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    required this.durationMin,
    this.costLevel = 1,
    this.kidFriendly = true,
    this.mustSee = false,
    this.isLunch = false,
    this.score = 90.0,
    this.ratingAvg = 4.8,
    this.ratingCount = 100,
    this.likesCount = 500,
    this.rankPosicao = 1,
    this.description = '',
    this.imageUrl = '',
    this.openingTime = '08:00',
    this.closingTime = '18:00',
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] as String? ?? '',
      citySlug: map['city_slug'] as String? ?? 'recife',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'cultura',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (map['lon'] as num?)?.toDouble() ?? 0.0,
      durationMin: (map['duration_min'] as num?)?.toInt() ?? 60,
      costLevel: (map['cost_level'] as num?)?.toInt() ?? 1,
      kidFriendly: (map['kid_friendly'] is int)
          ? (map['kid_friendly'] as int) == 1
          : (map['kid_friendly'] as bool? ?? true),
      mustSee: (map['must_see'] is int)
          ? (map['must_see'] as int) == 1
          : (map['must_see'] as bool? ?? false),
      isLunch: (map['is_lunch'] is int)
          ? (map['is_lunch'] as int) == 1
          : (map['is_lunch'] as bool? ?? false),
      score: (map['score'] as num?)?.toDouble() ?? 90.0,
      ratingAvg: (map['rating_avg'] as num?)?.toDouble() ?? 4.8,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 100,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 500,
      rankPosicao: (map['rank_posicao'] as num?)?.toInt() ?? 1,
      description: map['description'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      openingTime: map['opening_time'] as String? ?? '08:00',
      closingTime: map['closing_time'] as String? ?? '18:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_slug': citySlug,
      'name': name,
      'category': category,
      'lat': lat,
      'lon': lon,
      'duration_min': durationMin,
      'cost_level': costLevel,
      'kid_friendly': kidFriendly ? 1 : 0,
      'must_see': mustSee ? 1 : 0,
      'is_lunch': isLunch ? 1 : 0,
      'score': score,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
      'likes_count': likesCount,
      'rank_posicao': rankPosicao,
      'description': description,
      'image_url': imageUrl,
      'opening_time': openingTime,
      'closing_time': closingTime,
    };
  }
}

class TravelSegment {
  final int distanceMeters;
  final int durationMinutes;
  final bool isWalk;

  const TravelSegment({
    required this.distanceMeters,
    required this.durationMinutes,
    required this.isWalk,
  });

  String get labelFormatted {
    final distStr = distanceMeters < 1000
        ? '${distanceMeters}m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    if (isWalk) {
      return '🚶‍♂️ $durationMinutes min a pé ($distStr)';
    } else {
      return '🚗 $durationMinutes min de carro ($distStr)';
    }
  }

  factory TravelSegment.fromMap(Map<String, dynamic> map) {
    return TravelSegment(
      distanceMeters: (map['distanceMeters'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 5,
      isWalk: map['isWalk'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'distanceMeters': distanceMeters,
      'durationMinutes': durationMinutes,
      'isWalk': isWalk,
    };
  }
}

class ItineraryStop {
  final int order;
  final Place place;
  final String startTime;
  final String endTime;
  final bool isLunch;
  final TravelSegment? transitToNext;

  const ItineraryStop({
    required this.order,
    required this.place,
    required this.startTime,
    required this.endTime,
    this.isLunch = false,
    this.transitToNext,
  });

  ItineraryStop copyWith({
    TravelSegment? transitToNext,
  }) {
    return ItineraryStop(
      order: order,
      place: place,
      startTime: startTime,
      endTime: endTime,
      isLunch: isLunch,
      transitToNext: transitToNext ?? this.transitToNext,
    );
  }

  factory ItineraryStop.fromMap(Map<String, dynamic> map) {
    return ItineraryStop(
      order: (map['order'] as num?)?.toInt() ?? 1,
      place: Place.fromMap(map['place'] as Map<String, dynamic>),
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '10:30',
      isLunch: map['isLunch'] as bool? ?? false,
      transitToNext: map['transitToNext'] != null
          ? TravelSegment.fromMap(map['transitToNext'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'place': place.toMap(),
      'startTime': startTime,
      'endTime': endTime,
      'isLunch': isLunch,
      if (transitToNext != null) 'transitToNext': transitToNext!.toMap(),
    };
  }
}

class ItineraryDay {
  final int dayNumber;
  final List<ItineraryStop> stops;
  final int totalVisitMinutes;
  final int totalTransitMinutes;
  final int totalDistanceMeters;

  const ItineraryDay({
    required this.dayNumber,
    required this.stops,
    this.totalVisitMinutes = 0,
    this.totalTransitMinutes = 0,
    this.totalDistanceMeters = 0,
  });

  factory ItineraryDay.fromMap(Map<String, dynamic> map) {
    return ItineraryDay(
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      stops: (map['stops'] as List<dynamic>?)
              ?.map((s) => ItineraryStop.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      totalVisitMinutes: (map['totalVisitMinutes'] as num?)?.toInt() ?? 0,
      totalTransitMinutes: (map['totalTransitMinutes'] as num?)?.toInt() ?? 0,
      totalDistanceMeters: (map['totalDistanceMeters'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'stops': stops.map((s) => s.toMap()).toList(),
      'totalVisitMinutes': totalVisitMinutes,
      'totalTransitMinutes': totalTransitMinutes,
      'totalDistanceMeters': totalDistanceMeters,
    };
  }
}

class TripPlan {
  final String id;
  final String title;
  final String cityName;
  final int daysCount;
  final TripPace pace;
  final TripCompanion companion;
  final Set<String> interests;
  final List<ItineraryDay> days;
  final DateTime createdAt;

  const TripPlan({
    required this.id,
    required this.title,
    required this.cityName,
    required this.daysCount,
    required this.pace,
    required this.companion,
    required this.interests,
    required this.days,
    required this.createdAt,
  });

  int get totalStopsCount =>
      days.fold(0, (prev, day) => prev + day.stops.length);

  factory TripPlan.fromMap(Map<String, dynamic> map) {
    return TripPlan(
      id: map['id'] as String? ?? 'trip_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Roteiro Personalizado',
      cityName: map['cityName'] as String? ?? 'Recife',
      daysCount: (map['daysCount'] as num?)?.toInt() ?? 1,
      pace: TripPace.values.firstWhere(
        (p) => p.name == map['pace'],
        orElse: () => TripPace.moderate,
      ),
      companion: TripCompanion.values.firstWhere(
        (c) => c.name == map['companion'],
        orElse: () => TripCompanion.couple,
      ),
      interests: (map['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {'cultura', 'gastronomia'},
      days: (map['days'] as List<dynamic>?)
              ?.map((d) => ItineraryDay.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cityName': cityName,
      'daysCount': daysCount,
      'pace': pace.name,
      'companion': companion.name,
      'interests': interests.toList(),
      'days': days.map((d) => d.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());
  factory TripPlan.fromJson(String source) =>
      TripPlan.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
