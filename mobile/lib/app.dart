import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ads/admob_service.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/explore/presentation/explore_controller.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/social/services/social_service.dart';
import 'l10n/app_localizations.dart';

class OneTourApp extends ConsumerStatefulWidget {
  const OneTourApp({super.key});

  @override
  ConsumerState<OneTourApp> createState() => _OneTourAppState();
}

class _OneTourAppState extends ConsumerState<OneTourApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(flavorConfigProvider);

      // 1. Push Notifications
      NotificationService.instance.initialize(
        uf: config.uf,
        onNotificationReceived: (notif) {
          ref.read(notificationsListProvider.notifier).addNotification(notif);
        },
      );

      // 2. Social & Telemetry Engine (offline-first sync com Postgres)
      SocialService.instance.onStatsUpdated = () {
        ref.invalidate(curatedAttractionsProvider);
      };
      SocialService.instance.start(uf: config.uf);

      // 3. Google Mobile Ads (AdMob)
      AdMobService.instance.initialize().then((_) {
        AdMobService.instance.preloadInterstitial(config.uf);
      });
    });
  }

  @override
  void dispose() {
    SocialService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final config = ref.watch(flavorConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config),
      darkTheme: AppTheme.dark(config),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
