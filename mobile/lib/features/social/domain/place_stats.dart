/// Community statistics for a place, as consolidated by the One Tour API.
class PlaceStats {
  final String placeId;
  final int likesCount;
  final double ratingAvg;
  final int ratingCount;
  final double score;
  final int? rankState;
  final int? rankCity;

  const PlaceStats({
    required this.placeId,
    required this.likesCount,
    required this.ratingAvg,
    required this.ratingCount,
    required this.score,
    this.rankState,
    this.rankCity,
  });

  factory PlaceStats.fromJson(Map<String, dynamic> m) {
    return PlaceStats(
      placeId: m['place_id'].toString(),
      likesCount: (m['likes_count'] as num?)?.toInt() ?? 0,
      ratingAvg: (m['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (m['rating_count'] as num?)?.toInt() ?? 0,
      score: (m['score'] as num?)?.toDouble() ?? 0,
      rankState: (m['rank_state'] as num?)?.toInt(),
      rankCity: (m['rank_city'] as num?)?.toInt(),
    );
  }
}

/// In-memory view of the latest community stats (loaded from the local cache at
/// startup and refreshed from the API). Models read from here so that no
/// screen ever shows made-up ratings, likes or rankings.
class SocialStatsRegistry {
  static final SocialStatsRegistry instance = SocialStatsRegistry._();
  SocialStatsRegistry._();

  Map<String, PlaceStats> _byId = const {};

  PlaceStats? of(String placeId) => _byId[placeId];

  void replaceAll(Iterable<PlaceStats> stats) {
    _byId = {for (final s in stats) s.placeId: s};
  }

  void clear() => _byId = const {};
}
