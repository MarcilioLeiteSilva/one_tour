import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/explore/presentation/explore_screen.dart';
import '../../features/explore/presentation/city_detail_screen.dart';
import '../../features/trip_planner/presentation/trip_planner_screen.dart';
import '../../features/trip_planner/presentation/trip_itinerary_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/shell/presentation/how_to_use_screen.dart';
import '../../features/shell/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorExploreKey = GlobalKey<NavigatorState>();
final _shellNavigatorPlannerKey = GlobalKey<NavigatorState>();
final _shellNavigatorMapKey = GlobalKey<NavigatorState>();
final _shellNavigatorSavedKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/cidades',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Aba 1: Explorar (Cidades e Atrações)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey,
            routes: [
              GoRoute(
                path: '/cidades',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          // Aba 2: Roteiros
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPlannerKey,
            routes: [
              GoRoute(
                path: '/roteiros',
                builder: (context, state) => const TripPlannerScreen(),
              ),
            ],
          ),
          // Aba 3: Mapa
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMapKey,
            routes: [
              GoRoute(
                path: '/mapa',
                builder: (context, state) {
                  final filter = state.uri.queryParameters['filter'];
                  final attractionId = state.uri.queryParameters['attractionId'];
                  final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
                  final lon = double.tryParse(state.uri.queryParameters['lon'] ?? '');
                  return MapScreen(
                    initialFilter: filter,
                    initialAttractionId: attractionId,
                    initialLat: lat,
                    initialLon: lon,
                  );
                },
              ),
            ],
          ),
          // Aba 4: Salvos e Downloads
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSavedKey,
            routes: [
              GoRoute(
                path: '/favoritos',
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
        ],
      ),

      // Rotas Externas / Detalhes (fora da barra de navegação)
      GoRoute(
        path: '/cidade/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'recife';
          return CityDetailScreen(cityId: id);
        },
      ),
      GoRoute(
        path: '/roteiro/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'roteiro_demo';
          return TripItineraryScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/notificacoes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/como-usar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HowToUseScreen(),
      ),
      GoRoute(
        path: '/configuracoes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
