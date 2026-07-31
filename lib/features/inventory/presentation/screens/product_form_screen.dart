import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/inventory_providers.dart';

/// Create-or-edit form. Pass an existing [product] to edit it; leave it
/// null to create a new one. Returns `true` via `Navigator.pop` on
/// success so the caller (the inventory list) knows to refresh.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({this.product, super.key});
  final ProductEntity? product;

  bool get isEditing => product != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _unitController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _gstRateController;
  late final TextEditingController _quantityController;
  late final TextEditingController _reorderLevelController;
  late final TextEditingController _batchNumberController;

  String? _categoryId;
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');
    _costPriceController = TextEditingController(text: p?.costPrice.toStringAsFixed(2) ?? '0.00');
    _sellingPriceController = TextEditingController(text: p?.sellingPrice.toStringAsFixed(2) ?? '');
    _gstRateController = TextEditingController(text: p?.gstRate.toStringAsFixed(2) ?? '0.00');
    _quantityController = TextEditingController(text: p?.quantityInStock.toString() ?? '0');
    _reorderLevelController = TextEditingController(text: p?.reorderLevel.toString() ?? '5');
    _batchNumberController = TextEditingController(text: p?.batchNumber ?? '');
    _categoryId = p?.category?.id;
    _expiryDate = p?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _gstRateController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final repository = ref.read(inventoryRepositoryProvider);
    final result = widget.isEditing
        ? await repository.updateProduct(
            id: widget.product!.id,
            name: _nameController.text.trim(),
            barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
            unit: _unitController.text.trim(),
            categoryId: _categoryId,
            costPrice: double.parse(_costPriceController.text),
            sellingPrice: double.parse(_sellingPriceController.text),
            gstRate: double.parse(_gstRateController.text),
            reorderLevel: int.parse(_reorderLevelController.text),
            batchNumber: _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
            expiryDate: _expiryDate,
          )
        : await repository.createProduct(
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
            unit: _unitController.text.trim(),
            categoryId: _categoryId,
            costPrice: double.parse(_costPriceController.text),
            sellingPrice: double.parse(_sellingPriceController.text),
            gstRate: double.parse(_gstRateController.text),
            quantityInStock: int.parse(_quantityController.text),
            reorderLevel: int.parse(_reorderLevelController.text),
            batchNumber: _batchNumberController.text.trim().isEmpty ? null : _batchNumberController.text.trim(),
            expiryDate: _expiryDate,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit product' : 'Add product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Product name',
                controller: _nameController,
                enabled: !_isSubmitting,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'SKU',
                      controller: _skuController,
                      enabled: !_isSubmitting && !widget.isEditing,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'SKU is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(label: 'Unit', controller: _unitController, enabled: !_isSubmitting),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Barcode (optional)', controller: _barcodeController, enabled: !_isSubmitting),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No category')),
                    for (final CategoryEntity c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: _isSubmitting ? null : (value) => setState(() => _categoryId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load categories'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Cost price (₹)',
                      controller: _costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isSubmitting,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a valid amount' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Selling price (₹)',
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isSubmitting,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be greater than 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'GST rate (%)',
                      controller: _gstRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isSubmitting,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 100) return '0–100';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Reorder level',
                      controller: _reorderLevelController,
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter a whole number' : null,
                    ),
                  ),
                ],
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Opening stock quantity',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  enabled: !_isSubmitting,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter a whole number' : null,
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(label: 'Batch number (optional)', controller: _batchNumberController, enabled: !_isSubmitting),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry date (optional)'),
                subtitle: Text(_expiryDate != null
                    ? '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}'
                    : 'Not set'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(icon: const Icon(Icons.calendar_today), onPressed: _isSubmitting ? null : _pickExpiryDate),
                    if (_expiryDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _isSubmitting ? null : () => setState(() => _expiryDate = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.isEditing ? 'Save changes' : 'Add product',
                onPressed: _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
