import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/checks/domain/services/check_state_machine.dart';

void main() {
  group('Check Registry & Lifecycle State Machine', () {
    final customer = Contact(
      id: 'cust-30',
      type: ContactType.customer,
      name: 'Hebron Stone Works',
      phone: '059-7777777',
      address: 'Hebron',
      taxId: '518888777',
      debtWarningLimit: 30000.0,
      currentBalance: 1000.0,
    );

    final check = CheckRecord(
      id: 'chk-001',
      checkNumber: '887654',
      bankName: 'Bank Leumi (10)',
      branchNumber: '800',
      accountNumber: '123456',
      amount: 4500.0,
      dueDate: DateTime(2026, 12, 1),
      type: CheckType.received,
      partyId: customer.id,
      partyName: customer.name,
      relatedTransactionId: 'INV-2026-00010',
      status: CheckStatus.pending,
      history: [],
      createdAt: DateTime(2026, 11, 14),
    );

    test('valid lifecycle: pending -> deposited -> cleared', () {
      final deposited = CheckStateMachine.transition(
        check: check,
        targetStatus: CheckStatus.deposited,
        notes: 'Deposited into Bank Hapoalim account',
      );
      expect(deposited.updatedCheck.status, equals(CheckStatus.deposited));
      expect(deposited.updatedCheck.history.length, equals(1));

      final cleared = CheckStateMachine.transition(
        check: deposited.updatedCheck,
        targetStatus: CheckStatus.cleared,
        notes: 'Check funds cleared by bank',
      );
      expect(cleared.updatedCheck.status, equals(CheckStatus.cleared));
      expect(cleared.updatedCheck.history.length, equals(2));
      expect(cleared.updatedContact, isNull);
      expect(cleared.statementEntry, isNull);
    });

    test('bounce protection: re-applies debt to customer and creates check_bounced statement entry', () {
      final deposited = CheckStateMachine.transition(
        check: check,
        targetStatus: CheckStatus.deposited,
      );

      final bounceResult = CheckStateMachine.transition(
        check: deposited.updatedCheck,
        targetStatus: CheckStatus.bounced,
        notes: 'Insufficient funds (אין כיסוי מספיק)',
        contact: customer,
      );

      expect(bounceResult.updatedCheck.status, equals(CheckStatus.bounced));

      // Customer debt balance re-applied: 1000 + 4500 = 5500
      expect(bounceResult.updatedContact, isNotNull);
      expect(bounceResult.updatedContact!.currentBalance, equals(5500.0));

      // Statement Entry created
      expect(bounceResult.statementEntry, isNotNull);
      expect(bounceResult.statementEntry!.type, equals(StatementEntryType.checkBounced));
      expect(bounceResult.statementEntry!.debit, equals(4500.0));
      expect(bounceResult.statementEntry!.runningBalance, equals(5500.0));
      expect(bounceResult.statementEntry!.referenceNumber, equals('CHK-887654'));
    });

    test('requires endorsedToPartyId when transitioning to endorsed', () {
      expect(
        () => CheckStateMachine.transition(
          check: check,
          targetStatus: CheckStatus.endorsed,
        ),
        throwsA(isA<InvalidCheckEndorsementException>()),
      );

      final endorsed = CheckStateMachine.transition(
        check: check,
        targetStatus: CheckStatus.endorsed,
        endorsedToPartyId: 'supp-99',
        notes: 'Endorsed to Marble Quarry supplier',
      );
      expect(endorsed.updatedCheck.status, equals(CheckStatus.endorsed));
      expect(endorsed.updatedCheck.endorsedToPartyId, equals('supp-99'));
    });

    test('rejects invalid state transitions (e.g. cleared back to pending)', () {
      final cleared = CheckRecord(
        id: 'chk-002',
        checkNumber: '112233',
        bankName: 'Bank Hapoalim',
        branchNumber: '600',
        accountNumber: '998877',
        amount: 2000.0,
        dueDate: DateTime(2026, 11, 1),
        type: CheckType.received,
        partyId: customer.id,
        partyName: customer.name,
        relatedTransactionId: 'INV-001',
        status: CheckStatus.cleared,
        history: [],
        createdAt: DateTime(2026, 11, 1),
      );

      expect(
        () => CheckStateMachine.transition(
          check: cleared,
          targetStatus: CheckStatus.pending,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });
    test('bouncing a received check requires customer contact (CRIT-3)', () {
      final deposited = CheckStateMachine.transition(
        check: check,
        targetStatus: CheckStatus.deposited,
      );

      expect(
        () => CheckStateMachine.transition(
          check: deposited.updatedCheck,
          targetStatus: CheckStatus.bounced,
          contact: null, // missing contact!
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
