import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../pos/domain/entities/invoice_entity.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customer_providers.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({required this.customerId, super.key});
  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  CustomerEntity? _customer;
  List<InvoiceEntity> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = ref.read(customerRepositoryProvider);
    final customerResult = await repository.getCustomer(widget.customerId);
    final purchasesResult = await repository.getPurchaseHistory(widget.customerId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (customerResult is Success<CustomerEntity>) _customer = customerResult.data;
      if (purchasesResult is Success<List<InvoiceEntity>>) _purchases = purchasesResult.data;
      if (customerResult is Error<CustomerEntity>) _errorMessage = customerResult.failure.message;
    });
  }

  Future<void> _editCustomer() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: _customer)),
    );
    if (updated == true) _load();
  }

  Future<void> _repayCredit() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record credit repayment'),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: 'Amount received (₹)',
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Enter a positive amount';
              if (_customer != null && n > _customer!.creditBalance) {
                return 'Exceeds outstanding balance of ₹${_customer!.creditBalance.toStringAsFixed(2)}';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          AppButton(
            label: 'Record',
            fullWidth: false,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(double.parse(controller.text));
              }
            },
          ),
        ],
      ),
    );

    if (amount == null) return;

    final result = await ref.read(customerRepositoryProvider).repayCredit(
          customerId: widget.customerId,
          amount: amount,
        );
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() => _customer = data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repayment recorded')));
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.name ?? 'Customer'),
        actions: [
          if (_customer != null)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editCustomer),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _customer == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildPurchaseHistory(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileCard() {
    final theme = Theme.of(context);
    final c = _customer!;
    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.name, style: theme.textTheme.titleLarge),
          if (c.phone != null) _infoRow(Icons.phone_outlined, c.phone!),
          if (c.email != null) _infoRow(Icons.mail_outline, c.email!),
          if (c.address != null) _infoRow(Icons.location_on_outlined, c.address!),
          if (c.notes != null) ...[
            const SizedBox(height: 8),
            Text(c.notes!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final theme = Theme.of(context);
    final c = _customer!;
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            blur: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loyalty points', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('${c.loyaltyPoints}', style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            blur: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credit balance', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '₹${c.creditBalance.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: c.hasOutstandingCredit ? theme.colorScheme.error : null,
                  ),
                ),
                if (c.hasOutstandingCredit) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: _repayCredit, child: const Text('Record repayment')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseHistory() {
    final theme = Theme.of(context);
    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchase history', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_purchases.isEmpty)
            Text('No purchases yet', style: theme.textTheme.bodyMedium)
          else
            for (final invoice in _purchases)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Text('₹${invoice.totalAmount.toStringAsFixed(2)}', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
