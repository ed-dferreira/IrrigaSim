import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irrigasim/app/theme/app_colors.dart';
import 'package:irrigasim/app/theme/app_icons.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.navSimulacao),
            selectedIcon: Icon(
              AppIcons.navSimulacao,
              color: AppColors.primary,
            ),
            label: 'Simulação',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.navCenarios),
            selectedIcon: Icon(
              AppIcons.navCenarios,
              color: AppColors.primary,
            ),
            label: 'Cenários',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.navPerfil),
            selectedIcon: Icon(
              AppIcons.navPerfil,
              color: AppColors.primary,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
