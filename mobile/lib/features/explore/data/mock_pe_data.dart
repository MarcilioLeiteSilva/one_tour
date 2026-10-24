import '../../social/domain/place_stats.dart';
import '../../trip_planner/domain/itinerary_models.dart';
import '../../trip_planner/services/local_db_service.dart';

class CityModel {
  final String id;
  final String name;
  final String tag;
  final String imageUrl;
  final String description;
  final int attractionsCount;
  final String packageSize;
  final bool isDownloaded;

  const CityModel({
    required this.id,
    required this.name,
    required this.tag,
    required this.imageUrl,
    required this.description,
    required this.attractionsCount,
    required this.packageSize,
    this.isDownloaded = false,
  });
}

class AttractionModel {
  final String id;
  final String name;
  final String cityId;
  final String cityName;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final int likesCount;
  final int rankPosition;
  final int durationMinutes;
  final bool isMustSee;
  final bool isKidFriendly;
  final String description;
  final double lat;
  final double lon;

  const AttractionModel({
    required this.id,
    required this.name,
    required this.cityId,
    required this.cityName,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.likesCount,
    required this.rankPosition,
    required this.durationMinutes,
    this.isMustSee = false,
    this.isKidFriendly = false,
    required this.description,
    required this.lat,
    required this.lon,
  });

  AttractionModel copyWith({
    String? id,
    String? name,
    String? cityId,
    String? cityName,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviewsCount,
    int? likesCount,
    int? rankPosition,
    int? durationMinutes,
    bool? isMustSee,
    bool? isKidFriendly,
    String? description,
    double? lat,
    double? lon,
  }) {
    return AttractionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      likesCount: likesCount ?? this.likesCount,
      rankPosition: rankPosition ?? this.rankPosition,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isMustSee: isMustSee ?? this.isMustSee,
      isKidFriendly: isKidFriendly ?? this.isKidFriendly,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}

class MockPeData {
  static const List<CityModel> cities = [
    CityModel(
      id: 'recife',
      name: 'Recife',
      tag: 'Capital Multicultural',
      imageUrl: 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=800&q=80',
      description: 'Capital dos rios e pontes, berço do frevo, patrimônio histórico e gastronomia premiada.',
      attractionsCount: 38,
      packageSize: '14 MB',
      isDownloaded: true,
    ),
    CityModel(
      id: 'porto_de_galinhas',
      name: 'Porto de Galinhas',
      tag: 'Piscinas Naturais & Jangadas',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      description: 'Eleita diversas vezes a melhor praia do Brasil, famosa pelas águas cristalinas mornas e recifes de corais.',
      attractionsCount: 24,
      packageSize: '9 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'olinda',
      name: 'Olinda',
      tag: 'Patrimônio Histórico da Humanidade',
      imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
      description: 'Ladeiras históricas, casarios coloniais coloridos, igrejas barrocas e a vista panorâmica do Alto da Sé.',
      attractionsCount: 22,
      packageSize: '8 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'carneiros',
      name: 'Praia dos Carneiros',
      tag: 'Paraíso dos Coqueirais',
      imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=80',
      description: 'Igrejinha icônica do século XVIII à beira-mar, mar calmo de cor esmeralda e passeios de catamarã.',
      attractionsCount: 16,
      packageSize: '7 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'noronha',
      name: 'Fernando de Noronha',
      tag: 'Santuário Ecológico Mundial',
      imageUrl: 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80',
      description: 'Arquipélago vulcânico com a Baía do Sancho, golfinhos rotadores, mergulho e natureza preservada.',
      attractionsCount: 28,
      packageSize: '12 MB',
      isDownloaded: false,
    ),
  ];

