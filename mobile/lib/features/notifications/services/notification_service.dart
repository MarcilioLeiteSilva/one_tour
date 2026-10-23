import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final notificationsListProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotificationModel>>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsListProvider);
  return notifs.where((n) => !n.isRead).length;
});

class NotificationsNotifier extends StateNotifier<List<AppNotificationModel>> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super([]) {
    _loadInitialNotifications();
  }

  void _loadInitialNotifications() {
    final service = _ref.read(notificationServiceProvider);
    state = service.getInitialNotifications();
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void addNotification(AppNotificationModel notif) {
    state = [notif, ...state];
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final Set<String> _subscribedTopics = {
    'pe_geral',
    'pe_promocoes',
    'pe_eventos',
    'global_ofertas',
  };

  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);

  /// Subscribe to FCM Topic
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
    debugPrint('🔔 [FCM] Subscribed to topic: /topics/$topic');
  }

  /// Unsubscribe from FCM Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
    debugPrint('🔕 [FCM] Unsubscribed from topic: /topics/$topic');
  }

  /// Subscribe user to a specific city of interest
  Future<void> subscribeToCity(String uf, String citySlug) async {
    final topic = '${uf.toLowerCase()}_${citySlug.toLowerCase()}';
    await subscribeToTopic(topic);
  }

  /// Handle Notification Tap / Deep Linking
  void handleNotificationTap(BuildContext context, AppNotificationModel notif) {
    switch (notif.actionType) {
      case 'open_city':
        context.push('/cidade/${notif.actionValue}');
        break;
      case 'open_attraction':
        context.push('/cidade/recife');
        break;
      case 'open_trip':
        context.push('/roteiro/${notif.actionValue}');
        break;
      case 'open_url':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrindo link promocional: ${notif.actionValue}'),
            duration: const Duration(seconds: 3),
          ),
        );
        break;
      default:
        context.push('/cidades');
    }
  }

  /// Curated initial notifications for offline showcase
  List<AppNotificationModel> getInitialNotifications() {
    return [
      AppNotificationModel(
        id: 'notif_1',
        title: '☀️ Maré Baixa em Porto de Galinhas!',
        body: 'O pico da maré baixa hoje é às 10h15. Momento ideal para passeio de jangada até as piscinas.',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
        topic: 'pe_porto_de_galinhas',
        actionType: 'open_city',
        actionValue: 'porto_de_galinhas',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: false,
      ),
      AppNotificationModel(
        id: 'notif_2',
        title: '🎭 Ensaio de Maracatu no Alto da Sé',
        body: 'Noite dos Tambores Silenciosos nas ladeiras históricas de Olinda hoje às 19h.',
        imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80',
        topic: 'pe_eventos',
        actionType: 'open_attraction',
        actionValue: 'alto_da_se',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      AppNotificationModel(
        id: 'notif_3',
        title: '⛵ Passeio de Catamarã com 15% OFF',
        body: 'Reserve o tour pelas pontes históricas do Recife Antigo com desconto exclusivo no app.',
        imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=800&q=80',
        topic: 'pe_promocoes',
        actionType: 'open_url',
        actionValue: 'https://catamarantours.com.br?ref=onetour_pe',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }
}
