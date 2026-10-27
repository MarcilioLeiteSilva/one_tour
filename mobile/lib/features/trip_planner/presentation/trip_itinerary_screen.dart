import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ads/admob_service.dart';
import '../../../core/ads/hybrid_ad_banner.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/itinerary_models.dart';
import '../domain/trip_request.dart';
import '../services/local_db_service.dart';
import '../../social/services/social_service.dart';
import 'trip_planner_controller.dart';

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
      final uf = ref.read(flavorConfigProvider).uf;
      ref.read(adMobServiceProvider).preloadInterstitial(uf);
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
                icon: const Icon(Icons.rate_review_outlined),
                tooltip: 'Avaliar Roteiro',
                onPressed: () => _showTripReviewModal(context, plan),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartilhar Roteiro',
                onPressed: () {
                  ref.read(adMobServiceProvider).showInterstitial(
                    uf: config.uf,
                    onDismissed: () {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Card do roteiro gerado! Pronto para compartilhar.'),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Ver Rota no Mapa',
                onPressed: () => context.go('/mapa?filter=roteiro'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: plan.days.length > 4,
              indicatorColor: config.primaryColor,
              indicatorWeight: 3.5,
              labelColor: config.primaryColor,
              unselectedLabelColor: const Color(0xFF334155),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: List.generate(
                plan.days.length,
                (index) => Tab(text: l10n.dayTitle(index + 1)),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: plan.days.asMap().entries.map((entry) {
              final dayIndex = entry.key;
              final day = entry.value;
              return _buildDayTimeline(
                context,
                day,
                config,
                plan: plan,
                isLastDay: dayIndex == plan.days.length - 1,
              );
            }).toList(),
          ),
          bottomNavigationBar: const SafeArea(
            top: false,
            child: HybridAdBanner(position: 'itinerary_footer'),
          ),
        );
      },
    );
  }

  void _showPlaceReviewDialog(BuildContext context, Place place) {
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
                  const Icon(Icons.rate_review_outlined, color: Colors.amber, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Avaliar ${place.name}',
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
                      place.id,
                      selectedRating,
                      comment: commentCtrl.text.trim(),
                    );
                    await SocialService.instance.submitReview(
                      place.id,
                      selectedRating,
                      citySlug: place.citySlug,
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

  void _showTripReviewModal(BuildContext context, TripPlan plan, {ItineraryDay? currentDay}) {
    final stops = currentDay != null
        ? currentDay.stops.where((s) => !s.isLunch).toList()
        : plan.days.expand((d) => d.stops.where((s) => !s.isLunch)).toList();

    if (stops.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rate_review_rounded, color: Colors.amber, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentDay != null
                          ? 'Avaliar Atrações do Dia ${currentDay.dayNumber}'
                          : 'Avaliar Atrações do Roteiro',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha a atração visitada para registrar suas estrelas e comentário offline:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: stops.length,
                  separatorBuilder: (separatorCtx, index) => const Divider(height: 1),
                  itemBuilder: (itemCtx, index) {
                    final stop = stops[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          stop.place.imageUrl.isNotEmpty
                              ? stop.place.imageUrl
                              : 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=800&q=80',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (errCtx, err, stack) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.photo, size: 20, color: Colors.grey),
                          ),
                        ),
                      ),
                      title: Text(
                        stop.place.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${stop.place.citySlug.toUpperCase()} • ${stop.startTime}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: const Icon(Icons.star, size: 14, color: Colors.amber),
                        label: const Text('Avaliar'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showPlaceReviewDialog(context, stop.place);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayTimeline(
    BuildContext context,
    ItineraryDay day,
    FlavorConfig config, {
    required TripPlan plan,
    required bool isLastDay,
  }) {
    if (day.stops.isEmpty) {
      return const Center(child: Text('Nenhuma atração programada para este dia.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: day.stops.length + 1,
      itemBuilder: (context, index) {
        if (index == day.stops.length) {
          return _buildCompletionCard(context, day, plan, config, isLastDay);
        }

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
              onRate: () => _showPlaceReviewDialog(context, stop.place),
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

  Widget _buildCompletionCard(
    BuildContext context,
    ItineraryDay day,
    TripPlan plan,
    FlavorConfig config,
    bool isLastDay,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.primaryColor.withOpacity(0.08),
            config.secondaryColor.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.primaryColor.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLastDay ? '🎉 Roteiro Concluído!' : '✓ Dia ${day.dayNumber} Finalizado!',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      isLastDay
                          ? 'Você completou todas as paradas em ${plan.title}.'
                          : '${day.stops.where((s) => !s.isLunch).length} atrações visitadas hoje.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Como foi sua experiência? Avalie as atrações visitadas com estrelas e comentário. Seus votos são salvos offline e sincronizados com a Rede One Tour.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.star_rounded, color: Colors.amber),
              label: Text(
                isLastDay ? 'Avaliar Roteiro Completo' : 'Avaliar Atrações deste Dia',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => _showTripReviewModal(context, plan, currentDay: isLastDay ? null : day),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStop extends ConsumerWidget {
  final ItineraryStop stop;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onRate;

  const _TimelineStop({
    required this.stop,
    this.isFirst = false,
    this.isLast = false,
    this.onRate,
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
                              InkWell(
                                onTap: onRate,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${place.ratingAvg}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
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
