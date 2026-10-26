import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../domain/network_state_model.dart';
import '../services/network_status_service.dart';

/// Modal bottom sheet que exibe todos os estados da Rede One Tour Brasil,
/// permitindo abrir ou baixar apps já lançados e ativar pré-cadastro nos que estão em breve.
class NetworkStateBottomSheet extends ConsumerStatefulWidget {
  const NetworkStateBottomSheet({super.key});

  @override
  ConsumerState<NetworkStateBottomSheet> createState() => _NetworkStateBottomSheetState();
}

class _NetworkStateBottomSheetState extends ConsumerState<NetworkStateBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0; // 0: Todos, 1: Disponíveis, 2: Em Breve
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentFlavor = ref.watch(appFlavorProvider);
    final flavorConfig = FlavorConfig.of(currentFlavor);
    final allStates = ref.watch(networkAppStatusProvider);
    final notifier = ref.read(networkAppStatusProvider.notifier);

    final currentUf = flavorConfig.uf.toUpperCase();

    // Filtros
    final query = _searchController.text.trim().toLowerCase();
    final availableCount = allStates.where((s) => s.status == NetworkAppStatus.current || s.status == NetworkAppStatus.available).length;
    final comingSoonCount = allStates.where((s) => s.status == NetworkAppStatus.comingSoon).length;

    final filteredStates = allStates.where((state) {
      // Filtro por categoria
      if (_selectedFilter == 1) {
        if (state.status != NetworkAppStatus.current && state.status != NetworkAppStatus.available) {
          return false;
        }
      } else if (_selectedFilter == 2) {
        if (state.status != NetworkAppStatus.comingSoon) {
          return false;
        }
      }

      // Filtro por busca
      if (query.isNotEmpty) {
        final matchesName = state.name.toLowerCase().contains(query);
        final matchesUf = state.uf.toLowerCase().contains(query);
        final matchesCapital = state.capital.toLowerCase().contains(query);
        return matchesName || matchesUf || matchesCapital;
      }

      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrasto
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Cabeçalho com Título, Subtítulo e Botão de Sincronização
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.public_rounded,
                                color: flavorConfig.primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Rede One Tour Brasil',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cada estado conta com seu app próprio com guias e mapas offline dedicados.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Atualizar status da rede',
                      icon: _isRefreshing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: flavorConfig.primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.sync_rounded,
                              color: flavorConfig.primaryColor,
                            ),
                      onPressed: _isRefreshing
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _isRefreshing = true);
                              await notifier.refresh();
                              if (!mounted) return;
                              setState(() => _isRefreshing = false);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Status da Rede One Tour atualizado!'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),

              // Campo de Busca Rápida
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar estado ou capital...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Pílulas de Filtro (Todos / Disponíveis / Em Breve)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Todos (${allStates.length})',
                        index: 0,
                        primaryColor: flavorConfig.primaryColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Disponíveis ($availableCount)',
                        index: 1,
                        primaryColor: Colors.green.shade700,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Em Breve ($comingSoonCount)',
                        index: 2,
                        primaryColor: Colors.orange.shade800,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 12),

              // Lista de Estados
              Expanded(
                child: filteredStates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_rounded,
                              size: 48,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum estado encontrado para "${_searchController.text}"',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: MediaQuery.of(context).padding.bottom + 24,
                        ),
                        itemCount: filteredStates.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final state = filteredStates[index];
                          return _buildStateCard(
                            context: context,
                            state: state,
                            currentUf: currentUf,
                            flavorConfig: flavorConfig,
                            notifier: notifier,
                            isDark: isDark,
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

  Widget _buildFilterChip({
    required String label,
    required int index,
    required Color primaryColor,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == index;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = index),
      selectedColor: primaryColor.withOpacity(0.18),
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primaryColor : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStateCard({
    required BuildContext context,
    required NetworkStateInfo state,
    required String currentUf,
    required FlavorConfig flavorConfig,
    required NetworkStatusNotifier notifier,
    required bool isDark,
  }) {
    final isCurrent = state.status == NetworkAppStatus.current || state.uf.toUpperCase() == currentUf;
    final isAvailable = state.status == NetworkAppStatus.available;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (isCurrent) {
      badgeBg = Colors.green.shade50;
      badgeText = Colors.green.shade700;
      badgeLabel = 'App Atual';
      badgeIcon = Icons.check_circle_rounded;
    } else if (isAvailable) {
      badgeBg = Colors.blue.shade50;
      badgeText = Colors.blue.shade700;
      badgeLabel = 'Disponível';
      badgeIcon = Icons.download_rounded;
    } else {
      badgeBg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
      badgeText = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
      badgeLabel = 'Em breve';
      badgeIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? flavorConfig.primaryColor.withOpacity(0.06)
            : (isDark ? Colors.grey.shade900 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? flavorConfig.primaryColor.withOpacity(0.4)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Avatar com UF
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isCurrent
                  ? LinearGradient(
                      colors: [flavorConfig.primaryColor, flavorConfig.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isCurrent
                  ? null
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? Colors.transparent
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
            ),
            child: Center(
              child: Text(
                state.uf,
                style: TextStyle(
                  color: isCurrent
                      ? Colors.white
                      : (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Informações do Estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent
                              ? (isDark ? Colors.white : flavorConfig.primaryColor)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge de status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 10, color: badgeText),
                          const SizedBox(width: 3),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Capital: ${state.capital}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Ação do Botão
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Ativo',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else if (isAvailable)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.shop_two_rounded, size: 14),
              label: const Text(
                'Baixar',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final success = await notifier.openOrInstall(state);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Buscando ${state.name} na Google Play Store...'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            )
          else ...[
            if (state.isNotified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_rounded, size: 12, color: Colors.teal),
                    SizedBox(width: 3),
                    Text(
                      'Inscrito',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                  side: BorderSide(
                    color: isDark ? Colors.orange.shade700 : Colors.orange.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 13),
                label: const Text(
                  'Avise-me',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _showNotifyDialog(context, state, notifier);
                },
              ),
          ],
        ],
      ),
    );
  }

  void _showNotifyDialog(
    BuildContext context,
    NetworkStateInfo state,
    NetworkStatusNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Tour ${state.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O aplicativo oficial do Tour ${state.name} está sendo preparado com mapas e guias de pontos turísticos offline.',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Deseja receber uma notificação gratuita no seu celular assim que for lançado na Play Store?',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Agora não'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Quero ser avisado'),
              onPressed: () async {
                Navigator.pop(ctx);
                await notifier.registerInterest(state.uf);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Pronto! Você será avisado assim que o Tour ${state.name} for lançado!'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
