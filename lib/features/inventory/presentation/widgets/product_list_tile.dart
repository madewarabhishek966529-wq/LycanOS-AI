import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({required this.product, required this.onTap, super.key});

  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${product.sku} · ₹${product.sellingPrice.toStringAsFixed(2)}'
        '${product.category != null ? ' · ${product.category!.name}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${product.quantityInStock} ${product.unit}', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          _StockBadge(product: product),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    if (product.isExpired) return _badge('Expired', AppColors.error);
    if (product.isLowStock) return _badge('Low stock', AppColors.warning);
    if (product.isExpiringSoon) return _badge('Expiring soon', AppColors.warning);
    return _badge('In stock', AppColors.success);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
