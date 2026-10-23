import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/house_ad_model.dart';

final houseAdsServiceProvider = Provider<HouseAdsService>((ref) {
  return HouseAdsService.instance;
});

final houseAdsByPositionProvider =
    FutureProvider.family<List<HouseAdModel>, HouseAdQuery>((ref, query) async {
  final service = ref.read(houseAdsServiceProvider);
  return service.getAds(
    uf: query.uf,
    city: query.city,
    position: query.position,
  );
});

class HouseAdQuery {
  final String uf;
  final String? city;
  final String? position;

  const HouseAdQuery({
    required this.uf,
    this.city,
    this.position,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseAdQuery &&
          runtimeType == other.runtimeType &&
          uf == other.uf &&
          city == other.city &&
          position == other.position;

  @override
  int get hashCode => Object.hash(uf, city, position);
}

class HouseAdsService {
  static final HouseAdsService instance = HouseAdsService._internal();
  HouseAdsService._internal();

  // Curated offline-first catalog of house ads and cross-promotions
  final List<HouseAdModel> _offlineCatalog = const [
    // 1. Cross-promotion: Tour Paraíba
    HouseAdModel(
      id: 'cross_pb_litoral',
      type: 'cross_promotion',
      title: 'Conheça o App Tour Paraíba',
      subtitle: 'Explore as praias de Tambaú, Cabo Branco e o Centro Histórico de João Pessoa.',
      tag: 'REDE ONE TOUR • VIZINHO',
      imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
      actionLabel: 'Baixar App Grátis',
      targetUrl: 'https://onetour.app/pb',
      targetUf: 'PE',
      position: 'attraction_banner',
    ),
    // 2. Patrocinador Local: Catamarã Recife & Olinda
    HouseAdModel(
      id: 'sponsor_catamara_recife',
      type: 'direct_sponsor',
      title: 'Passeio de Catamarã pelos Rios do Recife',
      subtitle: 'Navegue sob as pontes históricas do Capibaribe com guia ao vivo e pôr do sol.',
      tag: 'EXPERIÊNCIA RECOMENDADA',
      imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
      actionLabel: 'Reservar com 15% OFF',
      targetUrl: 'https://catamarantours.com.br?ref=onetour_pe',
      targetUf: 'PE',
      position: 'home_card',
    ),
    // 3. Patrocinador Local: Pousada em Porto de Galinhas
    HouseAdModel(
      id: 'sponsor_pousada_porto',
      type: 'direct_sponsor',
      title: 'Pousada Pé na Areia • Porto de Galinhas',
      subtitle: 'Piscinas naturais na porta do quarto, café da manhã regional e transfer.',
      tag: 'ONDE SE HOSPEDAR',
      imageUrl: 'https://images.unsplash.com/photo-1582650625119-3a31f8418b7d?auto=format&fit=crop&w=800&q=80',
      actionLabel: 'Ver Tarifas Especiais',
      targetUrl: 'https://tabapitanga.com.br?ref=onetour_pe',
      targetUf: 'PE',
      position: 'home_card',
    ),
    // 4. Intersticial Suave: Seguro Viagem
    HouseAdModel(
      id: 'interstitial_seguro_viagem',
      type: 'direct_sponsor',
      title: 'Seu Roteiro está Pronto!',
      subtitle: 'Viaje tranquilo pelo Nordeste com assistência médica 24h e cobertura de bagagem.',
      tag: 'PARCEIRO OFICIAL ONE TOUR',
      imageUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80',
      actionLabel: 'Cotar Seguro Viagem',
      targetUrl: 'https://seguro.onetour.app?ref=export_trip',
      targetUf: 'PE',
      position: 'interstitial',
    ),
    // 5. Cross-promotion: Tour Alagoas
    HouseAdModel(
      id: 'cross_al_maragogi',
      type: 'cross_promotion',
      title: 'Viaje para Alagoas • Tour Alagoas',
      subtitle: 'Galés de Maragogi e as águas mornas de São Miguel dos Milagres 100% offline.',
      tag: 'REDE ONE TOUR • ALAGOAS',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      actionLabel: 'Abrir Guia de Alagoas',
      targetUrl: 'https://onetour.app/al',
      targetUf: 'PE',
      position: 'attraction_banner',
    ),
  ];

  /// Get ads filtered by UF, city and position (100% offline resilient)
  Future<List<HouseAdModel>> getAds({
    required String uf,
    String? city,
    String? position,
  }) async {
    final normalizedUf = uf.toUpperCase();

    final matches = _offlineCatalog.where((ad) {
      if (ad.targetUf != normalizedUf) return false;
      if (position != null && ad.position != position) return false;
      return true;
    }).toList();

    return matches;
  }

  /// Track impression (offline-first telemetry)
  Future<void> trackImpression(HouseAdModel ad, {String? city}) async {
    debugPrint('📊 [Telemetry] Impression recorded for Ad: ${ad.id} (pos: ${ad.position})');
  }

  /// Track click (offline-first telemetry)
  Future<void> trackClick(HouseAdModel ad, {String? city}) async {
    debugPrint('🖱️ [Telemetry] Click recorded for Ad: ${ad.id} (url: ${ad.targetUrl})');
  }
}
