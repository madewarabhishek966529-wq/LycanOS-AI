import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';

/// Adaptive shell for the authenticated area: a [NavigationRail] on
/// wide/desktop layouts, a [NavigationBar] on narrow/mobile layouts. Wraps
/// whatever the active branch of [AppRouter]'s ShellRoute renders.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.currentPath, super.key});

  final Widget child;
  final String currentPath;

  static const List<({IconData icon, String label, String path})> _destinations = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard', path: RouteNames.dashboard),
    (icon: Icons.point_of_sale_rounded, label: 'POS', path: RouteNames.pos),
    (icon: Icons.inventory_2_rounded, label: 'Inventory', path: RouteNames.inventory),
    (icon: Icons.people_alt_rounded, label: 'Customers', path: RouteNames.customers),
    (icon: Icons.badge_rounded, label: 'Employees', path: RouteNames.employees),
    (icon: Icons.insert_chart_rounded, label: 'Reports', path: RouteNames.reports),
    (icon: Icons.auto_awesome_rounded, label: 'AI Assistant', path: RouteNames.aiAssistant),
    (icon: Icons.settings_rounded, label: 'Settings', path: RouteNames.settings),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere((d) => d.path == currentPath);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              labelType: MediaQuery.sizeOf(context).width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.clamp(0, 4),
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations
            .take(5)
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}
