import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mock_pe_data.dart';
import '../../house_ads/presentation/house_ad_banner.dart';
import '../../house_ads/services/house_ads_service.dart';
import '../../notifications/services/notification_service.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar Moderna com Identidade do Estado
          SliverAppBar(
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
                    Column(
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
                            Text(
                              config.appName,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.orange.shade400),
                            const SizedBox(width: 4),
                            Text(
                              '${config.capital} • 29°C Ensolarado',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Ícone de Notificações com Badge
                        IconButton(
                          icon: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
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
                        // Seletor de Idioma PT / EN
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.language, size: 20),
                          ),
                          onPressed: () {
                            final current = ref.read(localeProvider);
                            ref.read(localeProvider.notifier).state =
                                current.languageCode == 'pt' ? const Locale('en') : const Locale('pt');
                          },
                          tooltip: 'Alternar Idioma / Switch Language',
                        ),
                        // Alternador de Tema Claro / Escuro
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).state =
                                isDark ? ThemeMode.light : ThemeMode.dark;
                          },
                          tooltip: 'Tema',
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
                  // Barra de Busca
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child: Text(
                            l10n.searchPlaceholder,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Icon(Icons.tune_rounded, size: 20, color: Colors.grey.shade400),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tags de Categorias em Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(icon: '🏖️', label: l10n.interestBeach, isSelected: true, color: config.primaryColor),
                        _CategoryChip(icon: '🏛️', label: l10n.interestCulture),
                        _CategoryChip(icon: '🍲', label: l10n.interestGastronomy),
                        _CategoryChip(icon: '🌿', label: l10n.interestNature),
                        _CategoryChip(icon: '🎉', label: l10n.interestNightlife),
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
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockPeData.cities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final city = MockPeData.cities[index];
                        return _CityCard(city: city);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bloco Nativo House Ads (Monetização e Cross-Promotion da Rede)
                  Consumer(
                    builder: (context, ref, _) {
                      final adsAsync = ref.watch(
                        houseAdsByPositionProvider(
                          HouseAdQuery(
                            uf: config.flavor.name.toUpperCase(),
                            position: 'attraction_banner',
                          ),
                        ),
                      );
                      return adsAsync.when(
                        data: (ads) => ads.isNotEmpty
                            ? HouseAdBanner(ad: ads.first)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),

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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: MockPeData.topAttractions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = MockPeData.topAttractions[index];
                      return _AttractionCard(item: item, config: config);
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

class _CategoryChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final Color? color;

  const _CategoryChip({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? (color ?? Colors.blue) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
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

class _AttractionCard extends StatelessWidget {
  final AttractionModel item;
  final FlavorConfig config;

  const _AttractionCard({required this.item, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
              // Botão Curtir com 1 toque
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
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
                    Text(
                      item.category,
                      style: TextStyle(
                        color: config.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    );
  }
}
