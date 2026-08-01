import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customer_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({this.customer, super.key});
  final CustomerEntity? customer;

  bool get isEditing => customer != null;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final repository = ref.read(customerRepositoryProvider);
    final result = widget.isEditing
        ? await repository.updateCustomer(
            id: widget.customer!.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          )
        : await repository.createCustomer(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit customer' : 'Add customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _nameController,
                enabled: !_isSubmitting,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone (optional)',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email (optional)',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSubmitting,
                validator: (v) => (v != null && v.isNotEmpty && !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Address (optional)',
                controller: _addressController,
                maxLines: 2,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes (optional)',
                controller: _notesController,
                maxLines: 3,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.isEditing ? 'Save changes' : 'Add customer',
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
