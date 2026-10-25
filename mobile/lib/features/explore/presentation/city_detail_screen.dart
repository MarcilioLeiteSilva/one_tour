import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mock_pe_data.dart';
import '../../trip_planner/presentation/trip_wizard_modal.dart';
import '../../house_ads/presentation/house_ad_top_card.dart';
import '../../house_ads/services/house_ads_service.dart';
import '../../trip_planner/services/local_db_service.dart';
import '../../trip_planner/services/city_pack_download_service.dart';
import '../../trip_planner/presentation/trip_planner_controller.dart';
import '../../social/services/social_service.dart';
import '../services/explore_repository.dart';
import 'explore_controller.dart';

class CityDetailScreen extends ConsumerStatefulWidget {
  final String cityId;

  const CityDetailScreen({super.key, required this.cityId});

  @override
  ConsumerState<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends ConsumerState<CityDetailScreen> {
  bool _isDownloading = false;
  int _downloadProgress = 0;
  bool _isDownloaded = false;
  List<AttractionModel> _attractions = [];

  @override
  void initState() {
    super.initState();
    _loadCityData();
  }

  Future<void> _loadCityData() async {
    final isDl = await LocalDbService.instance.isCityDownloaded(widget.cityId);
    final atts = await MockPeData.getAttractionsForCity(widget.cityId);
    if (mounted) {
      setState(() {
        _isDownloaded = isDl;
        _attractions = atts;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final success = await CityPackDownloadService.instance.downloadCityPack(
      widget.cityId,
      onProgress: (percent) {
        if (!mounted) return;
        setState(() => _downloadProgress = percent);
      },
    );

    ref.invalidate(downloadedPacksProvider);

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = success;
      });

      if (success) {
        // Recarrega as atrações para refletir os dados recém-baixados
        final freshAtts = await ExploreRepository.instance.getAttractions(
          uf: 'PE',
          citySlug: widget.cityId,
        );
        if (mounted) {
          setState(() => _attractions = freshAtts);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('✓ Pacote SQLite e Mapa offline prontos para uso!'),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Falha ao baixar pacote. Verifique sua conexão à internet.'),
          ),
        );
      }
    }
  }

  Future<void> _removeDownload() async {
    await CityPackDownloadService.instance.removeCityPack(widget.cityId);
    ref.invalidate(downloadedPacksProvider);
    if (mounted) {
      setState(() {
        _isDownloaded = false;
        _downloadProgress = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pacote offline removido do dispositivo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);

    // Buscar dados da cidade
    final city = MockPeData.cities.firstWhere(
      (c) => c.id == widget.cityId,
      orElse: () => MockPeData.cities.first,
    );

    final cityAttractions = _attractions.isNotEmpty
        ? _attractions
        : MockPeData.topAttractions.where((a) => a.cityId == city.id).toList();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Header da Cidade
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    city.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(city.imageUrl, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo da Cidade
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botão de Download do Pacote Offline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDownloading
                              ? Colors.amber.withOpacity(0.12)
                              : (_isDownloaded || _downloadProgress == 100
                                  ? Colors.green.withOpacity(0.1)
                                  : config.primaryColor.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isDownloaded || _downloadProgress == 100
                                ? Colors.green.shade400
                                : config.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    _isDownloaded || _downloadProgress == 100
                                        ? Icons.check_circle_rounded
                                        : Icons.offline_pin_outlined,
                                    color: _isDownloaded || _downloadProgress == 100
                                        ? Colors.green.shade600
                                        : config.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isDownloaded || _downloadProgress == 100
                                              ? l10n.offlineAvailable
                                              : (_isDownloading
                                                  ? l10n.downloading(_downloadProgress)
                                                  : l10n.downloadGuide(city.packageSize)),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _isDownloaded || _downloadProgress == 100
                                                ? Colors.green.shade700
                                                : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Mapas vetoriais e dados 100% offline',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!_isDownloaded && _downloadProgress < 100)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  backgroundColor: config.primaryColor,
                                ),
                                onPressed: _isDownloading ? null : _startDownload,
                                child: Text(_isDownloading ? '$_downloadProgress%' : 'Baixar'),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                                tooltip: 'Remover pacote offline',
                                onPressed: _removeDownload,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Descrição
                      Text('Sobre o Destino', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(city.description, style: theme.textTheme.bodyMedium),

                      const SizedBox(height: 24),

                      // Destaque Patrocinado / House Ads Local
                      Consumer(
                        builder: (context, ref, _) {
                          final adsAsync = ref.watch(
                            houseAdsByPositionProvider(
                              HouseAdQuery(
                                uf: config.flavor.name.toUpperCase(),
                                city: city.id,
                                position: 'home_card',
                              ),
                            ),
                          );
                          return adsAsync.when(
                            data: (ads) => ads.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: HouseAdTopCard(ad: ads.first),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),

                      // Lista de Atrações na Cidade
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Principais Atrações', style: theme.textTheme.titleLarge),
                          Text('${cityAttractions.length} pontos', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (cityAttractions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Outras atrações sendo compiladas para o pacote offline.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cityAttractions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final att = cityAttractions[index];
                            return _CityAttractionItem(att: att);
                          },
                        ),

                      const SizedBox(height: 100), // Espaço para o FAB
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Botão Flutuante (FAB) Grande para Criar Roteiro
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: config.primaryColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: config.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                label: Text(
                  '${l10n.createSmartTrip} em ${city.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => TripWizardModal(cityName: city.name),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityAttractionItem extends ConsumerWidget {
  final AttractionModel att;

  const _CityAttractionItem({required this.att});

  void _showDetailModal(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.read(flavorConfigProvider);
    final isLiked = ref.watch(userLikesProvider).contains(att.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    att.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.place, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${att.rankPosition} no Estado • ${att.cityName}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${att.rating} (${att.reviewsCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  att.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${att.category} • Duração sugerida: ${att.durationMinutes} min',
                  style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  att.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'GPS: ${att.lat.toStringAsFixed(4)}, ${att.lon.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent,
                        ),
                        label: Text(isLiked ? 'Salvo' : 'Salvar'),
                        onPressed: () {
                          ref.read(userLikesProvider.notifier).toggleLike(att.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isLiked ? 'Removido dos salvos' : 'Adicionado aos seus favoritos offline!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                        label: const Text('Avaliar'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showReviewDialog(context, att);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, AttractionModel att) {
    double selectedRating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.rate_review_outlined, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Avaliar ${att.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Como foi sua experiência neste local?'),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDlgState(() => selectedRating = star.toDouble()),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Escreva seu comentário ou dica para outros viajantes...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await LocalDbService.instance.submitReview(
                      att.id,
                      selectedRating,
                      comment: commentCtrl.text.trim(),
                    );
                    await SocialService.instance.submitReview(
                      att.id,
                      selectedRating,
                      citySlug: att.cityId,
                    );
                    if (context.mounted) {
                      Navigator.pop(dlgCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('✓ Sua avaliação foi registrada e salva com sucesso!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showDetailModal(context, ref),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                att.imageUrl,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 75,
                  height: 75,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.place),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${att.rankPosition} Ranking',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            att.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    att.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${att.durationMinutes} min • ${att.category}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

