import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/features/accounts/presentation/screens/statement_screen.dart';
import 'package:sales_logistics_system/features/checks/presentation/screens/checks_screen.dart';

void main() {
  group('Statement of Account & Checks Presentation Controllers', () {
    const company = CompanyInfo(
      name: 'M.I.R.N POWER',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      taxId: '516000999',
      phone: '02-1234567',
      address: 'Jerusalem',
    );

    final customer = Contact(
      id: 'cust-60',
      type: ContactType.customer,
      name: 'Beit Jala Construction Co.',
      phone: '059-3334444',
      address: 'Beit Jala',
      taxId: '516666555',
      debtWarningLimit: 25000.0,
      currentBalance: 7500.0,
    );

    final entries = [
      StatementEntry(
        id: 'st-01',
        contactId: customer.id,
        contactType: ContactType.customer,
        date: DateTime(2026, 11, 1),
        type: StatementEntryType.saleInvoice,
        referenceNumber: 'INV-2026-00001',
        debit: 5000.0,
        credit: 0.0,
        runningBalance: 5000.0,
        description: 'Invoice 1 Marble Order',
      ),
      StatementEntry(
        id: 'st-02',
        contactId: customer.id,
        contactType: ContactType.customer,
        date: DateTime(2026, 11, 5),
        type: StatementEntryType.paymentReceipt,
        referenceNumber: 'REC-2026-00001',
        debit: 0.0,
        credit: 2000.0,
        runningBalance: 3000.0,
        description: 'Cash payment on account',
      ),
      StatementEntry(
        id: 'st-03',
        contactId: customer.id,
        contactType: ContactType.customer,
        date: DateTime(2026, 11, 10),
        type: StatementEntryType.saleInvoice,
        referenceNumber: 'INV-2026-00002',
        debit: 4500.0,
        credit: 0.0,
        runningBalance: 7500.0,
        description: 'Invoice 2 Sanitary Fixtures',
      ),
    ];

    test('StatementScreenController filters entries by date range and calculates net totals', () {
      final controller = StatementScreenController(
        contact: customer,
        allEntries: entries,
      );

      final totalsAll = controller.getTotals();
      expect(totalsAll.totalDebits, equals(9500.0));
      expect(totalsAll.totalCredits, equals(2000.0));
      expect(totalsAll.closingBalance, equals(7500.0));

      // Filter by date: from Nov 4 to Nov 15 (should omit entry 1)
      controller.setDateFilter(
        fromDate: DateTime(2026, 11, 4),
        toDate: DateTime(2026, 11, 15),
      );

      final filtered = controller.getFilteredEntries();
      expect(filtered.length, equals(2));
      expect(filtered.first.referenceNumber, equals('REC-2026-00001'));
      expect(filtered.last.referenceNumber, equals('INV-2026-00002'));
    });

    test('StatementScreenController generates exportable PDF bytes', () async {
      final controller = StatementScreenController(
        contact: customer,
        allEntries: entries,
      );

      final Uint8List pdf = await controller.exportPdf(company: company);
      expect(pdf, isNotEmpty);
      expect(String.fromCharCodes(pdf.take(5)), equals('%PDF-'));
    });

    test('ChecksScreenController manages check registry and lifecycle transitions', () {
      final check1 = CheckRecord(
        id: 'c-1',
        checkNumber: '1001',
        bankName: 'Bank Leumi',
        branchNumber: '800',
        accountNumber: '111',
        amount: 3000.0,
        dueDate: DateTime(2026, 12, 1),
        type: CheckType.received,
        partyId: customer.id,
        partyName: customer.name,
        relatedTransactionId: 'INV-1',
        status: CheckStatus.pending,
        history: [],
        createdAt: DateTime(2026, 11, 1),
      );

      final check2 = CheckRecord(
        id: 'c-2',
        checkNumber: '1002',
        bankName: 'Bank Hapoalim',
        branchNumber: '600',
        accountNumber: '222',
        amount: 2000.0,
        dueDate: DateTime(2026, 12, 15),
        type: CheckType.received,
        partyId: customer.id,
        partyName: customer.name,
        relatedTransactionId: 'INV-2',
        status: CheckStatus.deposited,
        history: [],
        createdAt: DateTime(2026, 11, 1),
      );

      final controller = ChecksScreenController(initialChecks: [check1, check2]);

      expect(controller.totalPendingAmount, equals(3000.0));
      expect(controller.totalDepositedAmount, equals(2000.0));

      // Filter by status: pending
      controller.setStatusFilter(CheckStatus.pending);
      expect(controller.filteredChecks.length, equals(1));
      expect(controller.filteredChecks.first.checkNumber, equals('1001'));

      // Transition check1 to deposited
      controller.depositCheck(checkId: 'c-1', notes: 'Deposited into branch');
      final updatedCheck1 = controller.getCheckById('c-1')!;
      expect(updatedCheck1.status, equals(CheckStatus.deposited));
      expect(controller.totalDepositedAmount, equals(5000.0));
    });
    test('includes transactions on end date with timestamps and computes opening balance (IMP-4 & IMP-5)', () {
      final entriesWithTime = [
        StatementEntry(
          id: 'st-early',
          contactId: customer.id,
          contactType: ContactType.customer,
          date: DateTime(2026, 10, 15),
          type: StatementEntryType.saleInvoice,
          referenceNumber: 'INV-OCT-1',
          debit: 1000.0,
          credit: 0.0,
          runningBalance: 1000.0,
          description: 'October Order',
        ),
        StatementEntry(
          id: 'st-end-date',
          contactId: customer.id,
          contactType: ContactType.customer,
          date: DateTime(2026, 11, 15, 14, 30), // 2:30 PM on Nov 15
          type: StatementEntryType.paymentReceipt,
          referenceNumber: 'REC-2026-00005',
          debit: 0.0,
          credit: 500.0,
          runningBalance: 500.0,
          description: 'Payment on Nov 15 afternoon',
        ),
      ];

      final controller = StatementScreenController(
        contact: customer,
        allEntries: entriesWithTime,
      );

      controller.setDateFilter(
        fromDate: DateTime(2026, 11, 1),
        toDate: DateTime(2026, 11, 15), // Midnight start of Nov 15
      );

      final filtered = controller.getFilteredEntries();
      // Should include the Nov 15 14:30 entry!
      expect(filtered.length, equals(1));
      expect(filtered.first.referenceNumber, equals('REC-2026-00005'));

      final totals = controller.getTotals();
      expect(totals.openingBalance, equals(1000.0));
      expect(totals.totalCredits, equals(500.0));
    });
  });
}
