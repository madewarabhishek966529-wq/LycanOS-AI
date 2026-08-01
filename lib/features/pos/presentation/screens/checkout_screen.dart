import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../customers/domain/entities/customer_entity.dart';
import '../../../customers/presentation/providers/customer_providers.dart';
import '../providers/cart_provider.dart';
import '../providers/pos_providers.dart';
import 'receipt_screen.dart';

enum _PaymentMode { single, split }

const _paymentMethods = ['cash', 'card', 'upi', 'wallet', 'credit'];

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  _PaymentMode _mode = _PaymentMode.single;
  String _singleMethod = 'cash';
  final _couponController = TextEditingController();
  final _invoiceDiscountController = TextEditingController(text: '0');

  // One amount controller per payment method for the split-payment case.
  final Map<String, TextEditingController> _splitControllers = {
    for (final m in _paymentMethods) m: TextEditingController(text: '0'),
  };

  bool _isSubmitting = false;
  CustomerEntity? _selectedCustomer;

  @override
  void dispose() {
    _couponController.dispose();
    _invoiceDiscountController.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    List<({String method, double amount})>? splits;
    String? singleMethod;

    if (_mode == _PaymentMode.split) {
      splits = [
        for (final method in _paymentMethods)
          if ((double.tryParse(_splitControllers[method]!.text) ?? 0) > 0)
            (method: method, amount: double.parse(_splitControllers[method]!.text)),
      ];
      if (splits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter at least one split amount')));
        return;
      }
    } else {
      singleMethod = _singleMethod;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(posRepositoryProvider).checkout(
          items: cart.items,
          customerId: _selectedCustomer?.id,
          invoiceDiscountAmount: double.tryParse(_invoiceDiscountController.text) ?? 0,
          couponCode: _couponController.text.trim().isEmpty ? null : _couponController.text.trim(),
          paymentMethod: singleMethod,
          paymentSplits: splits,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success(:final data):
        ref.read(cartProvider.notifier).clear();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(invoiceId: data.id, invoiceNumber: data.invoiceNumber),
          ),
        );
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _pickCustomer() async {
    final searchController = TextEditingController();
    var results = <CustomerEntity>[];
    var isLoading = false;

    Future<void> search(StateSetter setSheetState) async {
      setSheetState(() => isLoading = true);
      final result = await ref.read(customerRepositoryProvider).getCustomers(search: searchController.text);
      isLoading = false;
      if (result is Success<List<CustomerEntity>>) {
        setSheetState(() => results = result.data);
      } else {
        setSheetState(() => results = []);
      }
    }

    final selected = await showModalBottomSheet<CustomerEntity>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (results.isEmpty && !isLoading && searchController.text.isEmpty) {
              search(setSheetState);
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Attach a customer', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Search by name or phone', prefixIcon: Icon(Icons.search)),
                      onChanged: (_) => search(setSheetState),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final customer = results[index];
                                return ListTile(
                                  title: Text(customer.name),
                                  subtitle: Text(customer.phone ?? customer.email ?? ''),
                                  onTap: () => Navigator.of(context).pop(customer),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) setState(() => _selectedCustomer = selected);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final invoiceDiscount = double.tryParse(_invoiceDiscountController.text) ?? 0;
    final estimatedTotal = (cart.estimatedTotal - invoiceDiscount) < 0 ? 0.0 : (cart.estimatedTotal - invoiceDiscount);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Customer (optional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_selectedCustomer == null)
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _pickCustomer,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Attach a customer'),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(_selectedCustomer!.name),
                subtitle: Text(_selectedCustomer!.phone ?? _selectedCustomer!.email ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting ? null : () => setState(() => _selectedCustomer = null),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('Order summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', cart.subtotal),
          _summaryRow('Estimated GST', cart.estimatedGst),
          const Divider(),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Coupon code (optional)',
            controller: _couponController,
            hintText: 'e.g. WELCOME10',
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Manual discount (₹, optional — ignored if a coupon is applied)',
            controller: _invoiceDiscountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSubmitting,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Payment', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<_PaymentMode>(
            segments: const [
              ButtonSegment(value: _PaymentMode.single, label: Text('Single method')),
              ButtonSegment(value: _PaymentMode.split, label: Text('Split payment')),
            ],
            selected: {_mode},
            onSelectionChanged: _isSubmitting ? null : (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 12),
          if (_mode == _PaymentMode.single)
            Wrap(
              spacing: 8,
              children: [
                for (final method in _paymentMethods)
                  ChoiceChip(
                    label: Text(method.toUpperCase()),
                    selected: _singleMethod == method,
                    onSelected: _isSubmitting ? null : (_) => setState(() => _singleMethod = method),
                  ),
              ],
            )
          else
            Column(
              children: [
                for (final method in _paymentMethods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 70, child: Text(method.toUpperCase())),
                        Expanded(
                          child: TextField(
                            controller: _splitControllers[method],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(prefixText: '₹ ', isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (_mode == _PaymentMode.single && _singleMethod == 'credit' && _selectedCustomer == null) ...[
            const SizedBox(height: 8),
            Text(
              'Credit sales need a customer attached above.',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          _summaryRow('Estimated total', estimatedTotal, emphasize: true),
          const SizedBox(height: 4),
          Text(
            'Final GST/discount and total are calculated authoritatively by the server at checkout.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Confirm sale',
            onPressed: cart.isEmpty ? null : _submit,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool emphasize = false}) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