  static const List<AttractionModel> topAttractions = [
    AttractionModel(
      id: 'marco_zero',
      name: 'Praça do Marco Zero',
      cityId: 'recife',
      cityName: 'Recife',
      category: 'Cultura & História',
      imageUrl: 'https://images.unsplash.com/photo-1680788842764-b5c9bc78ce59?auto=format&fit=crop&w=800&q=80',
      rating: 4.9,
      reviewsCount: 2840,
      likesCount: 6120,
      rankPosition: 1,
      durationMinutes: 90,
      isMustSee: true,
      isKidFriendly: true,
      description: 'Ponto inicial de contagem das distâncias de Pernambuco. Vista para o Parque das Esculturas e rio Capibaribe.',
      lat: -8.0631,
      lon: -34.8711,
    ),
    AttractionModel(
      id: 'piscinas_porto',
      name: 'Piscinas Naturais de Porto',
      cityId: 'porto_de_galinhas',
      cityName: 'Porto de Galinhas',
      category: 'Praias & Litoral',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      rating: 4.9,
      reviewsCount: 3950,
      likesCount: 8400,
      rankPosition: 2,
      durationMinutes: 120,
      isMustSee: true,
      isKidFriendly: true,
      description: 'Passeio tradicional de jangada até os recifes repletos de peixes coloridos em águas mornas.',
      lat: -8.5042,
      lon: -35.0028,
    ),
    AttractionModel(
      id: 'alto_da_se',
      name: 'Alto da Sé e Mirante',
      cityId: 'olinda',
      cityName: 'Olinda',
      category: 'Cultura & História',
      imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
      rating: 4.8,
      reviewsCount: 2190,
      likesCount: 4890,
      rankPosition: 3,
      durationMinutes: 75,
      isMustSee: true,
      isKidFriendly: true,
      description: 'Vista deslumbrante das torres de Olinda com o skyline do Recife ao fundo e as melhores tapiocas do Brasil.',
      lat: -8.0139,
      lon: -34.8519,
    ),
    AttractionModel(
      id: 'igrejinha_carneiros',
      name: 'Capela de São Benedito',
      cityId: 'carneiros',
      cityName: 'Praia dos Carneiros',
      category: 'Praias & Litoral',
      imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=80',
      rating: 4.9,
      reviewsCount: 1870,
      likesCount: 5300,
      rankPosition: 4,
      durationMinutes: 60,
      isMustSee: true,
      isKidFriendly: true,
      description: 'A capela mais fotografada do Brasil, construída no século XVIII entre coqueiros à beira da maré.',
      lat: -8.7042,
      lon: -35.0883,
    ),
    AttractionModel(
      id: 'cais_do_sertao',
      name: 'Museu Cais do Sertão',
      cityId: 'recife',
      cityName: 'Recife',
      category: 'Cultura & História',
      imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
      rating: 4.8,
      reviewsCount: 1650,
      likesCount: 3740,
      rankPosition: 5,
      durationMinutes: 120,
      isMustSee: true,
      isKidFriendly: true,
      description: 'Um dos museus mais modernos da América Latina, celebrando a riqueza e a força da cultura sertaneja e Luiz Gonzaga.',
      lat: -8.0617,
      lon: -34.8706,
    ),
  ];

  static String cityNameFromSlug(String slug) {
    switch (slug.toLowerCase().trim()) {
      case 'porto_de_galinhas':
        return 'Porto de Galinhas';
      case 'carneiros':
        return 'Praia dos Carneiros';
      case 'noronha':
        return 'Fernando de Noronha';
      case 'olinda':
        return 'Olinda';
      case 'recife':
      default:
        return 'Recife';
    }
  }

  /// Dynamically load attractions for a city from the curated SQLite POI catalog
  static Future<List<AttractionModel>> getAttractionsForCity(String citySlug) async {
    final places = await LocalDbService.instance.getPlacesForCity(citySlug);
    return places.map((p) => p.toAttractionModel()).toList();
  }

  /// Retrieve all curated attractions across all polo destinations
  static Future<List<AttractionModel>> getAllCuratedAttractions() async {
    final recife = await getAttractionsForCity('recife');
    final porto = await getAttractionsForCity('porto_de_galinhas');
    final carneiros = await getAttractionsForCity('carneiros');
    final noronha = await getAttractionsForCity('noronha');
    final olinda = await getAttractionsForCity('olinda');

    final all = [...recife, ...porto, ...olinda, ...carneiros, ...noronha];
    all.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    return all;
  }
}

extension PlaceToAttraction on Place {
  AttractionModel toAttractionModel() {
    final stats = SocialStatsRegistry.instance.of(id);
    return AttractionModel(
      id: id,
      name: name,
      cityId: citySlug,
      cityName: MockPeData.cityNameFromSlug(citySlug),
      category: category,
      imageUrl: imageUrl,
      rating: (stats != null && stats.ratingCount > 0) ? stats.ratingAvg : ratingAvg,
      reviewsCount: (stats != null && stats.ratingCount > 0) ? stats.ratingCount : ratingCount,
      likesCount: (stats != null && stats.likesCount > 0) ? stats.likesCount : likesCount,
      rankPosition: (stats != null && stats.rankState != null && stats.rankState! > 0)
          ? stats.rankState!
          : rankPosicao,
      durationMinutes: durationMin,
      isMustSee: mustSee,
      isKidFriendly: kidFriendly,
      description: description,
      lat: lat,
      lon: lon,
    );
  }
}
