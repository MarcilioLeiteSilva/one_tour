import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import 'trip_wizard_modal.dart';

class TripPlannerScreen extends ConsumerWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crie seu Roteiro Inteligente em Segundos',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Itinerários completos organizados por proximidade e tempo para aproveitar ao máximo ${config.stateName}.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
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
                      builder: (context) => const TripWizardModal(cityName: 'Recife & Região'),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text('Roteiros Recentes & Sugestões', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          // Card de Roteiro Existente
          GestureDetector(
            onTap: () => context.push('/roteiro/pe_recife_3dias'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recife Histórico e Praias',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3 dias • 12 atrações • Ritmo Moderado',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Pronto para uso offline',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
