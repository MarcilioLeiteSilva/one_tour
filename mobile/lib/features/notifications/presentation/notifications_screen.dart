import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../domain/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'todas';

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);
    final notifications = ref.watch(notificationsListProvider);

    final filteredNotifs = notifications.where((n) {
      if (_selectedFilter == 'todas') return true;
      if (_selectedFilter == 'promocoes') {
        return n.topic.contains('promocoes') || n.actionType == 'open_url';
      }
      if (_selectedFilter == 'eventos') {
        return n.topic.contains('eventos');
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos & Promoções'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationsListProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todas as notificações foram marcadas como lidas.')),
              );
            },
            child: const Text('Limpar Não Lidas', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de Tópicos (Chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('todas', 'Todas', config),
                const SizedBox(width: 8),
                _buildFilterChip('promocoes', 'Promoções & Ofertas', config),
                const SizedBox(width: 8),
                _buildFilterChip('eventos', 'Eventos & Marés', config),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de Notificações
          Expanded(
            child: filteredNotifs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Nenhuma notificação encontrada nesta categoria.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredNotifs[index];
                      return _NotificationCard(
                        notification: item,
                        onTap: () {
                          ref.read(notificationsListProvider.notifier).markAsRead(item.id);
                          ref.read(notificationServiceProvider).handleNotificationTap(context, item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, FlavorConfig config) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? config.primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours} h';
    } else {
      return 'Ontem';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.cardColor
              : theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem Rich Thumbnail
            if (notification.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  notification.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.notifications, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notifications_active, color: theme.colorScheme.primary),
              ),
            const SizedBox(width: 14),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeAgo(notification.timestamp),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
