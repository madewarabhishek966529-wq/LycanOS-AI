import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/customers/domain/entities/customer_entity.dart';

void main() {
  group('CustomerEntity', () {
    test('hasOutstandingCredit is true when credit balance is positive', () {
      final customer = CustomerEntity(
        id: '1',
        name: 'Ravi',
        loyaltyPoints: 0,
        creditBalance: 150,
        createdAt: DateTime.now(),
      );
      expect(customer.hasOutstandingCredit, isTrue);
    });

    test('hasOutstandingCredit is false when credit balance is zero', () {
      final customer = CustomerEntity(
        id: '1',
        name: 'Ravi',
        loyaltyPoints: 0,
        creditBalance: 0,
        createdAt: DateTime.now(),
      );
      expect(customer.hasOutstandingCredit, isFalse);
    });
  });
}
