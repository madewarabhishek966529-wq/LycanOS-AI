import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customer_providers.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

/// Customer list: searchable by name/phone/email, with credit-balance and
/// loyalty-point badges so a cashier glancing at the list can immediately
/// see who owes money before starting a sale.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({CustomerEntity? customer}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );
    if (created == true) {
      ref.read(customerListProvider.notifier).loadCustomers();
    }
  }

  void _openDetail(CustomerEntity customer) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id)))
        .then((_) => ref.read(customerListProvider.notifier).loadCustomers());
  }

  Future<void> _confirmDelete(CustomerEntity customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('This removes "${customer.name}" from your customer list. This cannot be undone.'),
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
      final success = await ref.read(customerListProvider.notifier).deleteCustomer(customer.id);
      if (!mounted) return;
      if (!success) {
        final error = ref.read(customerListProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to delete customer')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, or email',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (value) => ref.read(customerListProvider.notifier).setSearchQuery(value),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add customer'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerListProvider.notifier).loadCustomers(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(CustomerListState state) {
    if (state.isLoading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(state.errorMessage!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(customerListProvider.notifier).loadCustomers(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.customers.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 96),
          Icon(Icons.people_alt_rounded, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              state.searchQuery.isNotEmpty ? 'No customers match your search' : 'No customers yet — add your first one',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: state.customers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = state.customers[index];
        return Dismissible(
          key: ValueKey(customer.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await _confirmDelete(customer);
            return false; // list refresh is handled by the delete action itself
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: ListTile(
            onTap: () => _openDetail(customer),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(customer.name),
            subtitle: Text(customer.phone ?? customer.email ?? 'No contact info'),
            trailing: customer.hasOutstandingCredit
                ? Chip(
                    label: Text('₹${customer.creditBalance.toStringAsFixed(0)} due'),
                    backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.12),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        );
      },
    );
  }
}
