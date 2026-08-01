import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/revenue_chart.dart';

/// Dashboard landing screen — today's sales, monthly revenue, low-stock
/// alerts, best sellers, and a 7-day revenue chart, all backed by real
/// aggregation queries over Inventory (Phase 3) and POS (Phase 4) data.
///
/// Only Owner/Manager accounts see this screen's data (see the backend's
/// RBAC on `/dashboard/*`) — a Cashier/Employee hitting this route gets a
/// 403 surfaced as the error state below, which is correct: they simply
/// don't have a dashboard to see.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final revenueAsync = ref.watch(revenueSeriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(revenueSeriesProvider);
        },
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(context, ref, error),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Welcome back, ${user.fullName.split(' ').first}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 600 ? 2 : 2);
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      KpiTile(
                        label: "Today's Sales",
                        value: '₹${summary.todaySalesTotal.toStringAsFixed(0)}',
                        subtitle: '${summary.todaySalesCount} invoice${summary.todaySalesCount == 1 ? '' : 's'}',
                        icon: Icons.point_of_sale_rounded,
                      ),
                      KpiTile(
                        label: 'Monthly Revenue',
                        value: '₹${summary.monthRevenueTotal.toStringAsFixed(0)}',
                        subtitle: '${summary.monthSalesCount} invoices this month',
                        icon: Icons.trending_up_rounded,
                        color: Colors.teal,
                      ),
                      KpiTile(
                        label: "Today's GST Collected",
                        value: '₹${summary.todayGstCollected.toStringAsFixed(0)}',
                        icon: Icons.receipt_long_rounded,
                        color: Colors.indigo,
                      ),
                      KpiTile(
                        label: 'Low Stock Alerts',
                        value: '${summary.lowStockCount}',
                        subtitle: summary.lowStockCount > 0 ? 'products need restocking' : 'all stocked up',
                        icon: Icons.warning_amber_rounded,
                        color: summary.lowStockCount > 0 ? Colors.orange : Colors.green,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              revenueAsync.when(
                loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
                data: (points) => RevenueChart(points: points),
              ),
              const SizedBox(height: 16),
              _buildBestSellers(context, summary),
              const SizedBox(height: 16),
              if (summary.lowStockProducts.isNotEmpty) _buildLowStock(context, summary),
              const SizedBox(height: 16),
              _buildAiInsightsPlaceholder(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestSellers(BuildContext context, DashboardSummaryEntity summary) {
    final theme = Theme.of(context);
    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Best Selling Products (30 days)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (summary.bestSellingProducts.isEmpty)
            Text('No sales yet in this period', style: theme.textTheme.bodyMedium)
          else
            for (final product in summary.bestSellingProducts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(product.productName, overflow: TextOverflow.ellipsis)),
                    Text('${product.quantitySold} sold', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Text('₹${product.revenue.toStringAsFixed(0)}', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLowStock(BuildContext context, DashboardSummaryEntity summary) {
    final theme = Theme.of(context);
    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Low Stock', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          for (final product in summary.lowStockProducts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(product.productName, overflow: TextOverflow.ellipsis)),
                  Text(
                    '${product.quantityInStock} left (reorder at ${product.reorderLevel})',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiInsightsPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      blur: false,
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI Business Insights arrive in Phase 9, once the Ollama-backed assistant can reason over this data.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final isForbidden = error.toString().contains('403') || error.toString().toLowerCase().contains('not authorized');
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(
          isForbidden ? Icons.lock_outline : Icons.error_outline,
          size: 40,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            isForbidden
                ? "Only business owners and managers can view the dashboard."
                : 'Could not load the dashboard: $error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (!isForbidden) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: () {
                ref.invalidate(dashboardSummaryProvider);
                ref.invalidate(revenueSeriesProvider);
              },
              child: const Text('Retry'),
            ),
          ),
        ],
      ],
    );
  }
}
