import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../explore/data/mock_pe_data.dart';
import '../../trip_planner/presentation/trip_planner_controller.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final likedIds = ref.watch(userLikesProvider);

    // Filter attractions matching the liked place IDs (or top ones if empty)
    final allAttractions = MockPeData.topAttractions;
    final savedItems = likedIds.isEmpty
        ? allAttractions.take(2).toList()
        : allAttractions.where((a) => likedIds.contains(a.id)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabSaved),
          bottom: TabBar(
            indicatorColor: config.primaryColor,
            labelColor: config.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Meus Favoritos (❤️)'),
              Tab(text: 'Pacotes Offline (⬇)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba 1: Favoritos Curtidos
            if (savedItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Você ainda não favoritou nenhuma atração.\nToque no coração (❤️) em qualquer atração para salvá-la offline!',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: savedItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = savedItems[index];
                  final isLiked = likedIds.contains(item.id);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrl,
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 75,
                              height: 75,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.photo),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.cityName} • ${item.category}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  Text(
                                    ' ${item.rating}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.favorite, size: 13, color: Colors.red.shade400),
                                  Text(
                                    ' Salvo',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            ref.read(userLikesProvider.notifier).toggleLike(item.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Aba 2: Pacotes Offline Baixados
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recife e Região Metropolitana',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Pacote pack.sqlite + map.pmtiles (14 MB)',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pacote integrado do sistema. Mantido para navegação offline.'),
                            ),
                          );
                        },
                        child: const Text('Detalhes', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.download_for_offline_outlined, color: config.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Porto de Galinhas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Tamanho estimado: 9 MB',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => context.push('/cidade/porto_de_galinhas'),
                        child: const Text('Baixar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
