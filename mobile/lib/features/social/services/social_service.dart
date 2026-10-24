import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../trip_planner/services/local_db_service.dart';
import '../domain/place_stats.dart';

/// Offline-first bridge to the One Tour API.
///
/// * Every user action (like, review, ad impression/click) is written to a local
///   outbox first and flushed in batches whenever the network allows.
/// * Community stats (rating, likes, rankings) are cached locally and refreshed
///   from the API, so they can be shown without a connection.
class SocialService {
  static final SocialService instance = SocialService._internal();
  SocialService._internal();

  final http.Client _client = http.Client();
  final LocalDbService _db = LocalDbService.instance;

  static const _deviceIdKey = 'device_id';
  static const _batchSize = 100;
  static const _impressionDedupe = Duration(seconds: 60);

  String _uf = 'PE';
  String? _deviceId;
  Timer? _timer;
  bool _flushing = false;
  bool _refreshing = false;
  final Map<String, DateTime> _recentImpressions = {};

  /// Called after fresh stats arrive so the UI can rebuild.
  VoidCallback? onStatsUpdated;

  /// Loads cached stats, then syncs in the background and keeps syncing.
  Future<void> start({required String uf}) async {
    _uf = uf.toUpperCase();
    await _loadCachedStats();
    unawaited(syncNow());
    _timer ??= Timer.periodic(const Duration(minutes: 5), (_) => syncNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncNow() async {
    await flush();
    await refreshStats();
  }

  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  /// Anonymous, persistent identifier for this installation.
  Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    var id = await _db.getMeta(_deviceIdKey);
    if (id == null || id.isEmpty) {
      final rnd = Random.secure();
      final hex = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      id = 'dev_$hex';
      await _db.setMeta(_deviceIdKey, id);
    }
    _deviceId = id;
    return id;
  }

  // ---------------------------------------------------------------------------
  // Recording user actions
  // ---------------------------------------------------------------------------

  Future<void> recordLike(String placeId, {String? citySlug, required bool liked}) {
    return _enqueue({
      'kind': liked ? 'like' : 'unlike',
      'place_id': placeId,
      'city_slug': citySlug ?? '',
    });
  }

  /// Stores the rating locally (no free-text comments are collected) and queues it.
  Future<void> submitReview(String placeId, double stars, {String? citySlug}) async {
    await _db.submitReview(placeId, stars);
    await _enqueue({
      'kind': 'review',
      'place_id': placeId,
      'city_slug': citySlug ?? '',
      'stars': stars.round().clamp(1, 5),
    });
  }

  Future<void> recordAdImpression(String adId, String position, {String? citySlug, String? uf}) {
    final key = '$adId|$position';
    final now = DateTime.now();
    final last = _recentImpressions[key];
    if (last != null && now.difference(last) < _impressionDedupe) return Future.value();
    _recentImpressions[key] = now;
    return _enqueue({
      'kind': 'ad_impression',
      'ad_id': adId,
      'position': position,
      'city_slug': citySlug ?? '',
      'uf': uf ?? _uf,
    });
  }

  Future<void> recordAdClick(String adId, String position, {String? citySlug, String? uf}) {
    return _enqueue({
      'kind': 'ad_click',
      'ad_id': adId,
      'position': position,
      'city_slug': citySlug ?? '',
      'uf': uf ?? _uf,
    });
  }

  Future<void> _enqueue(Map<String, dynamic> event) async {
    try {
      event['uf'] ??= _uf;
      await _db.enqueueEvent(jsonEncode(event));
      unawaited(flush());
    } catch (e) {
      debugPrint('SocialService: failed to enqueue event ($e)');
    }
  }

  // ---------------------------------------------------------------------------
  // Outbox flush
  // ---------------------------------------------------------------------------

  /// Sends pending events in order. Network/server failures keep them queued;
  /// a 4xx (other than 429) means the batch is malformed, so it is dropped to
  /// avoid blocking the queue forever.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final device = await deviceId();
      while (true) {
        final rows = await _db.getPendingEvents(limit: _batchSize);
        if (rows.isEmpty) break;

        final ids = rows.map((r) => (r['id'] as num).toInt()).toList();
        final events = rows.map((r) => jsonDecode(r['payload'] as String)).toList();

        final response = await _client
            .post(
              Uri.parse('$kApiBaseUrl/api/v1/telemetry/batch'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'device_id': device,
                'uf': _uf,
                'platform': defaultTargetPlatform.name,
                'events': events,
              }),
            )
            .timeout(const Duration(seconds: 10));

        final status = response.statusCode;
        if (status >= 200 && status < 300) {
          await _db.deletePendingEvents(ids);
        } else if (status >= 400 && status < 500 && status != 429) {
          debugPrint('SocialService: dropping malformed batch (HTTP $status)');
          await _db.deletePendingEvents(ids);
        } else {
          break; // retry later
        }
        if (rows.length < _batchSize) break;
      }
    } catch (e) {
      debugPrint('SocialService: flush deferred ($e)');
    } finally {
      _flushing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Community stats
  // ---------------------------------------------------------------------------

  Future<void> _loadCachedStats() async {
    try {
      final cached = await _db.loadStatsCache();
      SocialStatsRegistry.instance.replaceAll(cached.map(PlaceStats.fromJson));
    } catch (e) {
      debugPrint('SocialService: could not read stats cache ($e)');
    }
  }

  Future<void> refreshStats() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final response = await _client
          .get(Uri.parse('$kApiBaseUrl/api/v1/places/stats?uf=$_uf'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = (body['data'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      SocialStatsRegistry.instance.replaceAll(data.map(PlaceStats.fromJson));
      await _db.replaceStatsCache(data);
      onStatsUpdated?.call();
    } catch (e) {
      debugPrint('SocialService: stats refresh deferred ($e)');
    } finally {
      _refreshing = false;
    }
  }
}
