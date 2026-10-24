import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/itinerary_models.dart';
import '../domain/trip_request.dart';
import 'trip_planner_controller.dart';
import '../../house_ads/presentation/house_ad_interstitial_modal.dart';
import '../../house_ads/services/house_ads_service.dart';

class TripItineraryScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripItineraryScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends ConsumerState<TripItineraryScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _lastDaysCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePlanLoaded();
    });
  }

  void _ensurePlanLoaded() {
    final currentPlan = ref.read(currentTripPlanProvider).value;
    if (currentPlan == null || currentPlan.id != widget.tripId) {
      if (widget.tripId == 'roteiro_demo') {
        ref.read(currentTripPlanProvider.notifier).generateTrip(
              const TripRequest(cityName: 'Recife', days: 3),
            );
      } else {
        ref.read(currentTripPlanProvider.notifier).loadTripById(widget.tripId);
      }
    }
  }

  void _updateTabController(int daysCount) {
    if (_tabController == null || _lastDaysCount != daysCount) {
      _tabController?.dispose();
      _tabController = TabController(length: daysCount, vsync: this);
      _lastDaysCount = daysCount;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final planAsync = ref.watch(currentTripPlanProvider);

    return planAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Carregando Roteiro...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Erro no Roteiro')),
        body: Center(child: Text('Não foi possível carregar o roteiro: $err')),
      ),
      data: (plan) {
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Roteiro não encontrado')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(currentTripPlanProvider.notifier).generateTrip(
                        const TripRequest(cityName: 'Recife', days: 3),
                      );
                },
                child: const Text('Gerar Roteiro Sugerido'),
              ),
            ),
          );
        }

        _updateTabController(plan.days.length);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${plan.daysCount} ${plan.daysCount == 1 ? 'Dia' : 'Dias'} • ${plan.totalStopsCount} paradas • 100% Offline',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () async {
                  final ads = await ref.read(houseAdsServiceProvider).getAds(
                        uf: config.flavor.name.toUpperCase(),
                        position: 'interstitial',
                      );
                  if (context.mounted && ads.isNotEmpty) {
                    HouseAdInterstitialModal.show(context, ads.first);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Card do roteiro gerado! Pronto para compartilhar.'),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: () => context.go('/mapa'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: plan.days.length > 4,
              indicatorColor: config.primaryColor,
              labelColor: config.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: List.generate(
                plan.days.length,
                (index) => Tab(text: l10n.dayTitle(index + 1)),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: plan.days.map((day) {
              return _buildDayTimeline(context, day, config);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDayTimeline(
    BuildContext context,
    ItineraryDay day,
    FlavorConfig config,
  ) {
    if (day.stops.isEmpty) {
      return const Center(child: Text('Nenhuma atração programada para este dia.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: day.stops.length,
      itemBuilder: (context, index) {
        final stop = day.stops[index];
        final isFirst = index == 0;
        final isLast = index == day.stops.length - 1;

        if (stop.isLunch) {
          return Column(
            children: [
              _LunchStop(
                time: stop.startTime,
                title: '🍽️ Pausa Almoço: ${stop.place.name}',
                subtitle: stop.place.description.isNotEmpty
                    ? stop.place.description
                    : 'Polo Gastronômico Regional (${stop.place.durationMin} min)',
                imageUrl: stop.place.imageUrl,
              ),
              if (stop.transitToNext != null)
                _TransitIndicator(
                  text: stop.transitToNext!.labelFormatted,
                  isWalk: stop.transitToNext!.isWalk,
                ),
            ],
          );
        }

        return Column(
          children: [
            _TimelineStop(
              stop: stop,
              isFirst: isFirst,
              isLast: isLast && stop.transitToNext == null,
            ),
            if (stop.transitToNext != null)
              _TransitIndicator(
                text: stop.transitToNext!.labelFormatted,
                isWalk: stop.transitToNext!.isWalk,
              ),
          ],
        );
      },
    );
  }
}

class _TimelineStop extends ConsumerWidget {
  final ItineraryStop stop;
  final bool isFirst;
  final bool isLast;

  const _TimelineStop({
    required this.stop,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = stop.place;
    final isLiked = ref.watch(userLikesProvider).contains(place.id);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna do Horário
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.startTime,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'até ${stop.endTime}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
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
            if (!isLast)
              Container(
                width: 2,
                height: 94,
                color: Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Card da Atração
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
                  child: Image.network(
                    place.imageUrl.isNotEmpty
                        ? place.imageUrl
                        : 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=800&q=80',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.photo, color: Colors.grey),
                    ),
                  ),
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
                            '#${place.rankPosicao} em ${place.citySlug.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                '${place.ratingAvg}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  ref.read(userLikesProvider.notifier).toggleLike(place.id);
                                },
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 16,
                                  color: isLiked ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${place.durationMin} min visita',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                          if (place.kidFriendly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Kids',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
      padding: const EdgeInsets.only(left: 64, bottom: 8),
      child: Row(
        children: [
          Icon(
            isWalk ? Icons.directions_walk : Icons.directions_car,
            size: 16,
            color: Colors.grey.shade600,
          ),
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
  final String imageUrl;

  const _LunchStop({
    required this.time,
    required this.title,
    required this.subtitle,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
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
        const SizedBox(width: 12),
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
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
