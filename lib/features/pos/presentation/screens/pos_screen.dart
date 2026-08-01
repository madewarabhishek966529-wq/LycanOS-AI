import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../providers/cart_provider.dart';
import '../widgets/barcode_scanner_screen.dart';
import '../widgets/cart_item_tile.dart';
import 'checkout_screen.dart';

/// POS billing screen. Two panels: a product search/scan picker (left on
/// wide layouts, top on narrow ones) and the running cart with checkout
/// action.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  List<ProductEntity> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    final result = await ref.read(inventoryRepositoryProvider).getProducts(search: query.isEmpty ? null : query);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _results = switch (result) {
        Success(:final data) => data,
        Error() => [],
      };
    });
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;
    _searchController.text = code;
    await _search(code);

    if (_results.length == 1) {
      _addToCart(_results.first);
    } else if (_results.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No product found for "$code"')));
    }
  }

  void _addToCart(ProductEntity product) {
    if (product.quantityInStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${product.name}" is out of stock')));
      return;
    }
    final error = ref.read(cartProvider.notifier).addProduct(product);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${product.name}"'), duration: const Duration(milliseconds: 900)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final searchPanel = _buildSearchPanel();
    final cartPanel = _buildCartPanel(cart);

    return Scaffold(
      appBar: AppBar(title: const Text('Point of Sale')),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 3, child: searchPanel),
                const VerticalDivider(width: 1),
                Expanded(flex: 2, child: cartPanel),
              ],
            )
          : Column(
              children: [
                Expanded(child: searchPanel),
                if (!cart.isEmpty) SizedBox(height: 260, child: cartPanel),
              ],
            ),
    );
  }

  Widget _buildSearchPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
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
                  onSubmitted: _search,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan barcode',
                onPressed: _scanBarcode,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'Search or scan a product to add it to the cart',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = _results[index];
                        final outOfStock = product.quantityInStock <= 0;
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text('${product.sku} · ₹${product.sellingPrice.toStringAsFixed(2)} '
                              '· ${product.quantityInStock} ${product.unit} in stock'),
                          enabled: !outOfStock,
                          trailing: const Icon(Icons.add_shopping_cart),
                          onTap: () => _addToCart(product),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCartPanel(CartState cart) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cart (${cart.itemCount})', style: Theme.of(context).textTheme.titleMedium),
              if (!cart.isEmpty)
                TextButton(onPressed: () => ref.read(cartProvider.notifier).clear(), child: const Text('Clear')),
            ],
          ),
        ),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Text('Cart is empty', style: Theme.of(context).textTheme.bodyMedium),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemTile(
                      item: item,
                      onIncrement: () => _adjustQuantity(item.productId, item.quantity + 1),
                      onDecrement: () => _adjustQuantity(item.productId, item.quantity - 1),
                      onRemove: () => ref.read(cartProvider.notifier).removeItem(item.productId),
                    );
                  },
                ),
        ),
        if (!cart.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated total', style: Theme.of(context).textTheme.titleMedium),
                    Text('₹${cart.estimatedTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Proceed to checkout'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _adjustQuantity(String productId, int quantity) {
    final error = ref.read(cartProvider.notifier).setQuantity(productId, quantity);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
