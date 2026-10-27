import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/trip_request.dart';
import '../services/local_db_service.dart';
import '../../shell/presentation/app_drawer.dart';
import 'trip_planner_controller.dart';
import 'trip_wizard_modal.dart';

class TripPlannerScreen extends ConsumerWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final savedTripsAsync = ref.watch(savedTripsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu Principal',
          ),
        ),
        title: Text(l10n.tabItineraries),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner de Criação Rápida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [config.primaryColor, config.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: config.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '100% OFFLINE & GRATUITO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crie seu Roteiro Inteligente em Segundos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Itinerários completos organizados por proximidade e tempo para aproveitar ao máximo ${config.stateName}.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: config.primaryColor,
                  ),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Montar Novo Roteiro'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TripWizardModal(cityName: config.capital),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Seção: Sugestões dos Especialistas
          Text('Sugestões Prontas dos Especialistas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: config.uf == 'AL'
                  ? [
                      _buildPresetTripCard(
                        context: context,
                        ref: ref,
                        theme: theme,
                        config: config,
                        title: 'Maceió Orla & Piscinas',
                        city: 'Maceió',
                        days: 3,
                        imageUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=800&q=80',
                      ),
                      const SizedBox(width: 12),
                      _buildPresetTripCard(
                        context: context,
                        ref: ref,
                        theme: theme,
                        config: config,
                        title: 'Maragogi Galés de Corais',
                        city: 'Maragogi',
                        days: 2,
                        imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
                      ),
                      const SizedBox(width: 12),
                      _buildPresetTripCard(
                        context: context,
                        ref: ref,
                        theme: theme,
                        config: config,
                        title: 'Milagres Rota Ecológica',
                        city: 'São Miguel dos Milagres',
                        days: 2,
                        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
                      ),
                    ]
                  : (config.uf == 'PE'
                      ? [
                          _buildPresetTripCard(
                            context: context,
                            ref: ref,
                            theme: theme,
                            config: config,
                            title: 'Recife Cultural & Pontes',
                            city: 'Recife',
                            days: 3,
                            imageUrl: 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=800&q=80',
                          ),
                          const SizedBox(width: 12),
                          _buildPresetTripCard(
                            context: context,
                            ref: ref,
                            theme: theme,
                            config: config,
                            title: 'Porto de Galinhas & Jangadas',
                            city: 'Porto de Galinhas',
                            days: 2,
                            imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
                          ),
                          const SizedBox(width: 12),
                          _buildPresetTripCard(
                            context: context,
                            ref: ref,
                            theme: theme,
                            config: config,
                            title: 'Olinda Barroca & Ladeiras',
                            city: 'Olinda',
                            days: 1,
                            imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
                          ),
                          const SizedBox(width: 12),
                          _buildPresetTripCard(
                            context: context,
                            ref: ref,
                            theme: theme,
                            config: config,
                            title: 'Noronha Paraíso Ecológico',
                            city: 'Fernando de Noronha',
                            days: 2,
                            imageUrl: 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=800&q=80',
                          ),
                        ]
                      : [
                          _buildPresetTripCard(
                            context: context,
                            ref: ref,
                            theme: theme,
                            config: config,
                            title: '${config.capital} Destaques & Roteiro',
                            city: config.capital,
                            days: 3,
                            imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
                          ),
                        ]),
            ),
          ),

          const SizedBox(height: 28),
          Text('Meus Roteiros Salvos (Offline)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          savedTripsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Erro ao carregar roteiros: $err')),
            data: (trips) {
              if (trips.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.route_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum roteiro salvo ainda.\nToque em "Montar Novo Roteiro" ou escolha uma sugestão acima!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: trips.map((trip) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        ref.read(currentTripPlanProvider.notifier).setPlan(trip);
                        context.push('/roteiro/${trip.id}');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: config.primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.map_rounded, color: config.primaryColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${trip.daysCount} dias • ${trip.totalStopsCount} paradas • ${trip.pace.labelPt}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir Roteiro?'),
                                    content: Text('Deseja excluir "${trip.title}" do armazenamento offline?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await LocalDbService.instance.deleteSavedTrip(trip.id);
                                  ref.invalidate(savedTripsProvider);
                                }
                              },
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTripCard({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeData theme,
    required dynamic config,
    required String title,
    required String city,
    required int days,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () async {
        final plan = await ref.read(currentTripPlanProvider.notifier).generateTrip(
              TripRequest(cityName: city, days: days),
            );
        if (context.mounted && plan != null) {
          context.push('/roteiro/${plan.id}');
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.photo),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$days ${days == 1 ? 'dia' : 'dias'} • Roteiro Inteligente',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.bolt, color: config.primaryColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Gerar com 1 toque',
                  style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
