import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../../l10n/app_localizations.dart';

class TripItineraryScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripItineraryScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends ConsumerState<TripItineraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recife Histórico e Praias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Roteiro Otimizado de 3 Dias', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card do roteiro pronto para compartilhar!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.go('/mapa'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: config.primaryColor,
          labelColor: config.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: l10n.dayTitle(1)),
            Tab(text: l10n.dayTitle(2)),
            Tab(text: l10n.dayTitle(3)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDay1Timeline(context, l10n, config),
          _buildDay2Timeline(context, l10n, config),
          _buildDay3Timeline(context, l10n, config),
        ],
      ),
    );
  }

  Widget _buildDay1Timeline(BuildContext context, AppLocalizations l10n, FlavorConfig config) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TimelineStop(
          time: '09:00',
          title: 'Praça do Marco Zero',
          category: 'Cultura & História',
          duration: '1h30 visita',
          imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80',
          rating: 4.9,
          rank: 1,
          isFirst: true,
        ),
        _TransitIndicator(text: l10n.walkTime(8, '600m'), isWalk: true),
        _TimelineStop(
          time: '10:45',
          title: 'Rua do Bom Jesus e Sinagoga',
          category: 'Patrimônio',
          duration: '1h visita',
          imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
          rating: 4.8,
          rank: 3,
        ),
        _TransitIndicator(text: l10n.walkTime(4, '300m'), isWalk: true),
        // Almoço
        _LunchStop(
          time: '12:00',
          title: l10n.lunchBreak,
          subtitle: 'Polo Gastronômico do Bairro do Recife (Culinária Típica)',
        ),
        _TransitIndicator(text: l10n.walkTime(6, '450m'), isWalk: true),
        _TimelineStop(
          time: '13:30',
          title: 'Museu Cais do Sertão',
          category: 'Cultura & Música',
          duration: '2h visita',
          imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
          rating: 4.8,
          rank: 5,
        ),
        _TransitIndicator(text: l10n.driveTime(15, '4.5 km'), isWalk: false),
        _TimelineStop(
          time: '16:00',
          title: 'Praia de Boa Viagem & Pôr do Sol',
          category: 'Praias',
          duration: '1h30 visita',
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
          rating: 4.7,
          rank: 8,
          isLast: true,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildDay2Timeline(BuildContext context, AppLocalizations l10n, FlavorConfig config) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TimelineStop(
          time: '09:00',
          title: 'Alto da Sé de Olinda',
          category: 'História & Mirante',
          duration: '1h30 visita',
          imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
          rating: 4.8,
          rank: 3,
          isFirst: true,
        ),
        _TransitIndicator(text: l10n.walkTime(10, '700m'), isWalk: true),
        _TimelineStop(
          time: '10:45',
          title: 'Mosteiro de São Bento',
          category: 'Arte Sacra',
          duration: '1h visita',
          imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80',
          rating: 4.8,
          rank: 7,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildDay3Timeline(BuildContext context, AppLocalizations l10n, FlavorConfig config) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TimelineStop(
          time: '08:30',
          title: 'Piscinas Naturais de Porto de Galinhas',
          category: 'Praias & Natureza',
          duration: '3h visita',
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
          rating: 4.9,
          rank: 2,
          isFirst: true,
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineStop extends StatelessWidget {
  final String time;
  final String title;
  final String category;
  final String duration;
  final String imageUrl;
  final double rating;
  final int rank;
  final bool isFirst;
  final bool isLast;

  const _TimelineStop({
    required this.time,
    required this.title,
    required this.category,
    required this.duration,
    required this.imageUrl,
    required this.rating,
    required this.rank,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna do Horário
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        // Linha do tempo
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            Container(
              width: 2,
              height: 100,
              color: Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
        const SizedBox(width: 14),
        // Card do Ponto
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#$rank no Estado',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              Text('$rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(duration, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransitIndicator extends StatelessWidget {
  final String text;
  final bool isWalk;

  const _TransitIndicator({required this.text, this.isWalk = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 58, bottom: 8),
      child: Row(
        children: [
          Icon(isWalk ? Icons.directions_walk : Icons.directions_car, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LunchStop extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;

  const _LunchStop({required this.time, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant, size: 8, color: Colors.white),
            ),
            Container(width: 2, height: 60, color: Colors.grey.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      Text(subtitle, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
