import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/employee_entity.dart';
import '../providers/employee_providers.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  const EmployeeDetailScreen({required this.employeeId, super.key});
  final String employeeId;

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  EmployeeEntity? _employee;
  List<AttendanceEntity> _attendance = [];
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

    final repository = ref.read(employeeRepositoryProvider);
    final employeeResult = await repository.getEmployee(widget.employeeId);
    final attendanceResult = await repository.getAttendanceHistory(widget.employeeId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (employeeResult is Success<EmployeeEntity>) _employee = employeeResult.data;
      if (attendanceResult is Success<List<AttendanceEntity>>) _attendance = attendanceResult.data;
      if (employeeResult is Error<EmployeeEntity>) _errorMessage = employeeResult.failure.message;
    });
  }

  Future<void> _toggleActive() async {
    if (_employee == null) return;
    final result = await ref.read(employeeRepositoryProvider).updateEmployee(
          id: _employee!.id,
          isActive: !_employee!.isActive,
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() => _employee = data);
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _updateSalary() async {
    final controller = TextEditingController(text: _employee?.salary?.toStringAsFixed(2) ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update monthly salary'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;

    final updateResult = await ref.read(employeeRepositoryProvider).updateEmployee(id: widget.employeeId, salary: result);
    if (!mounted) return;
    switch (updateResult) {
      case Success(:final data):
        setState(() => _employee = data);
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider.select((s) => s.user));
    final canManage = currentUser?.canManageBusiness ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(_employee?.fullName ?? 'Employee')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _employee == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildProfileCard(canManage),
                          const SizedBox(height: 16),
                          _buildAttendanceHistory(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileCard(bool canManage) {
    final theme = Theme.of(context);
    final e = _employee!;
    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.fullName, style: theme.textTheme.titleLarge),
                    Text(e.email, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Chip(label: Text(e.role.toUpperCase())),
            ],
          ),
          const SizedBox(height: 12),
          if (e.phone != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('Phone: ${e.phone}')),
          if (e.salary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Salary: ₹${e.salary!.toStringAsFixed(2)} / month'),
            ),
          if (e.hireDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Hired: ${e.hireDate!.year}-${e.hireDate!.month.toString().padLeft(2, '0')}-${e.hireDate!.day.toString().padLeft(2, '0')}'),
            ),
          if (canManage) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: _updateSalary, child: const Text('Update salary')),
                OutlinedButton(
                  onPressed: e.isOwner ? null : _toggleActive,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: e.isActive ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                  child: Text(e.isActive ? 'Deactivate' : 'Reactivate'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    final theme = Theme.of(context);
    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance (last 30 days)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_attendance.isEmpty)
            Text('No attendance records yet', style: theme.textTheme.bodyMedium)
          else
            for (final record in _attendance)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}',
                    ),
                    Text(
                      record.isComplete
                          ? '${record.hoursWorked!.inHours}h ${record.hoursWorked!.inMinutes % 60}m'
                          : record.isCheckedIn
                              ? 'Checked in'
                              : record.status,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
