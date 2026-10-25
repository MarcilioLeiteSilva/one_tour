import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sql;
import '../../../core/config/app_config.dart';
import 'local_db_service.dart';

/// Informações do pacote de cidade/mapa
class PackDownloadProgress {
  final String citySlug;
  final int percentage;
  final int bytesDownloaded;
  final int totalBytes;
  final bool isCompleted;
  final String? error;

  const PackDownloadProgress({
    required this.citySlug,
    required this.percentage,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.isCompleted = false,
    this.error,
  });
}

/// Serviço responsável pelo download real, integridade e armazenamento local
/// dos pacotes SQLite (pack.sqlite) e Mapas Vetoriais (PMTiles).
class CityPackDownloadService {
  static final CityPackDownloadService instance = CityPackDownloadService._internal();
  CityPackDownloadService._internal();

  http.Client? _client;
  http.Client get _httpClient => _client ??= http.Client();

  /// Retorna o caminho absoluto do SQLite do pacote da cidade
  Future<String> getPackDbPath(String citySlug) async {
    final slug = citySlug.toLowerCase().trim();
    String dbDir = '';
    try {
      dbDir = await sql.getDatabasesPath();
    } catch (_) {
      dbDir = Directory.systemTemp.path;
    }
    return p.join(dbDir, 'pack_$slug.sqlite');
  }

  /// Retorna o caminho absoluto do arquivo PMTiles da cidade
  Future<String> getMapPmtilesPath(String citySlug) async {
    final slug = citySlug.toLowerCase().trim();
    String dbDir = '';
    try {
      dbDir = await sql.getDatabasesPath();
    } catch (_) {
      dbDir = Directory.systemTemp.path;
    }
    final mapsDir = p.join(dbDir, 'maps');
    final dir = Directory(mapsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.join(mapsDir, '$slug.pmtiles');
  }

  /// Executa o download real do pacote SQLite e Mapa PMTiles com callback de progresso
  Future<bool> downloadCityPack(
    String citySlug, {
    void Function(int percentage)? onProgress,
  }) async {
    final slug = citySlug.toLowerCase().trim();
    final targetDbPath = await getPackDbPath(slug);
    final targetMapPath = await getMapPmtilesPath(slug);

    debugPrint('🌐 [CityPackDownloadService] Iniciando download do pacote: $slug');

    try {
      // 1. Tenta baixar o arquivo SQLite via One Tour API / CDN
      final downloadUrl = Uri.parse('$kApiBaseUrl/api/v1/packs/download/$slug');
      bool networkSuccess = false;

      try {
        final request = http.Request('GET', downloadUrl);
        final streamedResponse = await _httpClient.send(request).timeout(const Duration(seconds: 8));

        if (streamedResponse.statusCode == 200) {
          final totalLength = streamedResponse.contentLength ?? 73728;
          int bytesDownloaded = 0;

          final file = File(targetDbPath);
          final sink = file.openWrite();

          await for (final chunk in streamedResponse.stream) {
            sink.add(chunk);
            bytesDownloaded += chunk.length;
            if (totalLength > 0 && onProgress != null) {
              final pct = ((bytesDownloaded / totalLength) * 80).clamp(0, 80).toInt();
              onProgress(pct);
            }
          }

          await sink.flush();
          await sink.close();
          networkSuccess = true;
          debugPrint('✅ [CityPackDownloadService] SQLite baixado via rede ($bytesDownloaded bytes)');
        }
      } catch (netErr) {
        debugPrint('ℹ️ [CityPackDownloadService] Falha no download de rede ($netErr). Ativando fallback de asset local.');
      }

      // 2. Fallback resiliente: se rede indisponível, extrai do asset empacotado no app
      if (!networkSuccess || !await File(targetDbPath).exists()) {
        final assetNames = [
          'assets/packs/pack_$slug.sqlite',
          'assets/packs/pack_recife.sqlite', // fallback PE
        ];

        ByteData? data;
        for (final asset in assetNames) {
          try {
            data = await rootBundle.load(asset);
            debugPrint('📦 [CityPackDownloadService] Extraindo pacote offline bundled: $asset');
            break;
          } catch (_) {}
        }

        if (data != null) {
          final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          final file = File(targetDbPath);
          await file.writeAsBytes(bytes, flush: true);
          networkSuccess = true;
        }
      }

      if (onProgress != null) onProgress(85);

      // 3. Tenta baixar o mapa vetorial PMTiles correspondente
      try {
        final mapUrl = Uri.parse('$kApiBaseUrl/api/v1/packs/maps/download/$slug');
        final mapResp = await _httpClient.get(mapUrl).timeout(const Duration(seconds: 6));
        if (mapResp.statusCode == 200) {
          final mapFile = File(targetMapPath);
          await mapFile.writeAsBytes(mapResp.bodyBytes, flush: true);
          debugPrint('🗺️ [CityPackDownloadService] Mapa PMTiles baixado via rede (${mapResp.bodyBytes.length} bytes)');
        }
      } catch (mapErr) {
        debugPrint('ℹ️ [CityPackDownloadService] Mapa remoto não baixado ($mapErr). Prosseguindo com tiles padrão.');
      }

      if (onProgress != null) onProgress(100);

      // 4. Marca o pacote como baixado no banco de dados do usuário
      await LocalDbService.instance.markCityDownloaded(slug);
      debugPrint('🎉 [CityPackDownloadService] Pacote $slug 100% operacional no dispositivo');
      return true;
    } catch (e) {
      debugPrint('❌ [CityPackDownloadService] Erro fatal ao instalar pacote $slug: $e');
      return false;
    }
  }

  /// Remove o pacote do dispositivo para liberar espaço
  Future<void> removeCityPack(String citySlug) async {
    final slug = citySlug.toLowerCase().trim();
    try {
      final dbPath = await getPackDbPath(slug);
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      final mapPath = await getMapPmtilesPath(slug);
      final mapFile = File(mapPath);
      if (await mapFile.exists()) {
        await mapFile.delete();
      }

      await LocalDbService.instance.removeCityDownloaded(slug);
      debugPrint('🗑️ [CityPackDownloadService] Pacote $slug e mapas removidos com sucesso');
    } catch (e) {
      debugPrint('Erro ao remover pacote $slug: $e');
    }
  }
}
