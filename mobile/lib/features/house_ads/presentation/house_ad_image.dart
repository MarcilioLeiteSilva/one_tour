import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ad_image_cache_service.dart';

/// Componente visual resiliente para imagens de anúncios House Ads.
/// 1. Prioriza exibição do arquivo salvo em armazenamento local (100% offline).
/// 2. Se não estiver salvo localmente e houver conexão, exibe a imagem via rede
///    e efetua o download em background para persistência definitiva.
/// 3. Se o usuário limpar o cache do celular, ao abrir novamente com internet/Wi-Fi,
///    o componente baixa e salva o arquivo novamente.
/// 4. Se estiver offline e sem imagem em disco, renderiza um fallback sofisticado.
class HouseAdImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const HouseAdImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  @override
  State<HouseAdImage> createState() => _HouseAdImageState();
}

class _HouseAdImageState extends State<HouseAdImage> {
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _checkAndLoadImage();
  }

  @override
  void didUpdateWidget(covariant HouseAdImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _checkAndLoadImage();
    }
  }

  Future<void> _checkAndLoadImage() async {
    if (widget.imageUrl.isEmpty) return;

    // 1. Verifica se já está salvo no armazenamento local persistente
    final cached = await AdImageCacheService.instance.getLocalImageFile(widget.imageUrl);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _localFile = cached;
        });
      }
      return;
    }

    // 2. Se não está no disco, dispara o download e salvamento persistente
    AdImageCacheService.instance.downloadAndCacheImage(widget.imageUrl).then((file) {
      if (file != null && mounted) {
        setState(() {
          _localFile = file;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_localFile != null && _localFile!.existsSync()) {
      // Exibe direto do disco local (Instantâneo e 100% Offline)
      content = Image.file(
        _localFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (widget.imageUrl.isNotEmpty && widget.imageUrl.startsWith('http')) {
      // Exibe via rede enquanto salva no disco em segundo plano
      content = Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade900,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      content = _buildFallback();
    }

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildFallback() {
    if (widget.fallback != null) return widget.fallback!;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.campaign_outlined, size: 36, color: Colors.white54),
      ),
    );
  }
}
