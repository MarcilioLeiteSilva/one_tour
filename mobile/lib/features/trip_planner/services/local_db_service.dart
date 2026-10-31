import 'dart:convert';
import 'dart:io';
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
  final Set<String> _inMemoryDownloadedPacks = {'recife'};
  final Map<String, String> _inMemoryMeta = {};
  final List<Map<String, dynamic>> _inMemoryPendingEvents = [];
  int _inMemoryEventSeq = 0;
  List<Map<String, dynamic>> _inMemoryStatsCache = [];

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
        version: 3,
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

          // 4. Downloaded Packs table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS downloaded_packs (
              city_slug TEXT PRIMARY KEY,
              downloaded_at TEXT NOT NULL
            );
          ''');

          // 5. Social sync: device id, offline event queue and stats cache
          await _createSocialTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS downloaded_packs (
                city_slug TEXT PRIMARY KEY,
                downloaded_at TEXT NOT NULL
              );
            ''');
          }
          if (oldVersion < 3) {
            await _createSocialTables(db);
          }
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalDbService: SQLite native unavailable, using memory fallback ($e)');
      _isInitialized = true;
    }
  }

  Future<void> _createSocialTables(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS place_stats_cache (
        place_id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      );
    ''');
  }

  // ==========================================
  // APP META, OFFLINE EVENT QUEUE & STATS CACHE
  // ==========================================

  Future<String?> getMeta(String key) async {
    await init();
    if (_userDb != null) {
      try {
        final rows = await _userDb!.query('app_meta', where: 'key = ?', whereArgs: [key], limit: 1);
        if (rows.isNotEmpty) return rows.first['value'] as String;
        return null;
      } catch (e) {
        debugPrint('Error reading meta: $e');
      }
    }
    return _inMemoryMeta[key];
  }

  Future<void> setMeta(String key, String value) async {
    await init();
    _inMemoryMeta[key] = value;
    if (_userDb != null) {
      try {
        await _userDb!.insert(
          'app_meta',
          {'key': key, 'value': value},
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error writing meta: $e');
      }
    }
  }

  /// Appends an event (JSON) to the offline outbox. Returns its row id.
  Future<int> enqueueEvent(String payloadJson) async {
    await init();
    final createdAt = DateTime.now().toIso8601String();
    if (_userDb != null) {
      try {
        return await _userDb!.insert('pending_events', {
          'payload': payloadJson,
          'created_at': createdAt,
        });
      } catch (e) {
        debugPrint('Error enqueueing event: $e');
      }
    }
    final id = ++_inMemoryEventSeq;
    _inMemoryPendingEvents.add({'id': id, 'payload': payloadJson, 'created_at': createdAt});
    return id;
  }

  /// Oldest-first pending events (`id`, `payload`).
  Future<List<Map<String, dynamic>>> getPendingEvents({int limit = 100}) async {
    await init();
    if (_userDb != null) {
      try {
        final rows = await _userDb!.query('pending_events', orderBy: 'id ASC', limit: limit);
        return rows.map((r) => Map<String, dynamic>.from(r)).toList();
      } catch (e) {
        debugPrint('Error reading pending events: $e');
      }
    }
    return _inMemoryPendingEvents.take(limit).map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> deletePendingEvents(List<int> ids) async {
    if (ids.isEmpty) return;
    await init();
    _inMemoryPendingEvents.removeWhere((e) => ids.contains(e['id']));
    if (_userDb != null) {
      try {
        final marks = List.filled(ids.length, '?').join(',');
        await _userDb!.delete('pending_events', where: 'id IN ($marks)', whereArgs: ids);
      } catch (e) {
        debugPrint('Error deleting pending events: $e');
      }
    }
  }

  Future<int> pendingEventsCount() async {
    await init();
    if (_userDb != null) {
      try {
        final rows = await _userDb!.rawQuery('SELECT COUNT(*) AS n FROM pending_events');
        return (rows.first['n'] as num).toInt();
      } catch (e) {
        debugPrint('Error counting pending events: $e');
      }
    }
    return _inMemoryPendingEvents.length;
  }

  /// Replaces the cached community stats (raw JSON maps from the API).
  Future<void> replaceStatsCache(List<Map<String, dynamic>> stats) async {
    await init();
    _inMemoryStatsCache = stats;
    if (_userDb != null) {
      try {
        await _userDb!.transaction((txn) async {
          await txn.delete('place_stats_cache');
          final batch = txn.batch();
          for (final s in stats) {
            batch.insert(
              'place_stats_cache',
              {'place_id': s['place_id'].toString(), 'data': jsonEncode(s)},
              conflictAlgorithm: sql.ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        });
      } catch (e) {
        debugPrint('Error saving stats cache: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> loadStatsCache() async {
    await init();
    if (_userDb != null) {
      try {
        final rows = await _userDb!.query('place_stats_cache');
        return rows
            .map((r) => Map<String, dynamic>.from(jsonDecode(r['data'] as String) as Map))
            .toList();
      } catch (e) {
        debugPrint('Error loading stats cache: $e');
      }
    }
    return List.of(_inMemoryStatsCache);
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

  Future<List<Map<String, dynamic>>> getReviewsForPlace(String placeId) async {
    await init();
    if (_userDb != null) {
      try {
        final maps = await _userDb!.query(
          'user_reviews',
          where: 'place_id = ?',
          whereArgs: [placeId],
          orderBy: 'created_at DESC',
        );
        return maps;
      } catch (e) {
        debugPrint('Error getting reviews: $e');
      }
    }
    return _inMemoryReviews.where((r) => r['place_id'] == placeId).toList();
  }

  // ==========================================
  // OFFLINE CITY PACKS
  // ==========================================

  Future<bool> isCityDownloaded(String citySlug) async {
    await init();
    final slug = citySlug.toLowerCase().trim();

    if (_userDb != null) {
      try {
        final maps = await _userDb!.query(
          'downloaded_packs',
          where: 'city_slug = ?',
          whereArgs: [slug],
          limit: 1,
        );
        return maps.isNotEmpty;
      } catch (e) {
        debugPrint('Error checking downloaded pack: $e');
      }
    }

    return _inMemoryDownloadedPacks.contains(slug);
  }

  Future<void> markCityDownloaded(String citySlug) async {
    await init();
    final slug = citySlug.toLowerCase().trim();
    _inMemoryDownloadedPacks.add(slug);

    if (_userDb != null) {
      try {
        await _userDb!.insert(
          'downloaded_packs',
          {
            'city_slug': slug,
            'downloaded_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error marking pack downloaded: $e');
      }
    }
  }

  Future<void> removeCityDownloaded(String citySlug) async {
    await init();
    final slug = citySlug.toLowerCase().trim();
    _inMemoryDownloadedPacks.remove(slug);

    if (_userDb != null) {
      try {
        await _userDb!.delete(
          'downloaded_packs',
          where: 'city_slug = ?',
          whereArgs: [slug],
        );
      } catch (e) {
        debugPrint('Error removing downloaded pack: $e');
      }
    }
  }

  Future<Set<String>> getDownloadedCities() async {
    await init();

    if (_userDb != null) {
      try {
        final maps = await _userDb!.query('downloaded_packs');
        final fromDb = maps.map((m) => m['city_slug'] as String).toSet();
        return {..._inMemoryDownloadedPacks, ...fromDb};
      } catch (e) {
        debugPrint('Error getting downloaded packs: $e');
      }
    }

    return Set.from(_inMemoryDownloadedPacks);
  }

  Future<void> deleteCityPack(String citySlug) async {
    await init();
    final slug = citySlug.toLowerCase().trim();
    _inMemoryDownloadedPacks.remove(slug);

    if (_userDb != null) {
      try {
        await _userDb!.delete(
          'downloaded_packs',
          where: 'city_slug = ?',
          whereArgs: [slug],
        );
      } catch (e) {
        debugPrint('Error deleting downloaded pack: $e');
      }
    }
  }

  // ==========================================
  // CURATED POI CATALOG (OFFLINE PACK)
  // ==========================================

  /// Returns places for city (from downloaded SQLite pack or bundled catalog fallback)
  Future<List<Place>> getPlacesForCity(String citySlug) async {
    final slug = citySlug.toLowerCase().trim();

    // 1. Tenta carregar os lugares diretamente do SQLite baixado
    try {
      final dbPath = await sql.getDatabasesPath();
      final packFile = File(p.join(dbPath, 'pack_$slug.sqlite'));
      if (await packFile.exists()) {
        final packDb = await sql.openReadOnlyDatabase(packFile.path);
        final rows = await packDb.query('place', orderBy: 'rank_posicao ASC');
        await packDb.close();

        if (rows.isNotEmpty) {
          debugPrint('📂 [LocalDbService] Carregados ${rows.length} lugares reais do pack_$slug.sqlite!');
          return rows.map((r) => Place.fromMap(r)).toList();
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [LocalDbService] Falha ao ler pack_$slug.sqlite ($e). Usando catálogo padrão.');
    }

    // 2. Fallback de catálogo integrado em memória
    if (slug == 'porto_de_galinhas' || slug.contains('porto')) {
      return _portoPlaces;
    } else if (slug == 'carneiros' || slug.contains('carneiros')) {
      return _carneirosPlaces;
    } else if (slug == 'noronha' || slug.contains('noronha')) {
      return _noronhaPlaces;
    } else if (slug == 'olinda' || slug.contains('olinda')) {
      return _olindaPlaces;
    } else if (slug == 'maceio' || slug == 'al' || slug.contains('maceio') || slug.contains('maragogi')) {
      return _maceioPlaces;
    }
    return _recifePlaces;
  }

  /// Consulta a matriz pré-calculada de distância e tempo de trajeto do SQLite pack
  Future<TravelSegment?> getTravelSegment(String citySlug, String fromId, String toId) async {
    final slug = citySlug.toLowerCase().trim();
    try {
      final dbPath = await sql.getDatabasesPath();
      final packFile = File(p.join(dbPath, 'pack_$slug.sqlite'));
      if (await packFile.exists()) {
        final packDb = await sql.openReadOnlyDatabase(packFile.path);
        final rows = await packDb.query(
          'matrix',
          where: 'from_id = ? AND to_id = ?',
          whereArgs: [fromId, toId],
          limit: 1,
        );
        await packDb.close();

        if (rows.isNotEmpty) {
          final dist = (rows.first['distance_meters'] as num?)?.toInt() ?? 0;
          final walkSec = (rows.first['walk_seconds'] as num?)?.toInt() ?? 0;
          final driveSec = (rows.first['drive_seconds'] as num?)?.toInt() ?? 0;
          final isWalk = dist <= 1500;
          final durationMin = isWalk
              ? (walkSec / 60).ceil().clamp(1, 120)
              : (driveSec / 60).ceil().clamp(2, 240);

          return TravelSegment(
            distanceMeters: dist,
            durationMinutes: durationMin,
            isWalk: isWalk,
          );
        }
      }
    } catch (e) {
      debugPrint('LocalDbService: Matriz pré-calculada não encontrada ($e)');
    }
    return null;
  }

  static const List<Place> _recifePlaces = [
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
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg/1280px-Pra%C3%A7a_do_Marco_Zero%2C_Recife%2C_Pernambuco%2C_Brasil.jpg',
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
        imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=800&q=80',
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
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg',
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
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
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
        imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=800&q=80',
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
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
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
        imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
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

  /// Returns metadata of available offline city packs
  List<Map<String, dynamic>> getAvailableCityPacks() {
    return const [
      {
        'slug': 'recife',
        'name': 'Recife & Olinda',
        'tag': 'Capital Multicultural',
        'placesCount': 15,
        'packageSize': '72 KB',
        'assetPath': 'assets/packs/pack_recife.sqlite',
      },
      {
        'slug': 'porto_de_galinhas',
        'name': 'Porto de Galinhas',
        'tag': 'Piscinas Naturais & Jangadas',
        'placesCount': 10,
        'packageSize': '48 KB',
        'assetPath': 'assets/packs/pack_porto_de_galinhas.sqlite',
      },
      {
        'slug': 'carneiros',
        'name': 'Praia dos Carneiros',
        'tag': 'Paraíso dos Coqueirais',
        'placesCount': 8,
        'packageSize': '40 KB',
        'assetPath': 'assets/packs/pack_carneiros.sqlite',
      },
      {
        'slug': 'noronha',
        'name': 'Fernando de Noronha',
        'tag': 'Santuário Ecológico Mundial',
        'placesCount': 10,
        'packageSize': '56 KB',
        'assetPath': 'assets/packs/pack_noronha.sqlite',
      },
    ];
  }

  // ==========================================
  // 2. PORTO DE GALINHAS POI CATALOG
  // ==========================================
  static const List<Place> _portoPlaces = [
    Place(
      id: 'piscinas_porto',
      citySlug: 'porto_de_galinhas',
      name: 'Piscinas Naturais de Porto de Galinhas',
      category: 'praias',
      lat: -8.5042,
      lon: -35.0028,
      durationMin: 120,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 99.0,
      ratingAvg: 4.9,
      ratingCount: 5400,
      likesCount: 11200,
      rankPosicao: 1,
      description: 'Passeio clássico de jangada até a barreira de corais com peixes sargentinhos coloridos.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Piscina_natural_na_Praia_de_Porto_de_Galinhas%2C_Pernambuco%2C_Brasil%282%29.jpg',
      openingTime: '07:00',
      closingTime: '17:00',
    ),
    Place(
      id: 'muro_alto',
      citySlug: 'porto_de_galinhas',
      name: 'Praia de Muro Alto & Paredão de Recifes',
      category: 'praias',
      lat: -8.4712,
      lon: -34.9875,
      durationMin: 150,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 97.5,
      ratingAvg: 4.9,
      ratingCount: 4200,
      likesCount: 9800,
      rankPosicao: 2,
      description: 'Piscina oceânica de águas mornas e sem ondas, ideal para famílias com crianças pequenas.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg/1280px-BRUNO_LIMA_PRAIA_DE_MURO_ALTO_IPOJUCA_PE_%2840908731001%29.jpg',
      openingTime: '06:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'pontal_maracaipe',
      citySlug: 'porto_de_galinhas',
      name: 'Pontal de Maracaípe & Cavalos-Marinhos',
      category: 'natureza',
      lat: -8.5350,
      lon: -35.0180,
      durationMin: 90,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.0,
      ratingAvg: 4.8,
      ratingCount: 3600,
      likesCount: 7800,
      rankPosicao: 3,
      description: 'Encontro do rio com mar com jangadeiros levando para avistar cavalos-marinhos no mangue.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg/1280px-BRUNO_LIMA_PONTAL_DE_MARACAIPE_IPOJUCA_PE_%2826036000327%29.jpg',
      openingTime: '08:00',
      closingTime: '17:30',
    ),
    Place(
      id: 'praia_cupe',
      citySlug: 'porto_de_galinhas',
      name: 'Praia do Cupe & Pontal do Cupe',
      category: 'praias',
      lat: -8.4890,
      lon: -34.9960,
      durationMin: 90,
      costLevel: 1,
      kidFriendly: false,
      mustSee: false,
      isLunch: false,
      score: 92.0,
      ratingAvg: 4.7,
      ratingCount: 2400,
      likesCount: 5100,
      rankPosicao: 4,
      description: 'Extensa faixa de areia com trecho para surf e pontal calmo protegido por arrecifes.',
      imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80',
      openingTime: '06:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'vila_porto',
      citySlug: 'porto_de_galinhas',
      name: 'Vila de Porto & Galinhas Artesanais',
      category: 'compras',
      lat: -8.5060,
      lon: -35.0050,
      durationMin: 75,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 94.0,
      ratingAvg: 4.8,
      ratingCount: 4100,
      likesCount: 8200,
      rankPosicao: 5,
      description: 'Centro charmoso com calçadões de pedestres, esculturas de galinhas coloridas e sorveterias.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
      openingTime: '09:00',
      closingTime: '23:00',
    ),
    Place(
      id: 'barcaxeira',
      citySlug: 'porto_de_galinhas',
      name: 'Restaurante Barcaxeira',
      category: 'gastronomia',
      lat: -8.5055,
      lon: -35.0042,
      durationMin: 75,
      costLevel: 3,
      kidFriendly: true,
      mustSee: true,
      isLunch: true,
      score: 96.5,
      ratingAvg: 4.9,
      ratingCount: 3800,
      likesCount: 7900,
      rankPosicao: 6,
      description: 'Parada gastronômica obrigatória famosa pelos pratos de macaxeira gratinada com camarão.',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      openingTime: '12:00',
      closingTime: '23:00',
    ),
    Place(
      id: 'restaurante_domingos',
      citySlug: 'porto_de_galinhas',
      name: 'Restaurante Domingos',
      category: 'gastronomia',
      lat: -8.5062,
      lon: -35.0048,
      durationMin: 80,
      costLevel: 4,
      kidFriendly: false,
      mustSee: true,
      isLunch: true,
      score: 95.0,
      ratingAvg: 4.8,
      ratingCount: 2200,
      likesCount: 4500,
      rankPosicao: 7,
      description: 'Ambiente refinado com música ao vivo e pratos nobres de lagosta grelhada.',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
      openingTime: '12:00',
      closingTime: '23:30',
    ),
    Place(
      id: 'projeto_hippocampus',
      citySlug: 'porto_de_galinhas',
      name: 'Projeto Hippocampus (Conservação)',
      category: 'natureza',
      lat: -8.5015,
      lon: -35.0068,
      durationMin: 45,
      costLevel: 1,
      kidFriendly: true,
      mustSee: false,
      isLunch: false,
      score: 91.5,
      ratingAvg: 4.7,
      ratingCount: 1800,
      likesCount: 3400,
      rankPosicao: 8,
      description: 'Centro de preservação ambiental com aquários dedicados à pesquisa dos cavalos-marinhos.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      openingTime: '09:00',
      closingTime: '16:30',
    ),
    Place(
      id: 'buggy_ponta_a_ponta',
      citySlug: 'porto_de_galinhas',
      name: 'Passeio de Buggy Ponta a Ponta',
      category: 'aventura',
      lat: -8.5050,
      lon: -35.0035,
      durationMin: 180,
      costLevel: 3,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 98.0,
      ratingAvg: 4.9,
      ratingCount: 4900,
      likesCount: 10400,
      rankPosicao: 9,
      description: 'Aventura clássica que percorre de Muro Alto ao Pontal de Maracaípe pelas areias e coqueirais.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      openingTime: '08:00',
      closingTime: '16:00',
    ),
    Place(
      id: 'praia_serrambi',
      citySlug: 'porto_de_galinhas',
      name: 'Praia de Serrambi & Enseada Tranquila',
      category: 'praias',
      lat: -8.5610,
      lon: -35.0320,
      durationMin: 120,
      costLevel: 1,
      kidFriendly: true,
      mustSee: false,
      isLunch: false,
      score: 91.0,
      ratingAvg: 4.6,
      ratingCount: 1950,
      likesCount: 3800,
      rankPosicao: 10,
      description: 'Refúgio de águas calmas e mornas, excelente para caminhadas relaxantes à beira-mar.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      openingTime: '06:00',
      closingTime: '18:00',
    ),
  ];

  // ==========================================
  // 3. PRAIA DOS CARNEIROS POI CATALOG
  // ==========================================
  static const List<Place> _carneirosPlaces = [
    Place(
      id: 'capela_sao_benedito',
      citySlug: 'carneiros',
      name: 'Capela de São Benedito (Igrejinha de Carneiros)',
      category: 'cultura',
      lat: -8.7042,
      lon: -35.0883,
      durationMin: 60,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 99.0,
      ratingAvg: 4.9,
      ratingCount: 4800,
      likesCount: 12300,
      rankPosicao: 1,
      description: 'A capela mais fotografada do Brasil, construída no século XVIII entre coqueirais centenários.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Capela_S%C3%A3o_Benedito_-_Praia_de_Carneiros_-_Pernambuco.jpg/1280px-Capela_S%C3%A3o_Benedito_-_Praia_de_Carneiros_-_Pernambuco.jpg',
      openingTime: '06:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'piscinas_carneiros',
      citySlug: 'carneiros',
      name: 'Piscinas Naturais de Carneiros',
      category: 'praias',
      lat: -8.7070,
      lon: -35.0850,
      durationMin: 120,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 98.0,
      ratingAvg: 4.9,
      ratingCount: 4100,
      likesCount: 9600,
      rankPosicao: 2,
      description: 'Mar verde-esmeralda límpido com recifes de corais acessíveis a pé na maré baixa.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      openingTime: '07:00',
      closingTime: '17:00',
    ),
    Place(
      id: 'banho_argila_guadalupe',
      citySlug: 'carneiros',
      name: 'Banho de Argila na Praia de Guadalupe',
      category: 'natureza',
      lat: -8.6850,
      lon: -35.0740,
      durationMin: 60,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 93.0,
      ratingAvg: 4.7,
      ratingCount: 2900,
      likesCount: 5800,
      rankPosicao: 3,
      description: 'Parada dos passeios de barco para esfoliação com argila medicinal natural rica em minerais.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      openingTime: '08:00',
      closingTime: '16:30',
    ),
    Place(
      id: 'catamara_bancos_areia',
      citySlug: 'carneiros',
      name: 'Passeio de Catamarã pelos Bancos de Areia',
      category: 'aventura',
      lat: -8.7010,
      lon: -35.0860,
      durationMin: 120,
      costLevel: 3,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.5,
      ratingAvg: 4.8,
      ratingCount: 3500,
      likesCount: 7900,
      rankPosicao: 4,
      description: 'Navegação pelas águas cristalinas do Rio Formoso e bancos de areia que emergem no mar.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      openingTime: '09:00',
      closingTime: '16:00',
    ),
    Place(
      id: 'bora_bora_carneiros',
      citySlug: 'carneiros',
      name: 'Bora Bora Carneiros (Beach Club)',
      category: 'gastronomia',
      lat: -8.7030,
      lon: -35.0875,
      durationMin: 90,
      costLevel: 3,
      kidFriendly: true,
      mustSee: true,
      isLunch: true,
      score: 97.0,
      ratingAvg: 4.8,
      ratingCount: 5200,
      likesCount: 10500,
      rankPosicao: 5,
      description: 'Estrutura completa pé na areia com gazebos, petiscos de frutos do mar e drinks tropicais.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
      openingTime: '09:00',
      closingTime: '17:00',
    ),
    Place(
      id: 'beijupira_carneiros',
      citySlug: 'carneiros',
      name: 'Restaurante Beijupirá Carneiros',
      category: 'gastronomia',
      lat: -8.6990,
      lon: -35.0845,
      durationMin: 80,
      costLevel: 4,
      kidFriendly: false,
      mustSee: true,
      isLunch: true,
      score: 95.5,
      ratingAvg: 4.8,
      ratingCount: 2600,
      likesCount: 5400,
      rankPosicao: 6,
      description: 'Culinária refinada misturando peixes frescos grelhados com frutas tropicais perfumadas.',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
      openingTime: '11:30',
      closingTime: '17:00',
    ),
    Place(
      id: 'rio_formoso_manguezal',
      citySlug: 'carneiros',
      name: 'Estuário do Rio Formoso & Manguezais',
      category: 'natureza',
      lat: -8.6920,
      lon: -35.0930,
      durationMin: 75,
      costLevel: 1,
      kidFriendly: true,
      mustSee: false,
      isLunch: false,
      score: 90.5,
      ratingAvg: 4.6,
      ratingCount: 1700,
      likesCount: 3200,
      rankPosicao: 7,
      description: 'Rico ecossistema costeiro ideal para passeios de stand up paddle e contemplação.',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80',
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    Place(
      id: 'praia_do_amor',
      citySlug: 'carneiros',
      name: 'Praia do Amor & Coqueiro Solitário',
      category: 'praias',
      lat: -8.7180,
      lon: -35.0990,
      durationMin: 90,
      costLevel: 1,
      kidFriendly: true,
      mustSee: false,
      isLunch: false,
      score: 89.0,
      ratingAvg: 4.6,
      ratingCount: 1400,
      likesCount: 2900,
      rankPosicao: 8,
      description: 'Faixa calma de areia branca para caminhadas românticas e fotos no coqueiro inclinado.',
      imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80',
      openingTime: '06:00',
      closingTime: '18:00',
    ),
  ];

  // ==========================================
  // 4. FERNANDO DE NORONHA POI CATALOG
  // ==========================================
  static const List<Place> _noronhaPlaces = [
    Place(
      id: 'baia_do_sancho',
      citySlug: 'noronha',
      name: 'Baía do Sancho (Melhor Praia do Mundo)',
      category: 'praias',
      lat: -3.8542,
      lon: -32.4435,
      durationMin: 180,
      costLevel: 2,
      kidFriendly: false,
      mustSee: true,
      isLunch: false,
      score: 99.8,
      ratingAvg: 5.0,
      ratingCount: 6200,
      likesCount: 18500,
      rankPosicao: 1,
      description: 'Eleita consecutivamente a melhor praia do planeta; águas cristalinas e vida marinha rica.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      openingTime: '08:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'baia_dos_porcos',
      citySlug: 'noronha',
      name: 'Baía dos Porcos & Morro Dois Irmãos',
      category: 'praias',
      lat: -3.8510,
      lon: -32.4410,
      durationMin: 120,
      costLevel: 1,
      kidFriendly: false,
      mustSee: true,
      isLunch: false,
      score: 99.0,
      ratingAvg: 4.9,
      ratingCount: 5100,
      likesCount: 14200,
      rankPosicao: 2,
      description: 'Cartão-postal mais famoso do arquipélago, com piscinas naturais de cor verde-esmeralda.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      openingTime: '08:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'cacimba_do_padre',
      citySlug: 'noronha',
      name: 'Praia da Cacimba do Padre',
      category: 'praias',
      lat: -3.8530,
      lon: -32.4460,
      durationMin: 90,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.5,
      ratingAvg: 4.8,
      ratingCount: 3900,
      likesCount: 8900,
      rankPosicao: 3,
      description: 'Meca do surf com ondas tubulares perfeitas e ampla faixa de areia voltada para os Dois Irmãos.',
      imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80',
      openingTime: '06:00',
      closingTime: '18:30',
    ),
    Place(
      id: 'mirante_golfinhos',
      citySlug: 'noronha',
      name: 'Mirante dos Golfinhos Rotadores',
      category: 'natureza',
      lat: -3.8550,
      lon: -32.4380,
      durationMin: 90,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 97.0,
      ratingAvg: 4.9,
      ratingCount: 3400,
      likesCount: 7600,
      rankPosicao: 4,
      description: 'Observatório no alto do penhasco onde cardumes de golfinhos realizam saltos acrobáticos matinais.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      openingTime: '06:30',
      closingTime: '16:00',
    ),
    Place(
      id: 'projeto_tamar_noronha',
      citySlug: 'noronha',
      name: 'Centro de Visitantes Projeto Tamar',
      category: 'natureza',
      lat: -3.8480,
      lon: -32.4280,
      durationMin: 60,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 95.0,
      ratingAvg: 4.8,
      ratingCount: 2800,
      likesCount: 6200,
      rankPosicao: 5,
      description: 'Palestras ambientais noturnas e exposições sobre a preservação das tartarugas e ecossistema.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg/1280px-BRUNO_LIMA_CAIS_DO_SERTAO_RECIFE_PE_%2839114020220%29.jpg',
      openingTime: '09:00',
      closingTime: '22:00',
    ),
    Place(
      id: 'mergulho_naufragio_porto',
      citySlug: 'noronha',
      name: 'Mergulho no Naufrágio do Porto',
      category: 'aventura',
      lat: -3.8420,
      lon: -32.4170,
      durationMin: 150,
      costLevel: 4,
      kidFriendly: false,
      mustSee: true,
      isLunch: false,
      score: 98.0,
      ratingAvg: 4.9,
      ratingCount: 3200,
      likesCount: 8100,
      rankPosicao: 6,
      description: 'Mergulho autônomo com cilindro em navio grego naufragado habitado por rica vida marinha.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      openingTime: '08:00',
      closingTime: '16:00',
    ),
    Place(
      id: 'forte_do_boldro_sunset',
      citySlug: 'noronha',
      name: 'Mirante do Forte São Pedro do Boldró',
      category: 'cultura',
      lat: -3.8475,
      lon: -32.4350,
      durationMin: 75,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.0,
      ratingAvg: 4.9,
      ratingCount: 4500,
      likesCount: 9700,
      rankPosicao: 7,
      description: 'O pôr do sol mais aplaudido da ilha, com ruínas históricas e vista para os Dois Irmãos.',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      openingTime: '16:00',
      closingTime: '19:00',
    ),
    Place(
      id: 'trilha_atalaia',
      citySlug: 'noronha',
      name: 'Trilha do Atalaia & Aquário Natural',
      category: 'aventura',
      lat: -3.8450,
      lon: -32.4080,
      durationMin: 120,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 95.5,
      ratingAvg: 4.8,
      ratingCount: 2900,
      likesCount: 6700,
      rankPosicao: 8,
      description: 'Flutuação monitorada em piscina natural rasa repleta de filhotes de tubarão-lixa e polvos.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg/1280px-Fernando_De_Noronha_Strand_Baia_Do_Sancho_%28125363049%29.jpeg',
      openingTime: '08:00',
      closingTime: '15:00',
    ),
    Place(
      id: 'restaurante_varanda',
      citySlug: 'noronha',
      name: 'Restaurante Varanda (Chef Auricélio)',
      category: 'gastronomia',
      lat: -3.8495,
      lon: -32.4260,
      durationMin: 80,
      costLevel: 4,
      kidFriendly: true,
      mustSee: true,
      isLunch: true,
      score: 96.5,
      ratingAvg: 4.9,
      ratingCount: 3100,
      likesCount: 6900,
      rankPosicao: 9,
      description: 'Alta gastronomia da ilha com o tradicional Peixe na Telha e moquecas aromáticas.',
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
      openingTime: '12:00',
      closingTime: '23:00',
    ),
    Place(
      id: 'cacimba_bistro',
      citySlug: 'noronha',
      name: 'Cacimba Bistrô',
      category: 'gastronomia',
      lat: -3.8440,
      lon: -32.4220,
      durationMin: 80,
      costLevel: 4,
      kidFriendly: false,
      mustSee: true,
      isLunch: true,
      score: 95.0,
      ratingAvg: 4.8,
      ratingCount: 2600,
      likesCount: 5800,
      rankPosicao: 10,
      description: 'Bistrô charmoso no centro histórico dos Remédios famoso pelos pastéis de lagosta.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
      openingTime: '12:00',
      closingTime: '23:30',
    ),
  ];

  static const List<Place> _olindaPlaces = [
    Place(
      id: 'alto_da_se',
      citySlug: 'olinda',
      name: 'Alto da Sé & Mirante Panorâmico',
      category: 'cultura',
      lat: -8.0139,
      lon: -34.8519,
      durationMin: 90,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 98.5,
      ratingAvg: 4.9,
      ratingCount: 5400,
      likesCount: 9800,
      rankPosicao: 1,
      description: 'Vista deslumbrante das torres barrocas de Olinda com o mar e o skyline do Recife ao fundo. Ponto alto das tradicionais tapiocas.',
      imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
      openingTime: '08:00',
      closingTime: '21:00',
    ),
    Place(
      id: 'convento_sao_francisco',
      citySlug: 'olinda',
      name: 'Convento de São Francisco',
      category: 'cultura',
      lat: -8.0175,
      lon: -34.8486,
      durationMin: 60,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.5,
      ratingAvg: 4.8,
      ratingCount: 3800,
      likesCount: 7200,
      rankPosicao: 2,
      description: 'Primeiro convento da Ordem Franciscana no Brasil (1585), com ricos painéis de azulejos portugueses e arquitetura barroca.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      openingTime: '09:00',
      closingTime: '17:00',
    ),
    Place(
      id: 'mosteiro_sao_bento_olinda',
      citySlug: 'olinda',
      name: 'Mosteiro de São Bento de Olinda',
      category: 'cultura',
      lat: -8.0205,
      lon: -34.8533,
      durationMin: 60,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.0,
      ratingAvg: 4.8,
      ratingCount: 3100,
      likesCount: 6500,
      rankPosicao: 3,
      description: 'Igreja barroca de valor monumental com altar-mor talhado e folheado a ouro, célebre pelas missas com canto gregoriano aos domingos.',
      imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
      openingTime: '08:30',
      closingTime: '17:00',
    ),
    Place(
      id: 'casa_bonecos_gigantes',
      citySlug: 'olinda',
      name: 'Casa dos Bonecos Gigantes de Olinda',
      category: 'cultura',
      lat: -8.0146,
      lon: -34.8514,
      durationMin: 45,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 95.0,
      ratingAvg: 4.7,
      ratingCount: 2900,
      likesCount: 5900,
      rankPosicao: 4,
      description: 'Espaço interativo com os icônicos bonecos de mais de 3 metros que descem as ladeiras no Carnaval de Olinda.',
      imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=800&q=80',
      openingTime: '09:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'quatro_cantos',
      citySlug: 'olinda',
      name: 'Quatro Cantos & Ladeiras Históricas',
      category: 'cultura',
      lat: -8.0162,
      lon: -34.8505,
      durationMin: 45,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 94.5,
      ratingAvg: 4.8,
      ratingCount: 3400,
      likesCount: 6200,
      rankPosicao: 5,
      description: 'O cruzamento mais famoso da folia olindense, cercado por casarios coloniais coloridos e ateliês de artistas plásticos.',
      imageUrl: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
      openingTime: '00:00',
      closingTime: '23:59',
    ),
    Place(
      id: 'oficina_do_sabor_olinda',
      citySlug: 'olinda',
      name: 'Restaurante Oficina do Sabor (Chef César Santos)',
      category: 'gastronomia',
      lat: -8.0140,
      lon: -34.8510,
      durationMin: 75,
      costLevel: 4,
      kidFriendly: true,
      mustSee: true,
      isLunch: true,
      score: 97.0,
      ratingAvg: 4.9,
      ratingCount: 3600,
      likesCount: 7800,
      rankPosicao: 6,
      description: 'Alta gastronomia pernambucana no Alto da Sé, famoso pelo jerimum recheado com camarão e frutos do mar com vista panorâmica.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
      openingTime: '12:00',
      closingTime: '23:00',
    ),
    Place(
      id: 'catedral_da_se',
      citySlug: 'olinda',
      name: 'Catedral da Sé de Olinda (Igreja de São Salvador)',
      category: 'cultura',
      lat: -8.0143,
      lon: -34.8518,
      durationMin: 45,
      costLevel: 1,
      kidFriendly: true,
      mustSee: false,
      isLunch: false,
      score: 95.5,
      ratingAvg: 4.8,
      ratingCount: 2800,
      likesCount: 5300,
      rankPosicao: 7,
      description: 'A mais antiga diocese do Brasil, sede episcopal desde 1676 com impressionante vista para a costa pernambucana.',
      imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
      openingTime: '08:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'mercado_da_ribeira',
      citySlug: 'olinda',
      name: 'Mercado da Ribeira & Galerias de Arte',
      category: 'cultura',
      lat: -8.0182,
      lon: -34.8512,
      durationMin: 45,
      costLevel: 1,
      kidFriendly: true,
      mustSee: false,
      isLunch: false,
      score: 93.0,
      ratingAvg: 4.6,
      ratingCount: 2100,
      likesCount: 4200,
      rankPosicao: 8,
      description: 'Construção colonial do século XVII com arcadas características, hoje abrigando lojas de artesanato, xilogravuras e oficinas de arte.',
      imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?auto=format&fit=crop&w=800&q=80',
      openingTime: '09:00',
      closingTime: '18:00',
    ),
  ];

  static const List<Place> _maceioPlaces = [
    Place(
      id: 'piscinas_pajucara',
      citySlug: 'maceio',
      name: 'Piscinas Naturais da Pajuçara',
      category: 'praias',
      lat: -9.6658,
      lon: -35.7153,
      durationMin: 120,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 98.5,
      ratingAvg: 4.9,
      ratingCount: 3850,
      likesCount: 7420,
      rankPosicao: 1,
      description: 'Passeio tradicional de jangada até as piscinas naturais de corais com águas mornas e peixes coloridos.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Paju%C3%A7ara_em_Macei%C3%B3._%285700883183%29.jpg/1280px-Paju%C3%A7ara_em_Macei%C3%B3._%285700883183%29.jpg',
      openingTime: '08:00',
      closingTime: '17:00',
    ),
    Place(
      id: 'farol_ponta_verde',
      citySlug: 'maceio',
      name: 'Farol da Ponta Verde',
      category: 'cultura',
      lat: -9.6585,
      lon: -35.6980,
      durationMin: 60,
      costLevel: 1,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 96.0,
      ratingAvg: 4.8,
      ratingCount: 2900,
      likesCount: 5800,
      rankPosicao: 2,
      description: 'Cartão-postal icônico de Maceió onde se pode caminhar sobre os arrecifes durante a maré baixa.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg/1280px-Farol_da_Ponta_Verde_-_Macei%C3%B3%2C_AL_%2852113641992%29.jpg',
      openingTime: '06:00',
      closingTime: '22:00',
    ),
    Place(
      id: 'praia_frances',
      citySlug: 'maceio',
      name: 'Praia do Francês',
      category: 'praias',
      lat: -9.7710,
      lon: -35.8420,
      durationMin: 150,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: false,
      score: 97.0,
      ratingAvg: 4.8,
      ratingCount: 3100,
      likesCount: 6200,
      rankPosicao: 3,
      description: 'Uma das praias mais famosas de Alagoas, dividida entre piscinas calmas de arrecifes e área de surf.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg/1280px-Praia_do_Franc%C3%AAs%2C_Marechal_Deodoro_01.jpg',
      openingTime: '07:00',
      closingTime: '18:00',
    ),
    Place(
      id: 'massagueira_gastronomia',
      citySlug: 'maceio',
      name: 'Polo Gastronômico da Massagueira',
      category: 'gastronomia',
      lat: -9.7340,
      lon: -35.8300,
      durationMin: 80,
      costLevel: 2,
      kidFriendly: true,
      mustSee: true,
      isLunch: true,
      score: 96.5,
      ratingAvg: 4.8,
      ratingCount: 2400,
      likesCount: 4900,
      rankPosicao: 4,
      description: 'Maior polo gastronômico à beira da lagoa no Nordeste, famoso pelos frutos do mar, sururu e doces típicos.',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg/1280px-P%C3%B4r_do_sol_da_Lagoa_Manguaba%2C_Marechal_Deodoro_-_AL.jpg',
      openingTime: '11:00',
      closingTime: '22:00',
    ),
  ];
}
