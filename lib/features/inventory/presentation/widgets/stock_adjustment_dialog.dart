import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/product_entity.dart';

/// Result returned when the dialog is confirmed: signed delta (positive =
/// receiving stock, negative = removing it) and the required reason.
class StockAdjustmentResult {
  const StockAdjustmentResult({required this.delta, required this.reason});
  final int delta;
  final String reason;
}

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({required this.product, super.key});
  final ProductEntity product;

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isReceiving = true;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final quantity = int.parse(_quantityController.text);
    final delta = _isReceiving ? quantity : -quantity;
    Navigator.of(context).pop(StockAdjustmentResult(delta: delta, reason: _reasonController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust stock — ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Currently ${widget.product.quantityInStock} ${widget.product.unit} in stock'),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Receive'), icon: Icon(Icons.add)),
                ButtonSegment(value: false, label: Text('Remove'), icon: Icon(Icons.remove)),
              ],
              selected: {_isReceiving},
              onSelectionChanged: (selection) => setState(() => _isReceiving = selection.first),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Quantity',
              controller: _quantityController,
              keyboardType: TextInputType.number,
              validator: (value) {
                final n = int.tryParse(value ?? '');
                if (n == null || n <= 0) return 'Enter a positive whole number';
                if (!_isReceiving && n > widget.product.quantityInStock) {
                  return 'Only ${widget.product.quantityInStock} in stock';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Reason',
              controller: _reasonController,
              hintText: _isReceiving ? 'Purchase order #...' : 'Damaged, expired, correction...',
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Reason is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppButton(label: 'Confirm', onPressed: _submit, fullWidth: false),
      ],
    );
  }
}
