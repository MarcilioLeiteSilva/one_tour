enum TripPace {
  relaxed, // 2-3 paradas/dia
  moderate, // 3-4 paradas/dia
  intense; // 5-6 paradas/dia

  String get labelPt {
    switch (this) {
      case TripPace.relaxed:
        return 'Tranquilo';
      case TripPace.moderate:
        return 'Moderado';
      case TripPace.intense:
        return 'Intenso';
    }
  }
}

enum TripCompanion {
  solo,
  couple,
  family, // Ativa filtro prioritário kid-friendly
  friends;

  String get labelPt {
    switch (this) {
      case TripCompanion.solo:
        return 'Viajando Solo';
      case TripCompanion.couple:
        return 'Casal';
      case TripCompanion.family:
        return 'Família com Crianças';
      case TripCompanion.friends:
        return 'Grupo de Amigos';
    }
  }
}

class TripRequest {
  final String cityName;
  final int days;
  final TripPace pace;
  final TripCompanion companion;
  final Set<String> interests;

  const TripRequest({
    required this.cityName,
    this.days = 3,
    this.pace = TripPace.moderate,
    this.companion = TripCompanion.couple,
    this.interests = const {'praias', 'cultura', 'gastronomia'},
  });
}
