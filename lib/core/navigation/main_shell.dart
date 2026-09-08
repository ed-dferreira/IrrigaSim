import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_icons.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(AppIcons.navSimulacao),
            selectedIcon: Icon(
              AppIcons.navSimulacao,
              color: colorScheme.primary,
            ),
            label: 'Simulação',
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.navCenarios),
            selectedIcon: Icon(
              AppIcons.navCenarios,
              color: colorScheme.primary,
            ),
            label: 'Cenários',
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.navPerfil),
            selectedIcon: Icon(
              AppIcons.navPerfil,
              color: colorScheme.primary,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
