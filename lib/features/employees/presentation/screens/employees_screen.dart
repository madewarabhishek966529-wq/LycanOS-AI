import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/employee_entity.dart';
import '../providers/employee_providers.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

/// Employees landing screen: a self-service attendance card up top (every
/// role sees this — clocking in isn't an Owner/Manager-only action), then
/// staff list + sales performance for Owner/Manager only, matching the
/// backend's RBAC exactly rather than hiding the list and hoping nobody
/// notices the 403.
class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  bool _isClockingInOut = false;
  AttendanceEntity? _todayAttendance;

  Future<void> _checkIn() async {
    setState(() => _isClockingInOut = true);
    final result = await ref.read(employeeRepositoryProvider).checkIn();
    if (!mounted) return;
    setState(() => _isClockingInOut = false);
    switch (result) {
      case Success(:final data):
        setState(() => _todayAttendance = data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in')));
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isClockingInOut = true);
    final result = await ref.read(employeeRepositoryProvider).checkOut();
    if (!mounted) return;
    setState(() => _isClockingInOut = false);
    switch (result) {
      case Success(:final data):
        setState(() => _todayAttendance = data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked out')));
      case Error(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
    );
    if (created == true) {
      ref.read(employeeListProvider.notifier).loadEmployees();
    }
  }

  void _openDetail(EmployeeEntity employee) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employeeId: employee.id)))
        .then((_) => ref.read(employeeListProvider.notifier).loadEmployees());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider.select((s) => s.user));
    final canManage = currentUser?.canManageBusiness ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add employee'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAttendanceCard(),
          if (canManage) ...[
            const SizedBox(height: 16),
            _buildSalesPerformance(),
            const SizedBox(height: 16),
            _buildEmployeeList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final theme = Theme.of(context);
    final isCheckedIn = _todayAttendance?.isCheckedIn ?? false;
    final isComplete = _todayAttendance?.isComplete ?? false;

    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's attendance", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (isComplete)
            Text('You checked out for the day. See you tomorrow!', style: theme.textTheme.bodyMedium)
          else
            AppButton(
              label: isCheckedIn ? 'Check out' : 'Check in',
              onPressed: isCheckedIn ? _checkOut : _checkIn,
              isLoading: _isClockingInOut,
              variant: isCheckedIn ? AppButtonVariant.secondary : AppButtonVariant.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildSalesPerformance() {
    final theme = Theme.of(context);
    final performanceAsync = ref.watch(salesPerformanceProvider);

    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales performance (30 days)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          performanceAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text('Could not load performance data', style: theme.textTheme.bodySmall),
            data: (performance) {
              if (performance.isEmpty) {
                return Text('No sales recorded yet', style: theme.textTheme.bodyMedium);
              }
              return Column(
                children: [
                  for (final entry in performance)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(entry.employeeName, overflow: TextOverflow.ellipsis)),
                          Text('${entry.invoiceCount} sales', style: theme.textTheme.bodySmall),
                          const SizedBox(width: 12),
                          Text('₹${entry.totalSales.toStringAsFixed(0)}', style: theme.textTheme.labelLarge),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    final theme = Theme.of(context);
    final state = ref.watch(employeeListProvider);

    if (state.isLoading && state.employees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.employees.isEmpty) {
      return Text(state.errorMessage!, style: theme.textTheme.bodyMedium);
    }

    return GlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Staff', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final employee in state.employees)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _openDetail(employee),
              leading: CircleAvatar(
                backgroundColor: employee.isActive
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.error.withOpacity(0.12),
                child: Text(
                  employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: employee.isActive ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(employee.fullName),
              subtitle: Text('${employee.role} · ${employee.email}'),
              trailing: employee.isActive ? null : const Chip(label: Text('Inactive'), padding: EdgeInsets.zero),
            ),
        ],
      ),
    );
  }
}
