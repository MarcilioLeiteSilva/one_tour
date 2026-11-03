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
      tag: 'PE • Capital Multicultural',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
      description: 'Capital dos rios e pontes, berço do frevo, patrimônio histórico e gastronomia premiada.',
      attractionsCount: 38,
      packageSize: '14 MB',
      isDownloaded: true,
    ),
    CityModel(
      id: 'porto_de_galinhas',
      name: 'Porto de Galinhas',
      tag: 'PE • Piscinas Naturais & Jangadas',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
      description: 'Eleita diversas vezes a melhor praia do Brasil, famosa pelas águas cristalinas mornas e recifes de corais.',
      attractionsCount: 24,
      packageSize: '9 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'olinda',
      name: 'Olinda',
      tag: 'PE • Patrimônio da Humanidade',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg',
      description: 'Ladeiras históricas, casarios coloniais coloridos, igrejas barrocas e a vista panorâmica do Alto da Sé.',
      attractionsCount: 22,
      packageSize: '8 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'carneiros',
      name: 'Praia dos Carneiros',
      tag: 'PE • Paraíso dos Coqueirais',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg',
      description: 'Igrejinha icônica do século XVIII à beira-mar, mar calmo de cor esmeralda e passeios de catamarã.',
      attractionsCount: 16,
      packageSize: '7 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'noronha',
      name: 'Fernando de Noronha',
      tag: 'PE • Santuário Ecológico',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      description: 'Arquipélago vulcânico com a Baía do Sancho, golfinhos rotadores, mergulho e natureza preservada.',
      attractionsCount: 28,
      packageSize: '12 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'maceio',
      name: 'Maceió',
      tag: 'AL • Caribe Brasileiro & Águas Claras',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg',
      description: 'Capital de praias urbanas cinematográficas (Pajuçara, Ponta Verde), piscinas naturais e gastronomia de frutos do mar.',
      attractionsCount: 20,
      packageSize: '11 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'maragogi',
      name: 'Maragogi',
      tag: 'AL • Galés & Piscinas Naturais',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg',
      description: 'O coração da Costa dos Corais, célebre pelas Galés de águas mornas e translúcidas em alto mar.',
      attractionsCount: 16,
      packageSize: '8 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'milagres',
      name: 'São Miguel dos Milagres',
      tag: 'AL • Rota Ecológica & Charme Rústico',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg/1280px-Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg',
      description: 'Charme rústico, praias desertas paradisíacas (Praia do Toque), coqueirais infinitos e santuário do peixe-boi.',
      attractionsCount: 12,
      packageSize: '6 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'salvador',
      name: 'Salvador',
      tag: 'BA • Berço da Cultura & Pelourinho',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Largo_do_Pelourinho_Salvador_2019-9754_%28cropped%29.jpg/1280px-Largo_do_Pelourinho_Salvador_2019-9754_%28cropped%29.jpg',
      description: 'Capital cultural com o Pelourinho colonial, Farol da Barra, culinária afro-baiana e praias históricas.',
      attractionsCount: 35,
      packageSize: '13 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'rio_de_janeiro',
      name: 'Rio de Janeiro',
      tag: 'RJ • Cidade Maravilhosa',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Cidade_Maravilhosa.jpg/1280px-Cidade_Maravilhosa.jpg',
      description: 'Cristo Redentor, Pão de Açúcar, praias de Copacabana e Ipanema e o charme carioca entre o mar e a serra.',
      attractionsCount: 42,
      packageSize: '16 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'sao_paulo',
      name: 'São Paulo',
      tag: 'SP • Metrópole Cultural & Gastronômica',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/65/Avenida_Paulista_Skyline_2012.jpg',
      description: 'Avenida Paulista, MASP, Parque Ibirapuera, alta gastronomia internacional e riqueza cultural 24 horas.',
      attractionsCount: 45,
      packageSize: '15 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'florianopolis',
      name: 'Florianópolis',
      tag: 'SC • Ilha da Magia & Praias',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Ponte_Hercilio_Luz_%2811719073825%29.jpg/1280px-Ponte_Hercilio_Luz_%2811719073825%29.jpg',
      description: 'Mais de 40 praias paradisíacas, Ponte Hercílio Luz, dunas da Joaquina e gastronomia de ostras frescas.',
      attractionsCount: 26,
      packageSize: '10 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'foz_do_iguacu',
      name: 'Foz do Iguaçu',
      tag: 'PR • Maravilha Natural do Mundo',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/f/f0/Cataratas027.jpg',
      description: 'As grandiosas Cataratas do Iguaçu, Parque das Aves, Usina de Itaipu e marco das três fronteiras.',
      attractionsCount: 18,
      packageSize: '9 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'gramado',
      name: 'Gramado & Canela',
      tag: 'RS • Charme da Serra Gaúcha',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Panorama_of_Centro_de_Gramado_at_night_%2824884860720%29.jpg/1280px-Panorama_of_Centro_de_Gramado_at_night_%2824884860720%29.jpg',
      description: 'Arquitetura europeia, Lago Negro, fábricas de chocolate artesanal, Cascata do Caracol e eventos de inverno.',
      attractionsCount: 22,
      packageSize: '8 MB',
      isDownloaded: false,
    ),
    CityModel(
      id: 'brasilia',
      name: 'Brasília',
      tag: 'DF • Patrimônio Modernista Mundial',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Brazilian_National_Congress.jpg/1280px-Brazilian_National_Congress.jpg',
      description: 'A arquitetura monumental de Oscar Niemeyer, Congresso Nacional, Catedral Metropolitana e Lago Paranoá.',
      attractionsCount: 20,
      packageSize: '9 MB',
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
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
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
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
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
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg',
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
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg',
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
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg',
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
    final s = slug.toLowerCase().trim();
    switch (s) {
      case 'porto_de_galinhas':
        return 'Porto de Galinhas';
      case 'carneiros':
        return 'Praia dos Carneiros';
      case 'noronha':
        return 'Fernando de Noronha';
      case 'olinda':
        return 'Olinda';
      case 'maceio':
        return 'Maceió';
      case 'maragogi':
        return 'Maragogi';
      case 'milagres':
        return 'São Miguel dos Milagres';
      case 'salvador':
        return 'Salvador';
      case 'fortaleza':
        return 'Fortaleza';
      case 'natal':
        return 'Natal';
      case 'joao_pessoa':
        return 'João Pessoa';
      case 'aracaju':
        return 'Aracaju';
      case 'sao_luis':
        return 'São Luís';
      case 'teresina':
        return 'Teresina';
      case 'recife':
        return 'Recife';
      default:
        if (s.isNotEmpty) {
          return s
              .split('_')
              .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ');
        }
        return 'Cidade';
    }
  }

  /// Dynamically load attractions for a city from the curated SQLite POI catalog
  static Future<List<AttractionModel>> getAttractionsForCity(String citySlug) async {
    final places = await LocalDbService.instance.getPlacesForCity(citySlug);
    return places.map((p) => p.toAttractionModel()).toList();
  }

  /// Retrieve curated attractions for Alagoas
  static Future<List<AttractionModel>> getAttractionsForAlagoas({String? citySlug}) async {
    final maceio = await getAttractionsForCity('maceio');
    if (citySlug == 'maceio') return maceio;
    return maceio;
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
