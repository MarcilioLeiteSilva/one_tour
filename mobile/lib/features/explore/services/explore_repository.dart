import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
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

            return CityModel(
              id: slug,
              name: m['nome'] ?? 'Cidade',
              tag: m['tag'] ?? 'Destino Turístico',
              imageUrl: _getCityImageUrl(slug),
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
  }

  /// Retrieve attractions for state/city (from PocketBase with offline fallback)
  Future<List<AttractionModel>> getAttractions({String uf = 'PE', String? citySlug}) async {
    final normalizedUf = uf.toUpperCase().trim();

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

        if (items.isNotEmpty) {
          final list = items.map((item) {
            final m = item as Map<String, dynamic>;
            final slug = (m['slug'] ?? m['id'] ?? '').toString();
            final cSlug = (m['cidade_slug'] ?? '').toString();

            return AttractionModel(
              id: slug,
              name: m['nome'] ?? 'Atração',
              cityId: cSlug,
              cityName: MockPeData.cityNameFromSlug(cSlug),
              category: m['categoria'] ?? 'Turismo',
              imageUrl: _getAttractionImageUrl(slug),
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
          }).toList();

          debugPrint('🌐 [ExploreRepository] Carregadas ${list.length} atrações do PocketBase VPS!');
          return _enrichWithSocialStats(list);
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [ExploreRepository] Falha ao consultar atrações na VPS ($e). Usando SQLite local.');
    }

    // Fallback: SQLite POI Catalog
    final fallbackList = (citySlug != null && citySlug.isNotEmpty)
        ? await MockPeData.getAttractionsForCity(citySlug)
        : await MockPeData.getAllCuratedAttractions();

    return _enrichWithSocialStats(fallbackList);
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
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
      case 'olinda':
        return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80';
      case 'carneiros':
        return 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=80';
      case 'noronha':
        return 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80';
      case 'recife':
      default:
        return 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=800&q=80';
    }
  }

  static String _getAttractionImageUrl(String slug) {
    switch (slug.toLowerCase()) {
      case 'piscinas_porto':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
      case 'alto_da_se':
        return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80';
      case 'igrejinha_carneiros':
        return 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=800&q=80';
      case 'baia_do_sancho':
        return 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80';
      case 'marco_zero':
      default:
        return 'https://images.unsplash.com/photo-1680788842764-b5c9bc78ce59?auto=format&fit=crop&w=800&q=80';
    }
  }
}
