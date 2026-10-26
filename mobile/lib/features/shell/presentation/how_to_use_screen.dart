import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';

class HowToUseScreen extends ConsumerWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      {
        'icon': Icons.explore_rounded,
        'color': config.primaryColor,
        'title': '1. Explorar Cidades e Atrações',
        'desc':
            'Descubra as melhores praias, cidades históricas, museus e restaurantes. Toque em qualquer lugar para ver fotos, horários de visita, dicas e avaliações.',
        'tip': 'Dica: Use as categorias no topo (Praias, Cultura, Gastronomia) para filtrar rápido!',
      },
      {
        'icon': Icons.route_rounded,
        'color': Colors.deepOrange,
        'title': '2. Criar Suas Rotas',
        'desc':
            'Planeje sua viagem em poucos segundos! Escolha quantos dias vai ficar, seu ritmo de caminhada e seus interesses. O app calcula o trajeto ideal dia a dia.',
        'tip': 'Dica: As rotas mostram a ordem exata dos pontos para você não perder tempo no trânsito.',
      },
      {
        'icon': Icons.map_rounded,
        'color': Colors.teal,
        'title': '3. Usar os Mapas Sem Internet',
        'desc':
            'Antes de sair do hotel, baixe o pacote da cidade. Depois disso, você pode abrir o mapa e ver todos os pontos turísticos mesmo em praias desertas ou serras sem sinal de celular.',
        'tip': 'Dica: O mapa funciona 100% offline com o GPS do seu próprio celular.',
      },
      {
        'icon': Icons.favorite_rounded,
        'color': Colors.redAccent,
        'title': '4. Salvar Seus Lugares Favoritos',
        'desc':
            'Gostou de uma praia ou restaurante? Toque no coração (❤️) em qualquer atração para salvar. Eles ficam reunidos na aba "Salvos" para você achar em um segundo.',
        'tip': 'Dica: Na aba Salvos você também gerencia quais cidades já estão baixadas.',
      },
      {
        'icon': Icons.battery_charging_full_rounded,
        'color': Colors.amber.shade800,
        'title': '5. Economize Bateria e Dados',
        'desc':
            'Como os guias e mapas funcionam direto na memória do seu aparelho, você pode economizar seus dados móveis e até ativar o "Modo Avião" durante a praia para a bateria durar o dia inteiro.',
        'tip': 'Dica: Seus favoritos e rotas ficam guardados com total segurança no seu telefone.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Como Usar o App'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Banner de Boas-Vindas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [config.primaryColor.withOpacity(0.1), config.secondaryColor.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: config.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo ao ${config.appName}!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O seu companheiro de viagem simples, rápido e preparado para lugares sem sinal.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Passo a Passo Simples',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Cards dos Passos
          ...steps.map((s) {
            final color = s['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s['title'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s['desc'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s['tip'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Botão de Ação: Começar a Explorar
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: config.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.go('/cidades');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Começar a Explorar Agora',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
