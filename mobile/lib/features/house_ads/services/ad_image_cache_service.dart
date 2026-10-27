import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Serviço responsável pelo armazenamento local persistente de imagens de anúncios.
/// Salva no diretório de Documentos do app (não no cache temporário), garantindo
/// resiliência mesmo se o usuário acionar "Limpar Cache" do Android.
class AdImageCacheService {
  static final AdImageCacheService instance = AdImageCacheService._internal();
  AdImageCacheService._internal();

  Directory? _cacheDir;
  final http.Client _client = http.Client();

  /// Inicializa e garante que o diretório persistente existe.
  Future<Directory> _getStorageDir() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      return _cacheDir!;
    }
    // Usa ApplicationDocumentsDirectory para não ser purgado pelo "Limpar Cache" do Android.
    final baseDir = await getApplicationDocumentsDirectory();
    final adDir = Directory(p.join(baseDir.path, 'house_ads_images'));
    if (!await adDir.exists()) {
      await adDir.create(recursive: true);
    }
    _cacheDir = adDir;
    return _cacheDir!;
  }

  /// Gera um nome de arquivo determinístico e seguro para a URL da imagem.
  String _filenameForUrl(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    final uri = Uri.tryParse(url);
    String ext = 'webp';
    if (uri != null && uri.path.contains('.')) {
      final potentialExt = uri.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(potentialExt)) {
        ext = potentialExt == 'jpeg' ? 'jpg' : potentialExt;
      }
    }
    return 'ad_$hash.$ext';
  }

  /// Retorna o arquivo local se já existir no disco.
  Future<File?> getLocalImageFile(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final dir = await _getStorageDir();
      final filename = _filenameForUrl(url);
      final file = File(p.join(dir.path, filename));
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }
    } catch (e) {
      debugPrint('⚠️ [AdImageCache] Erro ao verificar arquivo local: $e');
    }
    return null;
  }

  /// Baixa a imagem e salva no armazenamento local persistente.
  /// Se o usuário limpar o cache ou os dados, na próxima visualização online
  /// esta função baixa novamente e restaura a persistência.
  Future<File?> downloadAndCacheImage(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;

    try {
      final dir = await _getStorageDir();
      final filename = _filenameForUrl(url);
      final file = File(p.join(dir.path, filename));

      // Se já existe, retorna diretamente
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }

      // Download da imagem via HTTP
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        debugPrint('💾 [AdImageCache] Imagem salva localmente: $filename (${response.bodyBytes.length} bytes)');
        return file;
      }
    } catch (e) {
      debugPrint('ℹ️ [AdImageCache] Falha no download/cache da imagem ($url): $e');
    }
    return null;
  }

  /// Pré-carrega uma lista de URLs de imagens em segundo plano (quando conectado/Wi-Fi).
  Future<void> prefetchImages(List<String> urls) async {
    for (final url in urls) {
      if (url.isEmpty || !url.startsWith('http')) continue;
      try {
        final existing = await getLocalImageFile(url);
        if (existing == null) {
          await downloadAndCacheImage(url);
        }
      } catch (e) {
        // Silencioso em prefetch background
      }
    }
  }

  /// Limpa arquivos órfãos ou forçadamente se solicitado
  Future<void> clearAll() async {
    try {
      final dir = await _getStorageDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _cacheDir = null;
      }
    } catch (e) {
      debugPrint('⚠️ [AdImageCache] Erro ao limpar cache local de ads: $e');
    }
  }
}
