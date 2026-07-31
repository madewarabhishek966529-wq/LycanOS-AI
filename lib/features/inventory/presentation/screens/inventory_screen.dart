import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_list_provider.dart';
import '../widgets/product_list_tile.dart';
import '../widgets/stock_adjustment_dialog.dart';
import 'product_form_screen.dart';

/// Inventory landing screen: searchable, filterable product list with
/// add/edit/stock-adjust actions. Categories/suppliers are managed inline
/// via the product form's category dropdown for now — dedicated
/// category/supplier management screens are a small follow-up, not
/// blocking for a usable Inventory module.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openProductForm({ProductEntity? product}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (created == true) {
      ref.read(productListProvider.notifier).loadProducts();
    }
  }

  Future<void> _adjustStock(ProductEntity product) async {
    final result = await showDialog<StockAdjustmentResult>(
      context: context,
      builder: (_) => StockAdjustmentDialog(product: product),
    );
    if (result != null) {
      final success = await ref.read(productListProvider.notifier).adjustStock(
            productId: product.id,
            delta: result.delta,
            reason: result.reason,
          );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated')));
      } else {
        final error = ref.read(productListProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to adjust stock')));
      }
    }
  }

  Future<void> _confirmDelete(ProductEntity product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('This removes "${product.name}" from your catalog. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await ref.read(productListProvider.notifier).deleteProduct(product.id);
      if (!mounted) return;
      if (!success) {
        final error = ref.read(productListProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to delete product')));
      }
    }
  }

  void _showProductActions(ProductEntity product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit product'),
              onTap: () {
                Navigator.of(context).pop();
                _openProductForm(product: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Adjust stock'),
              onTap: () {
                Navigator.of(context).pop();
                _adjustStock(product);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('Delete product', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, SKU, or barcode',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (value) => ref.read(productListProvider.notifier).setSearchQuery(value),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low stock'),
                  selected: state.lowStockOnly,
                  onSelected: (_) => ref.read(productListProvider.notifier).toggleLowStockOnly(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productListProvider.notifier).loadProducts(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ProductListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(state.errorMessage!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(productListProvider.notifier).loadProducts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return ListView(
        // ListView (not Column) so RefreshIndicator's pull-to-refresh
        // still works on an empty state.
        children: [
          const SizedBox(height: 96),
          Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              state.searchQuery.isNotEmpty || state.lowStockOnly
                  ? 'No products match your filters'
                  : 'No products yet — tap "Add product" to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: state.products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = state.products[index];
        return ProductListTile(product: product, onTap: () => _showProductActions(product));
      },
    );
  }
}
