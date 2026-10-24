import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../explore/data/mock_pe_data.dart';
import '../../explore/presentation/explore_controller.dart';
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
            Consumer(
              builder: (context, ref, _) {
                final downloadedAsync = ref.watch(downloadedPacksProvider);
                final downloadedSet = downloadedAsync.value ?? {'recife'};

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: MockPeData.cities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final city = MockPeData.cities[index];
                    final isDownloaded = downloadedSet.contains(city.id);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDownloaded ? Colors.green.withOpacity(0.08) : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDownloaded ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDownloaded ? Icons.check_circle_rounded : Icons.download_for_offline_outlined,
                            color: isDownloaded ? Colors.green : config.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  isDownloaded
                                      ? 'Disponível offline (${city.packageSize})'
                                      : 'Tamanho estimado: ${city.packageSize}',
                                  style: TextStyle(
                                    color: isDownloaded ? Colors.green.shade700 : Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isDownloaded)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: config.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => context.push('/cidade/${city.id}'),
                              child: const Text('Baixar'),
                            )
                          else
                            TextButton(
                              onPressed: () => context.push('/cidade/${city.id}'),
                              child: const Text('Abrir', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
