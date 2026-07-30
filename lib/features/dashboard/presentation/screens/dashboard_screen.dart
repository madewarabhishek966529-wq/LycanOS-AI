import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// Dashboard landing screen.
///
/// Full KPI/analytics implementation (today's sales, revenue graph, AI
/// insights, etc.) lands in Phase 3. Phase 2 adds the real signed-in-user
/// greeting on top of the Phase 1 empty state, since that data is now
/// actually available from [authStateProvider].
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_rounded, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              user != null ? 'Welcome back, ${user.fullName.split(' ').first}' : 'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (user != null) ...[
              const SizedBox(height: 4),
              Text(
                'Signed in as ${user.role} · ${user.email}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Sales, revenue, and AI insights land in Phase 3.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
