import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/notification_model.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('🔔 [FCM Background] Message received: ${message.messageId} - ${message.notification?.title}');
}

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

  bool _isFirebaseInitialized = false;
  String? _fcmToken;

  final Set<String> _subscribedTopics = {
    'pe_geral',
    'pe_promocoes',
    'pe_eventos',
    'global_ofertas',
  };

  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  String? get fcmToken => _fcmToken;

  /// Initialize Native Firebase Cloud Messaging
  Future<void> initialize({
    String uf = 'PE',
    void Function(AppNotificationModel)? onNotificationReceived,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseInitialized = true;

      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('🔔 [FCM] Authorization status: ${settings.authorizationStatus}');

      // Auto-subscribe to regional and global topics for this state flavor
      final stateSlug = uf.toLowerCase().trim();
      await subscribeToTopic('${stateSlug}_geral');
      await subscribeToTopic('${stateSlug}_promocoes');
      await subscribeToTopic('${stateSlug}_eventos');
      await subscribeToTopic('${stateSlug}_recife');
      await subscribeToTopic('${stateSlug}_porto_de_galinhas');
      await subscribeToTopic('${stateSlug}_olinda');
      await subscribeToTopic('${stateSlug}_carneiros');
      await subscribeToTopic('${stateSlug}_noronha');
      await subscribeToTopic('global_ofertas');

      // Listen to foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM Foreground] Received: ${message.notification?.title}');
        final model = _convertRemoteMessage(message);
        if (onNotificationReceived != null) {
          onNotificationReceived(model);
        }
      });

      // Retrieve device token for debug/telemetry
      _fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔔 [FCM] Device Token: $_fcmToken');
    } catch (e) {
      debugPrint('ℹ️ [FCM] Running in fallback/offline mode (Firebase not available or test environment): $e');
    }
  }

  /// Subscribe to FCM Topic with Slugs
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
    debugPrint('🔔 [FCM] Subscribed to topic: /topics/$topic');

    if (_isFirebaseInitialized) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } catch (e) {
        debugPrint('⚠️ [FCM] Could not subscribe to Firebase topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from FCM Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
    debugPrint('🔕 [FCM] Unsubscribed from topic: /topics/$topic');

    if (_isFirebaseInitialized) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      } catch (e) {
        debugPrint('⚠️ [FCM] Could not unsubscribe from Firebase topic $topic: $e');
      }
    }
  }

  /// Subscribe user to a specific city of interest with slug format
  Future<void> subscribeToCity(String uf, String citySlug) async {
    final topic = '${uf.toLowerCase()}_${citySlug.toLowerCase()}';
    await subscribeToTopic(topic);
  }

  /// Convert incoming RemoteMessage to AppNotificationModel
  AppNotificationModel _convertRemoteMessage(RemoteMessage message) {
    final data = message.data;
    return AppNotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? data['titulo'] ?? 'Nova Notificação',
      body: message.notification?.body ?? data['mensagem'] ?? '',
      imageUrl: message.notification?.android?.imageUrl ?? data['imagem_url'],
      topic: message.from ?? data['topico'] ?? 'global_ofertas',
      actionType: data['action_type'] ?? 'open_city',
      actionValue: data['action_value'] ?? 'recife',
      timestamp: DateTime.now(),
      isRead: false,
    );
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
        imageUrl: 'https://images.unsplash.com/photo-1667314200608-9823df705cc2?auto=format&fit=crop&w=800&q=80',
        topic: 'pe_promocoes',
        actionType: 'open_url',
        actionValue: 'https://catamarantours.com.br?ref=onetour_pe',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }
}
