import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ads/hybrid_ad_banner.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mock_pe_data.dart';
import '../../house_ads/presentation/house_ad_banner.dart';
import '../../house_ads/services/house_ads_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../trip_planner/presentation/trip_planner_controller.dart';
import '../../shell/presentation/app_drawer.dart';
import 'explore_controller.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryChip(String key, String emoji, String label, Color primaryColor) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // App Bar Moderna com Identidade do Estado
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            pinned: false,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [config.primaryColor.withOpacity(0.08), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (drawerCtx) => Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.menu_rounded, size: 22),
                          onPressed: () => Scaffold.of(drawerCtx).openDrawer(),
                          tooltip: 'Menu Principal',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: config.secondaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  config.uf,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  config.appName,
                                  style: theme.textTheme.headlineSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.orange.shade400),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${config.capital} • 29°C Ensolarado',
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone de Notificações com Badge
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.notifications_outlined, size: 20),
                              ),
                              if (ref.watch(unreadNotificationsCountProvider) > 0)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () => context.push('/notificacoes'),
                          tooltip: 'Avisos & Promoções',
                        ),
                        // Atalho Rápido para Configurações
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.settings_outlined, size: 20),
                          ),
                          onPressed: () => context.push('/configuracoes'),
                          tooltip: 'Configurações',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conteúdo do Feed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de Busca Interativa
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(isDark ? 0.2 : 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                            decoration: InputDecoration(
                              hintText: l10n.searchPlaceholder,
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.map_outlined, color: config.primaryColor, size: 20),
                            onPressed: () => context.go('/mapa'),
                            tooltip: 'Ver no Mapa',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tags de Categorias em Chips Interativas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('todas', '🌟', 'Todas', config.primaryColor),
                        _buildCategoryChip('praia', '🏖️', l10n.interestBeach, config.primaryColor),
                        _buildCategoryChip('cultura', '🏛️', l10n.interestCulture, config.primaryColor),
                        _buildCategoryChip('gastro', '🍲', l10n.interestGastronomy, config.primaryColor),
                        _buildCategoryChip('natureza', '🌿', l10n.interestNature, config.primaryColor),
                        _buildCategoryChip('noite', '🎉', l10n.interestNightlife, config.primaryColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seção: Cidades Polo em Destaque
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.topDestinations, style: theme.textTheme.titleLarge),
                      Text(
                        'Ver todas (${MockPeData.cities.length})',
                        style: TextStyle(
                          color: config.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Carrossel de Cidades
                  SizedBox(
                    height: 230,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final citiesAsync = ref.watch(citiesProvider);
                        final cities = citiesAsync.value ?? MockPeData.cities;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cities.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final city = cities[index];
                            return _CityCard(city: city);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bloco Híbrido: AdMob Banner com Fallback House Ads
                  const HybridAdBanner(position: 'attraction_banner'),

                  const SizedBox(height: 24),

                  // Seção: Mais Amados e Votados (Social Proof & Ranking)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.topRated, style: theme.textTheme.titleLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Top 5 Social',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Feed Vertical de Atrações Ranqueadas
                  Consumer(
                    builder: (context, ref, _) {
                      final attractionsAsync = ref.watch(curatedAttractionsProvider);
                      final allItems = attractionsAsync.value ?? MockPeData.topAttractions;

                      var filteredItems = allItems;
                      if (_selectedCategory != 'todas') {
                        filteredItems = filteredItems.where((a) {
                          final cat = a.category.toLowerCase();
                          final name = a.name.toLowerCase();
                          if (_selectedCategory == 'praia') {
                            return cat.contains('praia') || cat.contains('litoral') || name.contains('praia') || name.contains('piscina');
                          } else if (_selectedCategory == 'cultura') {
                            return cat.contains('cultura') || cat.contains('hist') || cat.contains('museu') || cat.contains('igreja');
                          } else if (_selectedCategory == 'gastro') {
                            return cat.contains('gastro') || cat.contains('restaurante');
                          } else if (_selectedCategory == 'natureza') {
                            return cat.contains('natureza') || cat.contains('trilha') || cat.contains('eco');
                          } else if (_selectedCategory == 'noite') {
                            return cat.contains('noite') || cat.contains('festa') || cat.contains('bar');
                          }
                          return true;
                        }).toList();
                      }
                      if (_searchQuery.isNotEmpty) {
                        filteredItems = filteredItems.where((a) =>
                          a.name.toLowerCase().contains(_searchQuery) ||
                          a.cityName.toLowerCase().contains(_searchQuery) ||
                          a.category.toLowerCase().contains(_searchQuery)
                        ).toList();
                      }

                      if (filteredItems.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.search_off, size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Nenhuma atração encontrada para "$_searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _AttractionCard(item: item, config: config);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _CityCard extends StatelessWidget {
  final CityModel city;

  const _CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/cidade/${city.id}'),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image: NetworkImage(city.imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradiente para leitura
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Badge Offline Status
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: city.isDownloaded ? Colors.green.shade600 : Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      city.isDownloaded ? Icons.check_circle : Icons.offline_bolt_outlined,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      city.isDownloaded ? 'Offline' : city.packageSize,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            // Texto inferior
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttractionCard extends ConsumerWidget {
  final AttractionModel item;
  final FlavorConfig config;

  const _AttractionCard({required this.item, required this.config});

  void _showDetailModal(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLiked = ref.watch(userLikesProvider).contains(item.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, math.max(bottomInset, 16) + 24),
          child: SafeArea(
            top: false,
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
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          item.imageUrl,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 190,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.place, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.pop(ctx);
                              context.go('/mapa?filter=${item.cityId}&attractionId=${item.id}&lat=${item.lat}&lon=${item.lon}');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ver no Mapa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                          '#${item.rankPosition} no Estado • ${item.cityName}',
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
                            '${item.rating} (${item.reviewsCount})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category} • Duração: ~${item.durationMinutes} min',
                    style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'GPS: ${item.lat.toStringAsFixed(4)}, ${item.lon.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          context.go('/mapa?filter=${item.cityId}&attractionId=${item.id}&lat=${item.lat}&lon=${item.lon}');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded, size: 14, color: config.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Localizar',
                              style: TextStyle(
                                color: config.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Botão Principal: Ver no Mapa
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.map_rounded, size: 20, color: Colors.white),
                      label: const Text(
                        'Ver no Mapa',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/mapa?filter=${item.cityId}&attractionId=${item.id}&lat=${item.lat}&lon=${item.lon}');
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão Secundário: Salvar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                      ),
                      label: Text(isLiked ? 'Salvo nos Favoritos' : 'Salvar nos Favoritos'),
                      onPressed: () {
                        ref.read(userLikesProvider.notifier).toggleLike(item.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isLiked ? 'Removido dos salvos' : 'Adicionado aos seus favoritos!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLiked = ref.watch(userLikesProvider).contains(item.id);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showDetailModal(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    item.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.place, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                // Badge de Ranking #1, #2...
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '#${item.rankPosition} em ${item.cityName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botão Curtir Interativo Real com SQLite
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(userLikesProvider.notifier).toggleLike(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isLiked
                                ? 'Removido dos seus favoritos'
                                : 'Adicionado aos seus favoritos offline! (❤️)',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: config.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ' (${item.reviewsCount})',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '~${item.durationMinutes} min',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.favorite, size: 14, color: Colors.red.shade300),
                      const SizedBox(width: 4),
                      Text(
                        '${item.likesCount} curtidas',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
