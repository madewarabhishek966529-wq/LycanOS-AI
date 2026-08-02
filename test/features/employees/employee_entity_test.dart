import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/employees/domain/entities/employee_entity.dart';

void main() {
  group('AttendanceEntity', () {
    test('isCheckedIn is true when checked in but not out', () {
      final record = AttendanceEntity(
        id: '1',
        userId: 'u1',
        date: DateTime(2026, 1, 1),
        checkInAt: DateTime(2026, 1, 1, 9),
        status: 'present',
      );
      expect(record.isCheckedIn, isTrue);
      expect(record.isComplete, isFalse);
    });

    test('isComplete is true and hoursWorked computed when both times set', () {
      final record = AttendanceEntity(
        id: '1',
        userId: 'u1',
        date: DateTime(2026, 1, 1),
        checkInAt: DateTime(2026, 1, 1, 9, 0),
        checkOutAt: DateTime(2026, 1, 1, 17, 30),
        status: 'present',
      );
      expect(record.isComplete, isTrue);
      expect(record.hoursWorked, const Duration(hours: 8, minutes: 30));
    });

    test('hoursWorked is null before check-in', () {
      final record = AttendanceEntity(
        id: '1',
        userId: 'u1',
        date: DateTime(2026, 1, 1),
        status: 'absent',
      );
      expect(record.hoursWorked, isNull);
      expect(record.isCheckedIn, isFalse);
    });
  });

  group('EmployeeEntity', () {
    test('isOwner and isManager reflect role string', () {
      final owner = EmployeeEntity(
        id: '1',
        email: 'o@x.com',
        fullName: 'Owner',
        role: 'owner',
        isActive: true,
        createdAt: DateTime.now(),
      );
      final manager = EmployeeEntity(
        id: '2',
        email: 'm@x.com',
        fullName: 'Manager',
        role: 'manager',
        isActive: true,
        createdAt: DateTime.now(),
      );
      expect(owner.isOwner, isTrue);
      expect(owner.isManager, isFalse);
      expect(manager.isManager, isTrue);
    });
  });
}
