import 'package:flutter/material.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    super.key,
  });

  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(2)} × ${item.quantity} = ₹${item.lineNet.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 20,
                onPressed: onDecrement,
              ),
              SizedBox(
                width: 28,
                child: Text('${item.quantity}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 20,
                onPressed: item.quantity < item.availableStock ? onIncrement : null,
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
