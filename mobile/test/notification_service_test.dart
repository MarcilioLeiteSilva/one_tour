import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_tour_app/features/notifications/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    final service = NotificationService.instance;

    test('has default regional topics configured', () {
      final topics = service.subscribedTopics;
      expect(topics.contains('pe_geral'), true);
      expect(topics.contains('pe_promocoes'), true);
      expect(topics.contains('pe_eventos'), true);
    });

    test('subscribes and unsubscribes from topics', () async {
      await service.subscribeToTopic('pe_noronha');
      expect(service.subscribedTopics.contains('pe_noronha'), true);

      await service.unsubscribeFromTopic('pe_noronha');
      expect(service.subscribedTopics.contains('pe_noronha'), false);
    });

    test('subscribes to city of interest topic', () async {
      await service.subscribeToCity('PE', 'carneiros');
      expect(service.subscribedTopics.contains('pe_carneiros'), true);
    });

    test('provides initial offline showcase notifications', () {
      final notifs = service.getInitialNotifications();
      expect(notifs.isNotEmpty, true);
      expect(notifs.any((n) => n.actionType == 'open_city'), true);
    });
  });

  group('NotificationsNotifier & Riverpod State', () {
    test('calculates unread count and marks as read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialUnread = container.read(unreadNotificationsCountProvider);
      expect(initialUnread, greaterThan(0));

      final firstNotif = container.read(notificationsListProvider).first;
      container.read(notificationsListProvider.notifier).markAsRead(firstNotif.id);

      final unreadAfterOne = container.read(unreadNotificationsCountProvider);
      expect(unreadAfterOne, equals(initialUnread - 1));

      container.read(notificationsListProvider.notifier).markAllAsRead();
      final finalUnread = container.read(unreadNotificationsCountProvider);
      expect(finalUnread, equals(0));
    });
  });
}
