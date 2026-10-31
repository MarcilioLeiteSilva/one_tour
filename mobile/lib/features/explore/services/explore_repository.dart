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
        // Jangadas típicas nas piscinas naturais de Porto de Galinhas
        return 'https://images.unsplash.com/photo-1590523277543-a94d2e4eb00b?auto=format&fit=crop&w=1000&q=80';
      case 'olinda':
        // Alto da Sé com casarios coloniais e vista panorâmica de Olinda
        return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1000&q=80';
      case 'carneiros':
        // Capela de São Benedito e coqueirais da Praia dos Carneiros
        return 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=1000&q=80';
      case 'noronha':
        // Baía do Sancho em Fernando de Noronha (falésias e águas esmeralda)
        return 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=1000&q=80';
      case 'maceio':
        // Orla cinematográfica e jangadas da Praia de Pajuçara em Maceió
        return 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1000&q=80';
      case 'maragogi':
        // Piscinas naturais Galés de Maragogi em alto-mar (águas turquesas)
        return 'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?auto=format&fit=crop&w=1000&q=80';
      case 'milagres':
        // Rota Ecológica dos Milagres e mar verde-esmeralda da Praia do Toque
        return 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=1000&q=80';
      case 'salvador':
        return 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=1000&q=80';
      case 'fortaleza':
        return 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1000&q=80';
      case 'natal':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1000&q=80';
      case 'joao_pessoa':
        return 'https://images.unsplash.com/photo-1509233725247-49e657c54213?auto=format&fit=crop&w=1000&q=80';
      case 'recife':
      default:
        // Praça do Marco Zero e Rio Capibaribe em Recife Antigo
        return 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=1000&q=80';
    }
  }

  static String _getAttractionImageUrl(String slug) {
    switch (slug.toLowerCase()) {
      case 'piscinas_porto':
        return 'https://images.unsplash.com/photo-1590523277543-a94d2e4eb00b?auto=format&fit=crop&w=1000&q=80';
      case 'muro_alto':
        return 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=1000&q=80';
      case 'alto_da_se':
        return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1000&q=80';
      case 'igrejinha_carneiros':
      case 'capela_sao_benedito':
        return 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=1000&q=80';
      case 'baia_do_sancho':
        return 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=1000&q=80';
      case 'morro_dois_irmaos':
        return 'https://images.unsplash.com/photo-1589556264800-08ae9e129a8c?auto=format&fit=crop&w=1000&q=80';
      case 'piscinas_pajucara':
      case 'praia_pajucara':
        return 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1000&q=80';
      case 'farol_ponta_verde':
        return 'https://images.unsplash.com/photo-1509233725247-49e657c54213?auto=format&fit=crop&w=1000&q=80';
      case 'praia_do_frances':
      case 'praia_frances':
        return 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1000&q=80';
      case 'gales_maragogi':
        return 'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?auto=format&fit=crop&w=1000&q=80';
      case 'antunes_maragogi':
        return 'https://images.unsplash.com/photo-1515238152791-8216bfdf89a7?auto=format&fit=crop&w=1000&q=80';
      case 'praia_do_toque':
        return 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=1000&q=80';
      case 'praia_ipioca':
        return 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1000&q=80';
      case 'massagueira_gastronomia':
        return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1000&q=80';
      case 'cais_do_sertao':
        return 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=1000&q=80';
      case 'marco_zero':
      default:
        return 'https://images.unsplash.com/photo-1680788842764-b5c9bc78ce59?auto=format&fit=crop&w=1000&q=80';
    }
  }
}
