import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../network/presentation/network_state_bottom_sheet.dart';
import '../../trip_planner/services/city_pack_download_service.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(flavorConfigProvider);
    final currentFlavor = ref.watch(appFlavorProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Cabeçalho do Drawer com Identidade Visual do Estado
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [config.primaryColor, config.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: config.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        config.uf,
                        style: TextStyle(
                          color: config.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Modo Offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  config.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.slogan,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Lista de Itens do Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Grupo 1: Navegação Principal
                _buildSectionHeader(context, 'NAVEGAÇÃO'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.explore_rounded,
                  iconColor: config.primaryColor,
                  title: 'Explorar',
                  subtitle: 'Cidades, praias e atrações',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/cidades');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.route_rounded,
                  iconColor: Colors.deepOrange,
                  title: 'Rotas',
                  subtitle: 'Crie e veja seus trajetos',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/roteiros');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.map_rounded,
                  iconColor: Colors.teal,
                  title: 'Mapas',
                  subtitle: 'Pontos turísticos no mapa',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/mapa');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.redAccent,
                  title: 'Salvos',
                  subtitle: 'Lugares e guias salvos',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/favoritos');
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1),
                ),

                // Grupo 2: Ferramentas
                _buildSectionHeader(context, 'FERRAMENTAS'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.cloud_download_rounded,
                  iconColor: Colors.blueAccent,
                  title: 'Baixar Cidades',
                  subtitle: 'Guias e mapas para usar sem internet',
                  onTap: () {
                    Navigator.pop(context);
                    _showCityPacksDialog(context, ref);
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.public_rounded,
                  iconColor: Colors.indigo,
                  title: 'Rede One Tour Brasil',
                  subtitle: 'Explore guias e mapas de outros estados',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: config.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${config.uf} • Ativo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: config.primaryColor,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeStateBottomSheet(context, ref, currentFlavor);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1),
                ),

                // Grupo 3: Ajuda e Ajustes
                _buildSectionHeader(context, 'AJUDA & AJUSTES'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  iconColor: Colors.amber.shade800,
                  title: 'Como Usar',
                  subtitle: 'Dicas simples para aproveitar o app',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/como-usar');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  iconColor: Colors.blueGrey,
                  title: 'Configurações',
                  subtitle: 'Aparência, idioma e memória',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/configuracoes');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.grey.shade600,
                  title: 'Sobre o App',
                  subtitle: 'One Tour Brasil • Versão 1.0.0',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context, config);
                  },
                ),
              ],
            ),
          ),

          // Rodapé do Drawer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One Tour Brasil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Turismo Inteligente & 100% Offline',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Diálogo para Baixar Cidades Offline
  void _showCityPacksDialog(BuildContext context, WidgetRef ref) {
    final cities = [
      {'name': 'Recife', 'slug': 'recife', 'size': '4.2 MB', 'attractions': '12 pontos'},
      {'name': 'Olinda', 'slug': 'olinda', 'size': '3.8 MB', 'attractions': '10 pontos'},
      {'name': 'Porto de Galinhas', 'slug': 'porto_de_galinhas', 'size': '4.5 MB', 'attractions': '9 pontos'},
      {'name': 'Fernando de Noronha', 'slug': 'fernando_de_noronha', 'size': '5.1 MB', 'attractions': '8 pontos'},
      {'name': 'Caruaru', 'slug': 'caruaru', 'size': '3.1 MB', 'attractions': '7 pontos'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Baixar Cidades',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Baixe guias e mapas das cidades para navegar tranquilamente sem sinal de internet ou gastar dados.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...cities.map((c) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(Icons.location_city_rounded, color: Color(0xFF0284C7)),
                    ),
                    title: Text(
                      c['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text('${c['attractions']} • Tamanho: ${c['size']}'),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Baixar'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        Navigator.pop(ctx);
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text('Baixando pacote de ${c['name']}...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        await CityPackDownloadService.instance.downloadCityPack(c['slug']!);
                        messenger?.showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green.shade700,
                            content: Text('✅ Guia e mapa de ${c['name']} prontos para uso offline!'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/favoritos');
                  },
                  child: const Text('Ver todos os pacotes em "Salvos"'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modal da Rede One Tour Brasil
  void _showChangeStateBottomSheet(
    BuildContext context,
    WidgetRef ref,
    AppFlavor currentFlavor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NetworkStateBottomSheet(),
    );
  }

  // Diálogo "Sobre o App"
  void _showAboutDialog(BuildContext context, FlavorConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: config.primaryColor,
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
            const Text('One Tour Brasil', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.appName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(config.slogan, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              'O One Tour é o seu guia de viagem completo, feito para funcionar mesmo em praias distantes, serras e estradas sem sinal de internet.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text('Versão 1.0.0 (Build 2026)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
