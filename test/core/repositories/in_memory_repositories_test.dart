import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_product_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_check_repository.dart';
import 'package:sales_logistics_system/core/repositories/in_memory/in_memory_dispatch_repository.dart';

void main() {
  group('InMemoryProductRepository', () {
    late InMemoryProductRepository repo;

    setUp(() {
      repo = InMemoryProductRepository(initialProducts: [
        const Product(
          id: 'p1',
          name: 'Marble Calacatta Gold',
          sku: 'MRB-001',
          category: ProductCategory.marble,
          unitType: UnitType.meter,
          purchaseCost: 200.0,
          sellingPrice: 300.0,
          currentStock: 100.0,
        ),
      ]);
    });

    tearDown(() {
      repo.dispose();
    });

    test('watchProducts emits current items and updates on stock change', () async {
      expect(
        repo.watchProducts(),
        emitsInOrder([
          hasLength(1),
          predicate<List<Product>>((list) => list.first.currentStock == 150.0),
        ]),
      );

      await repo.updateStock(productId: 'p1', stockDelta: 50.0);
    });

    test('secondary subscriber receives current items immediately without waiting for mutation', () async {
      // First listener
      final firstSub = repo.watchProducts().listen((_) {});

      // Second listener subscribing later
      expect(
        repo.watchProducts(),
        emits(hasLength(1)),
      );

      await firstSub.cancel();
    });

    test('updateStock throws ArgumentError if product does not exist', () async {
      expect(
        () => repo.updateStock(productId: 'non-existent', stockDelta: 10.0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('InMemoryContactRepository', () {
    late InMemoryContactRepository repo;

    setUp(() {
      repo = InMemoryContactRepository(initialContacts: [
        const Contact(
          id: 'c1',
          name: 'Al-Quds Contracting',
          phone: '050-1234567',
          address: 'Jerusalem Industrial',
          taxId: '515892104',
          debtWarningLimit: 20000.0,
          type: ContactType.customer,
          currentBalance: 5000.0,
        ),
      ]);
    });

    tearDown(() {
      repo.dispose();
    });

    test('updateBalance updates balance and emits snapshot', () async {
      expect(
        repo.watchContacts(),
        emitsInOrder([
          predicate<List<Contact>>((list) => list.first.currentBalance == 5000.0),
          predicate<List<Contact>>((list) => list.first.currentBalance == 8000.0),
        ]),
      );

      await repo.updateBalance(contactId: 'c1', balanceDelta: 3000.0);
    });

    test('addStatementEntry records entry and updates stream', () async {
      final entry = StatementEntry(
        id: 'st-01',
        contactId: 'c1',
        contactType: ContactType.customer,
        date: DateTime(2026, 11, 17),
        type: StatementEntryType.saleInvoice,
        referenceNumber: 'INV-2026-00001',
        description: 'Invoice INV-2026-00001',
        debit: 1000.0,
        credit: 0.0,
        runningBalance: 6000.0,
      );

      await repo.addStatementEntry(entry);
      final entries = await repo.getStatementEntries('c1');
      expect(entries, hasLength(1));
      expect(entries.first.id, equals('st-01'));
    });
  });

  group('InMemoryCheckRepository', () {
    late InMemoryCheckRepository repo;

    setUp(() {
      repo = InMemoryCheckRepository(initialChecks: [
        CheckRecord(
          id: 'chk-01',
          checkNumber: '100234',
          bankName: 'Bank Leumi',
          branchNumber: '600',
          accountNumber: '123456',
          amount: 2500.0,
          dueDate: DateTime(2026, 12, 1),
          type: CheckType.received,
          partyId: 'c1',
          partyName: 'Salim Builder',
          relatedTransactionId: 'inv-01',
          status: CheckStatus.pending,
          history: const [],
          createdAt: DateTime(2026, 11, 17),
        ),
      ]);
    });

    tearDown(() {
      repo.dispose();
    });

    test('updateCheckStatus advances status and records history entry', () async {
      await repo.updateCheckStatus('chk-01', CheckStatus.deposited);
      final check = await repo.getCheckById('chk-01');

      expect(check, isNotNull);
      expect(check!.status, equals(CheckStatus.deposited));
      expect(check.history, hasLength(1));
      expect(check.history.first.status, equals(CheckStatus.deposited));
    });
  });

  group('InMemoryDispatchRepository', () {
    late InMemoryDispatchRepository repo;

    setUp(() {
      repo = InMemoryDispatchRepository(initialDispatches: [
        Dispatch(
          id: 'dsp-01',
          dispatchNumber: 'DSP-2026-00001',
          date: DateTime(2026, 11, 17),
          customerId: 'c1',
          customerName: 'Al-Quds Contracting',
          customerPhone: '050-1234567',
          deliveryAddress: 'Ramallah Industrial Zone',
          cargoDescription: '50 m2 Marble slabs',
          vehicleId: 'veh-01',
          vehicleName: 'Mercedes Actros',
          plateNumber: '72-491-88',
          driverId: 'drv-01',
          driverName: 'Mahmoud Issa',
          status: DispatchStatus.pending,
          updatedAt: DateTime(2026, 11, 17),
        ),
      ]);
    });

    tearDown(() {
      repo.dispose();
    });

    test('updateDispatchStatus updates status and records timestamp', () async {
      await repo.updateDispatchStatus(
        'dsp-01',
        DispatchStatus.delivered,
        notes: 'Delivered successfully',
      );

      final dispatch = await repo.getDispatchById('dsp-01');
      expect(dispatch, isNotNull);
      expect(dispatch!.status, equals(DispatchStatus.delivered));
      expect(dispatch.notes, equals('Delivered successfully'));
    });
  });
}
