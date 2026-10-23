import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mock_pe_data.dart';
import '../../trip_planner/presentation/trip_wizard_modal.dart';

class CityDetailScreen extends ConsumerStatefulWidget {
  final String cityId;

  const CityDetailScreen({super.key, required this.cityId});

  @override
  ConsumerState<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends ConsumerState<CityDetailScreen> {
  bool _isDownloading = false;
  int _downloadProgress = 0;

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    // Simulação visual de download de pacote offline
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return false;
      setState(() {
        _downloadProgress += 20;
      });
      return _downloadProgress < 100;
    }).then((_) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✓ Pacote offline da cidade baixado com sucesso!'),
          ),
        );
      }
    });
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

    final cityAttractions = MockPeData.topAttractions
        .where((a) => a.cityId == city.id)
        .toList();

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
                              : (city.isDownloaded || _downloadProgress == 100
                                  ? Colors.green.withOpacity(0.1)
                                  : config.primaryColor.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: city.isDownloaded || _downloadProgress == 100
                                ? Colors.green.shade400
                                : config.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  city.isDownloaded || _downloadProgress == 100
                                      ? Icons.check_circle_rounded
                                      : Icons.offline_pin_outlined,
                                  color: city.isDownloaded || _downloadProgress == 100
                                      ? Colors.green.shade600
                                      : config.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      city.isDownloaded || _downloadProgress == 100
                                          ? l10n.offlineAvailable
                                          : (_isDownloading
                                              ? l10n.downloading(_downloadProgress)
                                              : l10n.downloadGuide(city.packageSize)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: city.isDownloaded || _downloadProgress == 100
                                            ? Colors.green.shade700
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      'Mapas vetoriais e dados 100% offline',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!city.isDownloaded && _downloadProgress < 100)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  backgroundColor: config.primaryColor,
                                ),
                                onPressed: _isDownloading ? null : _startDownload,
                                child: Text(_isDownloading ? '$_downloadProgress%' : 'Baixar'),
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

class _CityAttractionItem extends StatelessWidget {
  final AttractionModel att;

  const _CityAttractionItem({required this.att});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                ),
                const SizedBox(height: 2),
                Text(
                  '${att.durationMinutes} min • ${att.category}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
