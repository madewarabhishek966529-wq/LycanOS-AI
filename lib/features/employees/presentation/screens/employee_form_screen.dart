import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/employee_providers.dart';

/// Only an Owner can create a Manager (enforced server-side too — this is
/// a UX nicety, not the actual security boundary) — see
/// backend/app/services/employee_service.py.
class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  String _role = 'cashier';
  DateTime? _hireDate;
  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ref.read(employeeRepositoryProvider).createEmployee(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: _role,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          salary: double.tryParse(_salaryController.text),
          hireDate: _hireDate,
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
    final currentUser = ref.watch(authStateProvider.select((s) => s.user));
    final isOwner = currentUser?.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Add employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _fullNameController,
                enabled: !_isSubmitting,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSubmitting,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Temporary password',
                controller: _passwordController,
                obscureText: _obscure,
                enabled: !_isSubmitting,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) return 'At least 8 characters';
                  if (!v.contains(RegExp(r'[A-Za-z]')) || !v.contains(RegExp(r'[0-9]'))) {
                    return 'Must contain a letter and a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  const DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  const DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(
                    value: 'manager',
                    enabled: isOwner,
                    child: Text(isOwner ? 'Manager' : 'Manager (Owner only)'),
                  ),
                ],
                onChanged: _isSubmitting ? null : (value) => setState(() => _role = value ?? 'cashier'),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Phone (optional)', controller: _phoneController, enabled: !_isSubmitting),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Monthly salary (₹, optional)',
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hire date (optional)'),
                subtitle: Text(_hireDate != null
                    ? '${_hireDate!.year}-${_hireDate!.month.toString().padLeft(2, '0')}-${_hireDate!.day.toString().padLeft(2, '0')}'
                    : 'Not set'),
                trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _isSubmitting ? null : _pickHireDate),
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Add employee', onPressed: _submit, isLoading: _isSubmitting),
            ],
          ),
        ),
      ),
    );
  }
}
