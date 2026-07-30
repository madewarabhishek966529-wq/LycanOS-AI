import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

/// Adaptive shell for the authenticated area: a [NavigationRail] on
/// wide/desktop layouts, a [NavigationBar] on narrow/mobile layouts. Wraps
/// whatever the active branch of [AppRouter]'s ShellRoute renders, and
/// surfaces the signed-in user + sign-out action in both layouts.
class AppShell extends ConsumerWidget {
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

  int _selectedIndex() {
    final index = _destinations.indexWhere((d) => d.path == currentPath);
    return index == -1 ? 0 : index;
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You'll need to sign in again to access your business data."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).signOut();
      // AppRouter's redirect takes over from here once auth state flips.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final selectedIndex = _selectedIndex();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              labelType: MediaQuery.sizeOf(context).width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _UserAvatar(name: user?.fullName, role: user?.role),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ),
                ),
              ),
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
      appBar: AppBar(
        title: Text(_destinations[selectedIndex].label),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, 4),
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations
            .take(5)
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, required this.role});
  final String? name;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?';
    return Tooltip(
      message: [if (name != null) name!, if (role != null) role!].join(' · '),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
