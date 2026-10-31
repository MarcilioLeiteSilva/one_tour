import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../social/domain/place_stats.dart';
import '../../social/services/social_service.dart';
import '../../trip_planner/services/local_db_service.dart';
import '../data/mock_pe_data.dart';

class ExploreRepository {
  static final ExploreRepository instance = ExploreRepository._internal();
  ExploreRepository._internal();

  final http.Client _client = http.Client();

  /// Retrieve cities for the given state UF (from PocketBase with offline fallback)
  Future<List<CityModel>> getCities({String uf = 'PE'}) async {
    final normalizedUf = uf.toUpperCase().trim();

    try {
      final url = Uri.parse(
        '$kBackendBaseUrl/api/collections/cidades/records?filter=(estado_sigla="$normalizedUf")',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        if (items.isNotEmpty) {
          final downloadedSet = await LocalDbService.instance.getDownloadedCities();

          final cities = items.map((item) {
            final m = item as Map<String, dynamic>;
            final slug = (m['slug'] ?? m['id'] ?? '').toString();
            final isDl = downloadedSet.contains(slug);

            final dynamicImg = (m['image_url'] ?? m['imagem'] ?? '').toString().trim();
            return CityModel(
              id: slug,
              name: m['nome'] ?? 'Cidade',
              tag: m['tag'] ?? 'Destino Turístico',
              imageUrl: dynamicImg.isNotEmpty ? dynamicImg : _getCityImageUrl(slug),
              description: m['descricao_pt'] ?? '',
              attractionsCount: slug == 'recife'
                  ? 38
                  : (slug == 'noronha' ? 28 : (slug == 'porto_de_galinhas' ? 24 : 16)),
              packageSize: m['package_size'] ?? '10 MB',
              isDownloaded: isDl,
            );
          }).toList();

          debugPrint('🌐 [ExploreRepository] Carregadas ${cities.length} cidades reais do PocketBase VPS!');
          return cities;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [ExploreRepository] Falha de conexão com VPS ($e). Usando banco local SQLite.');
    }

    // Fallback: cidades do catálogo local com status de download real do SQLite
    final downloadedSet = await LocalDbService.instance.getDownloadedCities();

    if (normalizedUf == 'AL') {
      return [
        CityModel(
          id: 'maceio',
          name: 'Maceió',
          tag: 'Caribe Brasileiro & Orla das Águas Claras',
          imageUrl: _getCityImageUrl('maceio'),
          description: 'Capital de praias urbanas cinematográficas (Pajuçara, Ponta Verde), piscinas naturais e gastronomia de frutos do mar.',
          attractionsCount: 20,
          packageSize: '11 MB',
          isDownloaded: downloadedSet.contains('maceio') || downloadedSet.contains('al'),
        ),
        CityModel(
          id: 'maragogi',
          name: 'Maragogi',
          tag: 'Galés & Piscinas Naturais',
          imageUrl: _getCityImageUrl('maragogi'),
          description: 'O coração da Costa dos Corais, célebre pelas Galés de águas mornas e translúcidas em alto mar.',
          attractionsCount: 16,
          packageSize: '8 MB',
          isDownloaded: downloadedSet.contains('maragogi'),
        ),
        CityModel(
          id: 'milagres',
          name: 'São Miguel dos Milagres',
          tag: 'Rota Ecológica & Mar de Esmeralda',
          imageUrl: _getCityImageUrl('milagres'),
          description: 'Charme rústico, praias desertas paradisíacas (Praia do Toque), coqueirais infinitos e santuário do peixe-boi.',
          attractionsCount: 12,
          packageSize: '6 MB',
          isDownloaded: downloadedSet.contains('milagres'),
        ),
      ];
    } else if (normalizedUf == 'PE') {
      return MockPeData.cities.map((c) {
        return CityModel(
          id: c.id,
          name: c.name,
          tag: c.tag,
          imageUrl: c.imageUrl,
          description: c.description,
          attractionsCount: c.attractionsCount,
          packageSize: c.packageSize,
          isDownloaded: downloadedSet.contains(c.id),
        );
      }).toList();
    } else {
      final flavorConfig = FlavorConfig.of(AppFlavor.fromString(normalizedUf));
      final slug = flavorConfig.capital.toLowerCase().replaceAll(' ', '_');
      return [
        CityModel(
          id: slug,
          name: flavorConfig.capital,
          tag: flavorConfig.slogan,
          imageUrl: _getCityImageUrl(slug),
          description: '${flavorConfig.appName}: explore os principais pontos turísticos, rotas e gastronomia de ${flavorConfig.stateName}.',
          attractionsCount: 16,
          packageSize: '10 MB',
          isDownloaded: downloadedSet.contains(slug) || downloadedSet.contains(normalizedUf.toLowerCase()),
        ),
      ];
    }
  }

  /// Retrieve attractions for state/city (from PocketBase with offline fallback)
  Future<List<AttractionModel>> getAttractions({String uf = 'PE', String? citySlug}) async {
    final normalizedUf = uf.toUpperCase().trim();

    // 1. Carrega catálogo local curado correspondente ao estado
    final Map<String, AttractionModel> mergedMap = {};

    if (normalizedUf == 'PE') {
      final localCatalog = (citySlug != null && citySlug.isNotEmpty)
          ? await MockPeData.getAttractionsForCity(citySlug)
          : await MockPeData.getAllCuratedAttractions();
      for (final att in localCatalog) {
        mergedMap[att.id] = att;
      }
    } else if (normalizedUf == 'AL') {
      final alCatalog = await MockPeData.getAttractionsForAlagoas(citySlug: citySlug);
      for (final att in alCatalog) {
        mergedMap[att.id] = att;
      }
    } else {
      final stateCatalog = await MockPeData.getAttractionsForCity(citySlug ?? normalizedUf.toLowerCase());
      for (final att in stateCatalog) {
        mergedMap[att.id] = att;
      }
    }

    // 2. Mescla com eventuais atualizações vindas da VPS PocketBase
    try {
      String filter = 'uf="$normalizedUf"';
      if (citySlug != null && citySlug.isNotEmpty) {
        filter += '&&cidade_slug="$citySlug"';
      }

      final url = Uri.parse(
        '$kBackendBaseUrl/api/collections/atracoes/records?filter=($filter)&sort=-score',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final m = item as Map<String, dynamic>;
          final slug = (m['slug'] ?? m['id'] ?? '').toString();
          final cSlug = (m['cidade_slug'] ?? '').toString();

          final dynamicAttImg = (m['image_url'] ?? m['imagem'] ?? '').toString().trim();
          mergedMap[slug] = AttractionModel(
            id: slug,
            name: m['nome'] ?? 'Atração',
            cityId: cSlug,
            cityName: MockPeData.cityNameFromSlug(cSlug),
            category: m['categoria'] ?? 'Turismo',
            imageUrl: dynamicAttImg.isNotEmpty ? dynamicAttImg : _getAttractionImageUrl(slug),
            rating: (m['rating_avg'] as num?)?.toDouble() ?? 4.8,
            reviewsCount: (m['rating_count'] as num?)?.toInt() ?? 1200,
            likesCount: (m['likes_count'] as num?)?.toInt() ?? 3400,
            rankPosition: (m['rank_posicao'] as num?)?.toInt() ?? 1,
            durationMinutes: (m['duracao_min'] as num?)?.toInt() ?? 90,
            isMustSee: m['must_see'] == true,
            isKidFriendly: m['kid_friendly'] == true,
            description: m['descricao_pt'] ?? '',
            lat: (m['lat'] as num?)?.toDouble() ?? -8.0631,
            lon: (m['lon'] as num?)?.toDouble() ?? -34.8711,
          );
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [ExploreRepository] VPS offline ou lenta ($e). Usando catálogo local.');
    }

    return _enrichWithSocialStats(mergedMap.values.toList());
  }

  List<AttractionModel> _enrichWithSocialStats(List<AttractionModel> items) {
    return items.map((att) {
      final stats = SocialStatsRegistry.instance.of(att.id);
      if (stats == null) return att;
      return att.copyWith(
        rating: stats.ratingCount > 0 ? stats.ratingAvg : att.rating,
        reviewsCount: stats.ratingCount > 0 ? stats.ratingCount : att.reviewsCount,
        likesCount: stats.likesCount > 0 ? stats.likesCount : att.likesCount,
        rankPosition: (stats.rankState != null && stats.rankState! > 0)
            ? stats.rankState!
            : att.rankPosition,
      );
    }).toList();
  }

  /// Toggle Social Like with Offline Queue and Online Sync
  Future<bool> toggleLike(String attractionId) async {
    final isLikedNow = await LocalDbService.instance.toggleLike(attractionId);
    await SocialService.instance.recordLike(attractionId, liked: isLikedNow);
    return isLikedNow;
  }

  static String _getCityImageUrl(String slug) {
    switch (slug.toLowerCase()) {
      case 'porto_de_galinhas':
        // Wikimedia Commons: Piscina natural na Praia de Porto de Galinhas, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg';
      case 'olinda':
        // Wikimedia Commons: Centro Histórico de Olinda, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg/1280px-Centro_Hist%C3%B3rico_de_Olinda_-_Pernambuco.jpg';
      case 'carneiros':
        // Wikimedia Commons: Praia dos Carneiros, Tamandaré, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg/1280px-Praia_dos_Carneiros%2C_Tamandar%C3%A9%2C_PE.jpg';
      case 'noronha':
        // Wikimedia Commons: Baía do Sancho em Fernando de Noronha
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg';
      case 'maceio':
        // Wikimedia Commons: Orla de Maceió (Ponta Verde / Pajuçara)
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Orla_de_Macei%C3%B3_2023.jpg/1280px-Orla_de_Macei%C3%B3_2023.jpg';
      case 'maragogi':
        // Wikimedia Commons: Praia de Maragogi, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Maragogi_beach_tourist.jpg/1280px-Maragogi_beach_tourist.jpg';
      case 'milagres':
        // Wikimedia Commons: São Miguel dos Milagres, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg/1280px-Beach_Sao_Miguel_Dos_Milagres_Alagoas_%28140207749%29.jpeg';
      case 'salvador':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Pelourinho_-_Salvador_-_Bahia_-_Brasil.jpg/1280px-Pelourinho_-_Salvador_-_Bahia_-_Brasil.jpg';
      case 'fortaleza':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Praia_de_Iracema_-_Fortaleza%2C_Cear%C3%A1%2C_Brasil.jpg/1280px-Praia_de_Iracema_-_Fortaleza%2C_Cear%C3%A1%2C_Brasil.jpg';
      case 'natal':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Morro_do_Careca_Ponta_Negra_Natal_RN_Brazil.jpg/1280px-Morro_do_Careca_Ponta_Negra_Natal_RN_Brazil.jpg';
      case 'joao_pessoa':
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Praia_de_Tambau_-_Joao_Pessoa_-_PB.jpg/1280px-Praia_de_Tambau_-_Joao_Pessoa_-_PB.jpg';
      case 'recife':
      default:
        // Wikimedia Commons: Praça do Marco Zero e Recife Antigo
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg';
    }
  }

  static String _getAttractionImageUrl(String slug) {
    switch (slug.toLowerCase()) {
      case 'piscinas_porto':
        // Wikimedia Commons: Piscinas naturais de Porto de Galinhas
        return 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg';
      case 'muro_alto':
        // Wikimedia Commons: Praia de Muro Alto, Ipojuca, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg';
      case 'pontal_maracaipe':
        // Wikimedia Commons: Pontal de Maracaípe, Ipojuca, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg/1280px-BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg';
      case 'alto_da_se':
        // Wikimedia Commons: Mirante e Alto da Sé, Olinda, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Mirante_da_Caixa_D%27%C3%81gua_do_Alto_da_S%C3%A9_-_Olinda%2C_Pernambuco%2C_Brasil.jpg/1280px-Mirante_da_Caixa_D%27%C3%81gua_do_Alto_da_S%C3%A9_-_Olinda%2C_Pernambuco%2C_Brasil.jpg';
      case 'igrejinha_carneiros':
      case 'capela_sao_benedito':
        // Wikimedia Commons: Capela de São Benedito, Carneiros, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Capela_S%C3%A3o_Benedito_-_Praia_de_Carneiros_-_Pernambuco.jpg/1280px-Capela_S%C3%A3o_Benedito_-_Praia_de_Carneiros_-_Pernambuco.jpg';
      case 'baia_do_sancho':
        // Wikimedia Commons: Baía do Sancho, Fernando de Noronha
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg';
      case 'morro_dois_irmaos':
        // Wikimedia Commons: Morro Dois Irmãos em Fernando de Noronha
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Morro_Dois_Irm%C3%A3os_em_Fernando_de_Noronha%2C_Pernambuco.jpg/1280px-Morro_Dois_Irm%C3%A3os_em_Fernando_de_Noronha%2C_Pernambuco.jpg';
      case 'piscinas_pajucara':
        // Wikimedia Commons: Jangadas nas piscinas de Pajuçara, Maceió
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Paju%C3%A7ara_em_Macei%C3%B3._%285700883183%29.jpg/1280px-Paju%C3%A7ara_em_Macei%C3%B3._%285700883183%29.jpg';
      case 'praia_pajucara':
        // Wikimedia Commons: Praia de Pajuçara, Maceió, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG/1280px-Praia_Paju%C3%A7ara_Macei%C3%B3_04_2015_3249.JPG';
      case 'farol_ponta_verde':
        // Wikimedia Commons: Farol da Ponta Verde, Maceió, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg';
      case 'praia_do_frances':
      case 'praia_frances':
        // Wikimedia Commons: Praia do Francês, Marechal Deodoro, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg/1280px-Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg';
      case 'gales_maragogi':
        // Wikimedia Commons: Piscinas naturais Galés de Maragogi, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Sargentinho_-_Piscinas_naturais_de_Maragogi_-_Alagoas.jpg/1280px-Sargentinho_-_Piscinas_naturais_de_Maragogi_-_Alagoas.jpg';
      case 'antunes_maragogi':
        // Wikimedia Commons: Praia de Antunes, Maragogi, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Marco_Ankosqui_Praia_de_Antunes_Maragogi-AL_%2840850130861%29.jpg/1280px-Marco_Ankosqui_Praia_de_Antunes_Maragogi-AL_%2840850130861%29.jpg';
      case 'praia_do_toque':
        // Wikimedia Commons: Praia do Toque, São Miguel dos Milagres, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Marco_Ankosqui_Praia_do_Toque_Sao_Miguel_Milagres-AL_%2839956457515%29.jpg/1280px-Marco_Ankosqui_Praia_do_Toque_Sao_Miguel_Milagres-AL_%2839956457515%29.jpg';
      case 'praia_gunga':
        // Wikimedia Commons: Praia do Gunga, Roteiro, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Praia_do_Gunga_%281%29_-_Alagoas.jpg/1280px-Praia_do_Gunga_%281%29_-_Alagoas.jpg';
      case 'massagueira_gastronomia':
        // Wikimedia Commons: Lagoa Manguaba e Polo Gastronômico da Massagueira, AL
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg';
      case 'cais_do_sertao':
        // Wikimedia Commons: Museu Cais do Sertão, Recife, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg';
      case 'instituto_brennand':
        // Wikimedia Commons: Instituto Ricardo Brennand, Recife, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/f/f5/Instituto_Ricardo_Brennand_-_Recife_%28crop%29.png';
      case 'oficina_brennand':
        // Wikimedia Commons: Oficina Francisco Brennand, Recife, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Oficina_de_Cer%C3%A2mica_Francisco_Brennand_%28foto3%29-_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Oficina_de_Cer%C3%A2mica_Francisco_Brennand_%28foto3%29-_Recife%2C_Pernambuco%2C_Brasil.jpg';
      case 'boa_viagem':
        // Wikimedia Commons: Praia de Boa Viagem, Recife, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Boa_Viagem%2C_Recife_%2820150717-DSC05419%29.jpg/1280px-Boa_Viagem%2C_Recife_%2820150717-DSC05419%29.jpg';
      case 'marco_zero':
      default:
        // Wikimedia Commons: Praça do Marco Zero, Recife, PE
        return 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg';
    }
  }
}
