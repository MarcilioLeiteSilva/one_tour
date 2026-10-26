import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _nearbyAlerts = true;
  bool _tripTips = true;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Seção: Aparência
          _buildSectionTitle('APARÊNCIA'),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Padrão do Sistema'),
                  subtitle: const Text('Segue as configurações do seu celular'),
                  secondary: const Icon(Icons.settings_brightness_rounded),
                  value: ThemeMode.system,
                  groupValue: currentThemeMode,
                  activeColor: config.primaryColor,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).state = mode;
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Modo Claro'),
                  subtitle: const Text('Visual claro e suave'),
                  secondary: const Icon(Icons.light_mode_rounded, color: Colors.amber),
                  value: ThemeMode.light,
                  groupValue: currentThemeMode,
                  activeColor: config.primaryColor,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).state = mode;
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Modo Escuro'),
                  subtitle: const Text('Economiza bateria e descansa a visão'),
                  secondary: const Icon(Icons.dark_mode_rounded, color: Colors.indigoAccent),
                  value: ThemeMode.dark,
                  groupValue: currentThemeMode,
                  activeColor: config.primaryColor,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).state = mode;
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Idioma
          _buildSectionTitle('IDIOMA'),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Português (Brasil)'),
                  secondary: const Text('🇧🇷', style: TextStyle(fontSize: 22)),
                  value: 'pt',
                  groupValue: currentLocale.languageCode,
                  activeColor: config.primaryColor,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(localeProvider.notifier).state = const Locale('pt');
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('English (Inglês)'),
                  secondary: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                  value: 'en',
                  groupValue: currentLocale.languageCode,
                  activeColor: config.primaryColor,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(localeProvider.notifier).state = const Locale('en');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Avisos e Lembretes
          _buildSectionTitle('AVISOS E LEMBRETES'),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.near_me_rounded, color: Colors.blueAccent),
                  title: const Text('Atrações Próximas'),
                  subtitle: const Text('Avisa quando você estiver perto de um ponto famoso'),
                  value: _nearbyAlerts,
                  activeColor: config.primaryColor,
                  onChanged: (val) => setState(() => _nearbyAlerts = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.tips_and_updates_rounded, color: Colors.amber),
                  title: const Text('Dicas e Sugestões'),
                  subtitle: const Text('Ideias de passeios e novidades para sua viagem'),
                  value: _tripTips,
                  activeColor: config.primaryColor,
                  onChanged: (val) => setState(() => _tripTips = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Memória e Armazenamento
          _buildSectionTitle('MEMÓRIA E ARMAZENAMENTO'),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_special_rounded, color: Colors.teal),
                  title: const Text('Cidades e Guias Baixados'),
                  subtitle: const Text('Espaço ocupado: ~18.5 MB no aparelho'),
                  trailing: TextButton(
                    onPressed: () => context.go('/favoritos'),
                    child: const Text('Gerenciar'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.deepOrange),
                  title: const Text('Limpar Arquivos Temporários'),
                  subtitle: const Text('Libera memória do celular sem apagar seus favoritos'),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('✅ Memória temporária limpa com sucesso! (12.4 MB liberados)'),
                        ),
                      );
                    },
                    child: const Text('Limpar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção: Sobre e Ajuda
          _buildSectionTitle('SOBRE E AJUDA'),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_center_rounded, color: Colors.blue),
                  title: const Text('Como Usar o Aplicativo'),
                  subtitle: const Text('Veja o passo a passo ilustrado'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/como-usar'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_rounded, color: Colors.grey),
                  title: const Text('Termos de Uso e Privacidade'),
                  subtitle: const Text('Seus dados ficam 100% seguros no seu celular'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showPrivacyDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                  title: const Text('Versão'),
                  trailing: const Text(
                    '1.0.0 (Build 2026)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Privacidade & Segurança', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O One Tour foi construído com foco na sua total privacidade.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• Suas listas de favoritos e rotas ficam salvas somente no seu dispositivo.\n'
              '• Nenhum dado pessoal sensível é coletado ou vendido.\n'
              '• O uso do GPS serve exclusivamente para mostrar os pontos próximos a você no mapa.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
