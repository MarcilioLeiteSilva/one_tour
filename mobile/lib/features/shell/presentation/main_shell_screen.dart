import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';

class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: theme.colorScheme.primary),
              label: l10n.tabExplore,
            ),
            NavigationDestination(
              icon: const Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route, color: theme.colorScheme.primary),
              label: l10n.tabItineraries,
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: theme.colorScheme.primary),
              label: l10n.tabMap,
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite, color: theme.colorScheme.primary),
              label: l10n.tabSaved,
            ),
          ],
        ),
      ),
    );
  }
}
