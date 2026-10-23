import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sql;
import '../domain/itinerary_models.dart';

/// Service managing offline user data in `user.sqlite` and offline POI packs in `pack.sqlite`.
class LocalDbService {
  sql.Database? _userDb;
  bool _isInitialized = false;

  // Fallback in-memory cache for fast access and test/mock compatibility
  final Map<String, TripPlan> _inMemorySavedTrips = {};
  final Set<String> _inMemoryLikes = {};
  final List<Map<String, dynamic>> _inMemoryReviews = [];

  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  bool get isInitialized => _isInitialized;

  /// Initialize user database
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final dbPath = await sql.getDatabasesPath();
      final path = p.join(dbPath, 'one_tour_user.sqlite');

      _userDb = await sql.openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // 1. Saved Trips table
          await db.execute('''
            CREATE TABLE saved_trips (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              city_name TEXT NOT NULL,
              days_count INTEGER NOT NULL,
              plan_json TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
          ''');

          // 2. User Likes table (Local + Sync queue)
          await db.execute('''
            CREATE TABLE user_likes (
              place_id TEXT PRIMARY KEY,
              created_at TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            );
          ''');

          // 3. User Reviews table (Local + Sync queue)
          await db.execute('''
            CREATE TABLE user_reviews (
              id TEXT PRIMARY KEY,
              place_id TEXT NOT NULL,
              rating REAL NOT NULL,
              comment TEXT,
              created_at TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            );
          ''');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalDbService: SQLite native unavailable, using memory fallback ($e)');
      _isInitialized = true;
    }
  }

  // ==========================================
  // TRIP PLANS
  // ==========================================

  Future<void> saveTrip(TripPlan plan) async {
    await init();
    _inMemorySavedTrips[plan.id] = plan;

    if (_userDb != null) {
      try {
        await _userDb!.insert(
          'saved_trips',
          {
            'id': plan.id,
            'title': plan.title,
            'city_name': plan.cityName,
            'days_count': plan.daysCount,
            'plan_json': plan.toJson(),
            'created_at': plan.createdAt.toIso8601String(),
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error saving trip to sqlite: $e');
      }
    }
  }

  Future<List<TripPlan>> getSavedTrips() async {
    await init();

    if (_userDb != null) {
      try {
        final maps = await _userDb!.query(
          'saved_trips',
          orderBy: 'created_at DESC',
        );
        return maps.map((m) {
          final jsonStr = m['plan_json'] as String;
          return TripPlan.fromJson(jsonStr);
        }).toList();
      } catch (e) {
        debugPrint('Error reading saved trips from sqlite: $e');
      }
    }

    final list = _inMemorySavedTrips.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<TripPlan?> getSavedTripById(String id) async {
    await init();

    if (_userDb != null) {
      try {
        final maps = await _userDb!.query(
          'saved_trips',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (maps.isNotEmpty) {
          return TripPlan.fromJson(maps.first['plan_json'] as String);
        }
      } catch (e) {
        debugPrint('Error getting trip by id from sqlite: $e');
      }
    }

    return _inMemorySavedTrips[id];
  }

  Future<void> deleteSavedTrip(String id) async {
    await init();
    _inMemorySavedTrips.remove(id);

    if (_userDb != null) {
      try {
        await _userDb!.delete(
          'saved_trips',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        debugPrint('Error deleting saved trip: $e');
      }
    }
  }

  // ==========================================
  // SOCIAL LIKES (Offline Queue)
  // ==========================================

  Future<bool> toggleLike(String placeId) async {
    await init();
    final currentlyLiked = await isLiked(placeId);

    if (currentlyLiked) {
      _inMemoryLikes.remove(placeId);
      if (_userDb != null) {
        try {
          await _userDb!.delete(
            'user_likes',
            where: 'place_id = ?',
            whereArgs: [placeId],
          );
        } catch (e) {
          debugPrint('Error deleting like: $e');
        }
      }
      return false;
    } else {
      _inMemoryLikes.add(placeId);
      if (_userDb != null) {
        try {
          await _userDb!.insert(
            'user_likes',
            {
              'place_id': placeId,
              'created_at': DateTime.now().toIso8601String(),
              'synced': 0, // Flag for background sync when internet is back
            },
            conflictAlgorithm: sql.ConflictAlgorithm.replace,
          );
        } catch (e) {
          debugPrint('Error inserting like: $e');
        }
      }
      return true;
    }
  }

  Future<bool> isLiked(String placeId) async {
    await init();

    if (_userDb != null) {
      try {
        final maps = await _userDb!.query(
          'user_likes',
          where: 'place_id = ?',
          whereArgs: [placeId],
          limit: 1,
        );
        return maps.isNotEmpty;
      } catch (e) {
        debugPrint('Error checking like: $e');
      }
    }

    return _inMemoryLikes.contains(placeId);
  }

  Future<Set<String>> getLikedPlaceIds() async {
    await init();

    if (_userDb != null) {
      try {
        final maps = await _userDb!.query('user_likes');
        return maps.map((m) => m['place_id'] as String).toSet();
      } catch (e) {
        debugPrint('Error getting all likes: $e');
      }
    }

    return Set.from(_inMemoryLikes);
  }

  // ==========================================
  // SOCIAL REVIEWS (1-5 Stars + Comments)
  // ==========================================

  Future<void> submitReview(
    String placeId,
    double rating, {
    String comment = '',
  }) async {
    await init();
    final id = 'rev_${DateTime.now().millisecondsSinceEpoch}';
    final revMap = {
      'id': id,
      'place_id': placeId,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    _inMemoryReviews.add(revMap);

    if (_userDb != null) {
      try {
        await _userDb!.insert(
          'user_reviews',
          revMap,
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error submitting review: $e');
      }
    }
  }

  // ==========================================
  // CURATED POI CATALOG (OFFLINE PACK)
  // ==========================================

  /// Returns places for city (from pack or bundled curated catalog)
  Future<List<Place>> getPlacesForCity(String citySlug) async {
    // Curated rich dataset for Recife & Olinda (Capital PE)
    return const [
      Place(
        id: 'marco_zero',
        citySlug: 'recife',
        name: 'Praça do Marco Zero',
        category: 'cultura',
        lat: -8.0631,
        lon: -34.8711,
        durationMin: 75,
        costLevel: 1,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 98.5,
        ratingAvg: 4.9,
        ratingCount: 4820,
        likesCount: 9150,
        rankPosicao: 1,
        description: 'Coração do Recife Antigo, marco geográfico e vista panorâmica para o Parque das Esculturas.',
        imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80',
        openingTime: '00:00',
        closingTime: '23:59',
      ),
      Place(
        id: 'cais_do_sertao',
        citySlug: 'recife',
        name: 'Museu Cais do Sertão',
        category: 'cultura',
        lat: -8.0608,
        lon: -34.8706,
        durationMin: 90,
        costLevel: 2,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 96.0,
        ratingAvg: 4.8,
        ratingCount: 3120,
        likesCount: 6400,
        rankPosicao: 2,
        description: 'Museu interativo e sensorial dedicado à cultura do sertão nordestino e a Luiz Gonzaga.',
        imageUrl: 'https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=800&q=80',
        openingTime: '09:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'paco_do_frevo',
        citySlug: 'recife',
        name: 'Paço do Frevo',
        category: 'cultura',
        lat: -8.0620,
        lon: -34.8718,
        durationMin: 60,
        costLevel: 2,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 94.5,
        ratingAvg: 4.8,
        ratingCount: 2780,
        likesCount: 5200,
        rankPosicao: 3,
        description: 'Espaço dedicado à salvaguarda e celebração do Frevo, Patrimônio Imaterial da Humanidade pela UNESCO.',
        imageUrl: 'https://images.unsplash.com/photo-1582650625119-3a31f8418b7d?auto=format&fit=crop&w=800&q=80',
        openingTime: '10:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'rua_do_bom_jesus',
        citySlug: 'recife',
        name: 'Rua do Bom Jesus & Sinagoga Kahal Zur Israel',
        category: 'cultura',
        lat: -8.0617,
        lon: -34.8713,
        durationMin: 60,
        costLevel: 1,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 97.0,
        ratingAvg: 4.9,
        ratingCount: 3950,
        likesCount: 7890,
        rankPosicao: 4,
        description: 'Eleita uma das ruas mais bonitas do mundo; abriga a primeira sinagoga das Américas.',
        imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
        openingTime: '09:00',
        closingTime: '18:00',
      ),
      Place(
        id: 'restaurante_leite',
        citySlug: 'recife',
        name: 'Restaurante Leite (Desde 1882)',
        category: 'gastronomia',
        lat: -8.0612,
        lon: -34.8835,
        durationMin: 75,
        costLevel: 4,
        kidFriendly: false,
        mustSee: true,
        isLunch: true,
        score: 95.0,
        ratingAvg: 4.8,
        ratingCount: 2100,
        likesCount: 4120,
        rankPosicao: 5,
        description: 'O restaurante mais antigo em funcionamento contínuo do Brasil, famoso pelo Bacalhau e Cartola.',
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        openingTime: '11:30',
        closingTime: '16:00',
      ),
      Place(
        id: 'parraxaxa_boa_viagem',
        citySlug: 'recife',
        name: 'Restaurante Parraxaxá',
        category: 'gastronomia',
        lat: -8.1189,
        lon: -34.9015,
        durationMin: 70,
        costLevel: 3,
        kidFriendly: true,
        mustSee: true,
        isLunch: true,
        score: 97.5,
        ratingAvg: 4.9,
        ratingCount: 5200,
        likesCount: 8900,
        rankPosicao: 6,
        description: 'Banquete autêntico de comida regional nordestina com carne de sol na nata e baião de dois.',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
        openingTime: '11:30',
        closingTime: '22:00',
      ),
      Place(
        id: 'instituto_ricardo_brennand',
        citySlug: 'recife',
        name: 'Instituto Ricardo Brennand (Castelo)',
        category: 'cultura',
        lat: -8.0645,
        lon: -34.9642,
        durationMin: 150,
        costLevel: 3,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 99.0,
        ratingAvg: 4.9,
        ratingCount: 6800,
        likesCount: 12500,
        rankPosicao: 7,
        description: 'Castelo medieval cercado por reserva de Mata Atlântica; maior acervo de Frans Post e armas brancas.',
        imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
        openingTime: '13:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'oficina_francisco_brennand',
        citySlug: 'recife',
        name: 'Oficina Francisco Brennand',
        category: 'cultura',
        lat: -8.0531,
        lon: -34.9749,
        durationMin: 120,
        costLevel: 2,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 96.5,
        ratingAvg: 4.8,
        ratingCount: 3400,
        likesCount: 6800,
        rankPosicao: 8,
        description: 'Templo monumental de esculturas e cerâmicas a céu aberto criado pelo mestre Francisco Brennand.',
        imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
        openingTime: '10:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'praia_boa_viagem',
        citySlug: 'recife',
        name: 'Praia de Boa Viagem & Calçadão',
        category: 'praias',
        lat: -8.1275,
        lon: -34.9011,
        durationMin: 120,
        costLevel: 1,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 95.5,
        ratingAvg: 4.7,
        ratingCount: 8900,
        likesCount: 14200,
        rankPosicao: 9,
        description: 'Orla mais famosa do Recife com 8km de calçadão, quiosques com água de coco e piscinas na maré baixa.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
        openingTime: '06:00',
        closingTime: '22:00',
      ),
      Place(
        id: 'parque_das_esculturas',
        citySlug: 'recife',
        name: 'Parque das Esculturas Francisco Brennand',
        category: 'cultura',
        lat: -8.0642,
        lon: -34.8685,
        durationMin: 60,
        costLevel: 1,
        kidFriendly: true,
        mustSee: false,
        isLunch: false,
        score: 90.0,
        ratingAvg: 4.6,
        ratingCount: 1850,
        likesCount: 3100,
        rankPosicao: 10,
        description: 'Acesso de barquinho a partir do Marco Zero; abriga a Coluna de Cristal de 32 metros.',
        imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80',
        openingTime: '08:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'alto_da_se_olinda',
        citySlug: 'recife',
        name: 'Alto da Sé & Mirante Histórico de Olinda',
        category: 'cultura',
        lat: -8.0139,
        lon: -34.8519,
        durationMin: 90,
        costLevel: 1,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 98.0,
        ratingAvg: 4.9,
        ratingCount: 6400,
        likesCount: 11800,
        rankPosicao: 11,
        description: 'Mirante lendário com vista panorâmica para o mar e Recife, barracas de tapioca e feira cultural.',
        imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
        openingTime: '08:00',
        closingTime: '20:00',
      ),
      Place(
        id: 'mosteiro_sao_bento',
        citySlug: 'recife',
        name: 'Mosteiro de São Bento de Olinda',
        category: 'cultura',
        lat: -8.0189,
        lon: -34.8547,
        durationMin: 60,
        costLevel: 1,
        kidFriendly: true,
        mustSee: true,
        isLunch: false,
        score: 95.0,
        ratingAvg: 4.8,
        ratingCount: 2900,
        likesCount: 5400,
        rankPosicao: 12,
        description: 'Joia do barroco brasileiro com altar-mor folheado a ouro de valor histórico incalculável.',
        imageUrl: 'https://images.unsplash.com/photo-1548625361-1250325d7b68?auto=format&fit=crop&w=800&q=80',
        openingTime: '09:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'oficina_do_sabor',
        citySlug: 'recife',
        name: 'Restaurante Oficina do Sabor (Olinda)',
        category: 'gastronomia',
        lat: -8.0163,
        lon: -34.8524,
        durationMin: 80,
        costLevel: 4,
        kidFriendly: true,
        mustSee: true,
        isLunch: true,
        score: 96.0,
        ratingAvg: 4.9,
        ratingCount: 2300,
        likesCount: 4900,
        rankPosicao: 13,
        description: 'Alta gastronomia pernambucana de autor em Olinda com moranga de frutos do mar.',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
        openingTime: '12:00',
        closingTime: '23:00',
      ),
      Place(
        id: 'mercado_sao_jose',
        citySlug: 'recife',
        name: 'Mercado de São José & Artesanato',
        category: 'compras',
        lat: -8.0678,
        lon: -34.8778,
        durationMin: 60,
        costLevel: 1,
        kidFriendly: false,
        mustSee: false,
        isLunch: false,
        score: 88.0,
        ratingAvg: 4.5,
        ratingCount: 3100,
        likesCount: 4200,
        rankPosicao: 14,
        description: 'Mercado público de ferro fundido de 1875; polo de artesanato em palha, renda e temperos.',
        imageUrl: 'https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?auto=format&fit=crop&w=800&q=80',
        openingTime: '08:00',
        closingTime: '17:00',
      ),
      Place(
        id: 'jardim_botanico_recife',
        citySlug: 'recife',
        name: 'Jardim Botânico do Recife',
        category: 'natureza',
        lat: -8.0772,
        lon: -34.9664,
        durationMin: 90,
        costLevel: 1,
        kidFriendly: true,
        mustSee: false,
        isLunch: false,
        score: 92.0,
        ratingAvg: 4.7,
        ratingCount: 1950,
        likesCount: 3800,
        rankPosicao: 15,
        description: 'Trilhas ecológicas imersas em Mata Atlântica preservada, orquidário e jardins temáticos.',
        imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
        openingTime: '09:00',
        closingTime: '15:30',
      ),
    ];
  }
}
