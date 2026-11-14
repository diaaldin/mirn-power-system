# Standalone Payment Receipts & Supplier Payment Vouchers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Standalone Payment Receipts (سندات القبض / קבלות) and Supplier Payment Vouchers (سندات الصرف / תשלומי ספקים) module with open-balance debt settlement, automatic check registry ingestion, and Israeli standard A4 PDF document generation.

**Architecture:** Pure Dart domain models and transactional settlement services decouple receipt validation from UI. Customer receipts deduct on-account debt and append audited credit entries to `StatementEntry` while feeding received checks into the Check state machine. Supplier vouchers record payables reduction and issue checks. A specialized PDF generator outputs compliant bilingual A4 receipts.

**Tech Stack:** Dart 3.x, Flutter 3.x, `pdf` package, `intl`, `test`.

**Spec:** `docs/superpowers/specs/2026-11-13-sales-accounting-logistics-design.md` (Section 2.1 #7, Section 4.5, Section 4.9, Section 4.10)

## Global Constraints
- Currency: Israeli New Shekel (ILS / ₪) formatted with 2 decimal places.
- Settlement Model: Open-Balance Ledger (no manual invoice pairing required; payments reduce net customer debt).
- Sequential Numbering: `REC-YYYY-xxxxx` for customer receipts, `PAY-YYYY-xxxxx` for supplier payments.
- Trilingual Support: Arabic (default RTL), Hebrew (official statutory RTL), English (LTR).
- PDF Documents: Standard A4 format with M.I.R.N POWER luxury branding, Hebrew & Arabic legal headers, and exact payment channel breakdowns.

## Review Focus
- Floating-point currency drift during multi-check receipt settlements (must round to exact 2-decimal agorot).
- Handling receipts with amount exceeding current debt (must allow customer to transition to credit balance negative debt without throwing).
- Zero or negative payment amounts in receipt split breakdown (must be strictly rejected).
- Check details validation: when a check payment method is used in a receipt, check number, bank, and future due date must be mandatory.
- Customer vs. Supplier isolation: receipts must not allow customer contact IDs on supplier payment vouchers and vice-versa.

---

### Task 1: `PaymentReceipt` Domain Model & Line Items

**Files:**
- Create: `lib/features/receipts/domain/models/payment_receipt.dart`
- Test: `test/features/receipts/payment_receipt_model_test.dart`

**Interfaces:**
- Consumes: `lib/features/accounts/domain/models/contact.dart` (`ContactType`), `lib/features/sales/domain/models/payment_split.dart` (`PaymentMethod`).
- Produces: `PaymentReceipt`, `ReceiptPaymentItem`, `ReceiptType` (`customerReceipt`, `supplierPayment`).

- [ ] **Step 1: Write failing test for `PaymentReceipt` model**

```dart
// test/features/receipts/payment_receipt_model_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';

void main() {
  group('PaymentReceipt Model Tests', () {
    test('creates valid customer receipt and validates total match', () {
      final receipt = PaymentReceipt(
        id: 'rec-001',
        receiptNumber: 'REC-2026-00001',
        date: DateTime(2026, 11, 14, 10, 30),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق للمقاولات',
        totalAmount: 15000.0,
        payments: [
          const ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 5000.0,
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 10000.0,
            checkNumber: '10495',
            bankName: 'בנק הפועלים (12)',
            branchNumber: '680',
            accountNumber: '445910',
            dueDate: DateTime(2026, 12, 1),
          ),
        ],
        notes: 'دفعة على الحساب',
        createdBy: 'admin-01',
        createdAt: DateTime(2026, 11, 14),
      );

      expect(receipt.totalAmount, equals(15000.0));
      expect(receipt.payments.length, equals(2));
      expect(receipt.isPaymentBalanced, isTrue);
    });

    test('rejects receipt where payments do not equal total amount', () {
      expect(
        () => PaymentReceipt(
          id: 'rec-002',
          receiptNumber: 'REC-2026-00002',
          date: DateTime.now(),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 10000.0,
          payments: [
            const ReceiptPaymentItem(
              method: PaymentMethod.cash,
              amount: 8000.0,
            ),
          ],
          createdBy: 'admin-01',
          createdAt: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });

    test('rejects receipt with negative or zero total amount', () {
      expect(
        () => PaymentReceipt(
          id: 'rec-003',
          receiptNumber: 'REC-2026-00003',
          date: DateTime.now(),
          partyType: ContactType.customer,
          contactId: 'cust-101',
          contactName: 'شركة البراق',
          totalAmount: 0.0,
          payments: const [],
          createdBy: 'admin-01',
          createdAt: DateTime.now(),
        ),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/payment_receipt_model_test.dart`
Expected: FAIL (file and types not defined)

- [ ] **Step 3: Implement `PaymentReceipt` and `ReceiptPaymentItem`**

Create `lib/features/receipts/domain/models/payment_receipt.dart` with fields:
`id`, `receiptNumber`, `date`, `partyType`, `contactId`, `contactName`, `totalAmount`, `payments`, `notes`, `createdBy`, `createdAt`.
Include validation: `totalAmount > 0`, payments sum equals `totalAmount` within 0.01 tolerance, and JSON serialization.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/payment_receipt_model_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/features/receipts/domain/models/payment_receipt.dart test/features/receipts/payment_receipt_model_test.dart
git commit -m "feat(receipts): implement PaymentReceipt domain model with payment balance validation"
```

---

### Task 2: `ReceiptService` Customer Debt Settlement Engine

**Files:**
- Create: `lib/features/receipts/domain/services/receipt_service.dart`
- Test: `test/features/receipts/receipt_service_test.dart`

**Interfaces:**
- Consumes: `PaymentReceipt`, `Contact`, `StatementEntry`, `StatementEntryType`, `CheckRecord`, `CheckStatus`, `CheckType`.
- Produces: `ReceiptService.processCustomerReceipt(contact: Contact, receiptData: CreateReceiptInput) -> ProcessCustomerReceiptResult`.

- [ ] **Step 1: Write failing test for customer receipt settlement**

```dart
// test/features/receipts/receipt_service_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/checks/domain/models/check_record.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';
import 'package:sales_logistics_system/features/receipts/domain/services/receipt_service.dart';

void main() {
  group('ReceiptService - Customer Debt Settlement Engine', () {
    late Contact customer;

    setUp(() {
      customer = const Contact(
        id: 'cust-101',
        type: ContactType.customer,
        name: 'شركة البراق للمقاولات العامة',
        phone: '052-1234567',
        address: 'رام الله',
        taxId: '515892104',
        debtWarningLimit: 50000.0,
        currentBalance: 38200.0,
      );
    });

    test('deducts debt, generates credit statement entry, and registers pending checks', () {
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00001',
        date: DateTime(2026, 11, 14, 11, 0),
        amount: 15000.0,
        payments: [
          const ReceiptPaymentItem(
            method: PaymentMethod.cash,
            amount: 5000.0,
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 10000.0,
            checkNumber: '88201',
            bankName: 'בנק הפועלים (12)',
            branchNumber: '680',
            accountNumber: '445910',
            dueDate: DateTime(2026, 12, 15),
          ),
        ],
        notes: 'تسديد دفعة كشف حساب',
        createdBy: 'admin-01',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: customer,
        input: input,
      );

      // Verify contact balance reduced by 15,000.00
      expect(result.updatedContact.currentBalance, equals(23200.0));

      // Verify statement entry
      expect(result.statementEntry.type, equals(StatementEntryType.paymentReceipt));
      expect(result.statementEntry.referenceNumber, equals('REC-2026-00001'));
      expect(result.statementEntry.credit, equals(15000.0));
      expect(result.statementEntry.debit, equals(0.0));
      expect(result.statementEntry.runningBalance, equals(23200.0));

      // Verify check registered in pending state
      expect(result.createdChecks.length, equals(1));
      final chk = result.createdChecks.first;
      expect(chk.checkNumber, equals('88201'));
      expect(chk.amount, equals(10000.0));
      expect(chk.type, equals(CheckType.received));
      expect(chk.status, equals(CheckStatus.pending));
      expect(chk.partyId, equals('cust-101'));
    });

    test('allows payment exceeding current debt, resulting in credit customer balance', () {
      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00002',
        date: DateTime.now(),
        amount: 40000.0, // 38,200 debt - 40,000 = -1,800 (customer in credit)
        payments: const [
          ReceiptPaymentItem(method: PaymentMethod.cash, amount: 40000.0),
        ],
        createdBy: 'admin-01',
      );

      final result = ReceiptService.processCustomerReceipt(
        contact: customer,
        input: input,
      );

      expect(result.updatedContact.currentBalance, equals(-1800.0));
      expect(result.statementEntry.runningBalance, equals(-1800.0));
    });

    test('rejects receipt if contact is not a customer or both', () {
      const supplierOnly = Contact(
        id: 'sup-201',
        type: ContactType.supplier,
        name: 'سيراميك رويال',
        phone: '050-0000000',
        address: 'حيفا',
        taxId: '512000000',
        debtWarningLimit: 0.0,
        currentBalance: 0.0,
      );

      final input = CreateReceiptInput(
        receiptNumber: 'REC-2026-00003',
        date: DateTime.now(),
        amount: 1000.0,
        payments: const [
          ReceiptPaymentItem(method: PaymentMethod.cash, amount: 1000.0),
        ],
        createdBy: 'admin-01',
      );

      expect(
        () => ReceiptService.processCustomerReceipt(contact: supplierOnly, input: input),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/receipt_service_test.dart`
Expected: FAIL (`ReceiptService` not defined)

- [ ] **Step 3: Implement `ReceiptService.processCustomerReceipt`**

Implement `ReceiptService` in `lib/features/receipts/domain/services/receipt_service.dart`:
- Validate `contact.type != ContactType.supplier`.
- Calculate new balance: `(contact.currentBalance - input.amount)`.
- Build `StatementEntry` with `StatementEntryType.paymentReceipt`.
- Generate `CheckRecord` items for each payment item with `method == PaymentMethod.check`.
- Return `ProcessCustomerReceiptResult`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/receipt_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/features/receipts/domain/services/receipt_service.dart test/features/receipts/receipt_service_test.dart
git commit -m "feat(receipts): implement ReceiptService customer debt settlement and check ingestion"
```

---

### Task 3: `ReceiptService` Supplier Payment Voucher Engine (سند صرف)

**Files:**
- Modify: `lib/features/receipts/domain/services/receipt_service.dart`
- Modify: `test/features/receipts/receipt_service_test.dart`

**Interfaces:**
- Consumes: `Contact`, `StatementEntryType.supplierPayment`, `CheckType.issued`.
- Produces: `ReceiptService.processSupplierPayment(contact: Contact, input: CreateSupplierPaymentInput) -> ProcessSupplierPaymentResult`.

- [ ] **Step 1: Write failing test for supplier payment voucher**

Add test group to `test/features/receipts/receipt_service_test.dart`:
- Pay supplier ₪20,000.00 (Cash ₪5,000 + Issued Check ₪15,000).
- Verifies supplier balance is debited (`runningBalance` updated).
- Verifies `StatementEntryType.supplierPayment` entry created.
- Verifies issued check created with `type: CheckType.issued`, `partyId: supplier.id`, and `status: CheckStatus.pending`.
- Verifies rejection if contact is purely `ContactType.customer`.

- [ ] **Step 2: Run test to verify it fails**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/receipt_service_test.dart`
Expected: FAIL (`processSupplierPayment` not defined)

- [ ] **Step 3: Implement `ReceiptService.processSupplierPayment`**

In `lib/features/receipts/domain/services/receipt_service.dart`:
- Validate `contact.type != ContactType.customer`.
- Compute updated supplier balance (`contact.currentBalance - input.amount`).
- Generate `StatementEntry` of type `StatementEntryType.supplierPayment` (`debit: input.amount, credit: 0.0`).
- Create issued checks with `type: CheckType.issued`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/receipt_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/features/receipts/domain/services/receipt_service.dart test/features/receipts/receipt_service_test.dart
git commit -m "feat(receipts): implement supplier payment voucher settlement and issued checks"
```

---

### Task 4: Israeli Standard A4 Payment Receipt & Voucher PDF Generator

**Files:**
- Create: `lib/core/pdf/receipt_pdf_generator.dart`
- Test: `test/core/pdf/receipt_pdf_test.dart`

**Interfaces:**
- Consumes: `PaymentReceipt`, `Contact`, `CompanyInfo`, `formatCurrency`.
- Produces: `ReceiptPdfGenerator.generate(receipt: PaymentReceipt, contact: Contact, company: CompanyInfo, previousBalance: double, newBalance: double) -> Future<Uint8List>`.

- [ ] **Step 1: Write failing test for A4 PDF generator**

```dart
// test/core/pdf/receipt_pdf_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/receipt_pdf_generator.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';

void main() {
  group('ReceiptPdfGenerator Tests', () {
    test('generates valid non-empty PDF bytes for customer payment receipt', () async {
      final receipt = PaymentReceipt(
        id: 'rec-001',
        receiptNumber: 'REC-2026-00001',
        date: DateTime(2026, 11, 14, 12, 0),
        partyType: ContactType.customer,
        contactId: 'cust-101',
        contactName: 'شركة البراق للمقاولات العامة',
        totalAmount: 15000.0,
        payments: [
          const ReceiptPaymentItem(method: PaymentMethod.cash, amount: 5000.0),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 10000.0,
            checkNumber: '88201',
            bankName: 'בנק הפועלים',
            dueDate: DateTime(2026, 12, 15),
          ),
        ],
        createdBy: 'admin',
        createdAt: DateTime.now(),
      );

      const contact = Contact(
        id: 'cust-101',
        type: ContactType.customer,
        name: 'شركة البراق للمقاولات العامة',
        phone: '052-1234567',
        address: 'رام الله',
        taxId: '515892104',
        debtWarningLimit: 50000.0,
        currentBalance: 23200.0,
      );

      const company = CompanyInfo(
        nameArabic: 'شركة م.ي.ر.ن باور م.ض',
        nameHebrew: 'מ.י.ר.ן פאוור בע"מ',
        subtitleArabic: 'كلים סניטריים, שיש, אבן והובלה',
        subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
        taxId: '515892104',
        phone: '02-1234567',
        address: 'אזור התעשייה עטרות / عطروت',
      );

      final pdfBytes = await ReceiptPdfGenerator.generate(
        receipt: receipt,
        contact: contact,
        company: company,
        previousBalance: 38200.0,
        newBalance: 23200.0,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF header magic bytes %PDF-
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/core/pdf/receipt_pdf_test.dart`
Expected: FAIL (`ReceiptPdfGenerator` not defined)

- [ ] **Step 3: Implement `ReceiptPdfGenerator`**

Create `lib/core/pdf/receipt_pdf_generator.dart` using `pdf/widgets.dart`:
- Header with Gold & Charcoal accents and Company Information.
- Document title: "קבלה / سند قبض" (or "אישור תשלום לספק / سند صرف").
- Receipt Number and Issue Date.
- Party information block (Name, Phone, Address, Osek Murshe / Tax ID).
- Amount summary in Shekels (₪).
- Detailed Payment Method Table:
  - Payment Type (Cash, Check, Bank Transfer).
  - Details / Ref (Check #, Bank, Due Date).
  - Amount (₪).
- Customer Statement Reconciliation Box:
  - Previous Debt Balance: ₪38,200.00
  - Amount Paid: -₪15,000.00
  - Remaining Balance: ₪23,200.00
- Legal disclaimer and Cashier Signature / Stamp box.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/core/pdf/receipt_pdf_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/core/pdf/receipt_pdf_generator.dart test/core/pdf/receipt_pdf_test.dart
git commit -m "feat(pdf): implement Israeli standard A4 Payment Receipt and Voucher PDF generator"
```

---

### Task 5: `ReceiptsController` Presentation State Machine

**Files:**
- Create: `lib/features/receipts/presentation/controllers/receipts_controller.dart`
- Test: `test/features/receipts/receipts_controller_test.dart`

**Interfaces:**
- Consumes: `ReceiptService`, `PaymentReceipt`, `Contact`.
- Produces: `ReceiptsController`, `ReceiptFormState`.

- [ ] **Step 1: Write failing test for `ReceiptsController`**

```dart
// test/features/receipts/receipts_controller_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/presentation/controllers/receipts_controller.dart';

void main() {
  group('ReceiptsController Tests', () {
    test('calculates remaining allocation and projected new balance', () {
      const customer = Contact(
        id: 'cust-101',
        type: ContactType.customer,
        name: 'شركة البراق',
        phone: '052-1234567',
        address: 'رام الله',
        taxId: '515892104',
        debtWarningLimit: 50000.0,
        currentBalance: 30000.0,
      );

      final controller = ReceiptsController(initialContact: customer);
      controller.setTotalAmount(10000.0);

      expect(controller.state.remainingToAllocate, equals(10000.0));
      expect(controller.state.projectedBalance, equals(20000.0));
      expect(controller.state.isComplete, isFalse);

      controller.addPaymentLine(
        method: PaymentMethod.cash,
        amount: 4000.0,
      );
      expect(controller.state.remainingToAllocate, equals(6000.0));

      controller.addPaymentLine(
        method: PaymentMethod.bankTransfer,
        amount: 6000.0,
        reference: 'TRF-9941',
      );
      expect(controller.state.remainingToAllocate, equals(0.0));
      expect(controller.state.isComplete, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/receipts_controller_test.dart`
Expected: FAIL (`ReceiptsController` not defined)

- [ ] **Step 3: Implement `ReceiptsController`**

Create `lib/features/receipts/presentation/controllers/receipts_controller.dart`:
- Manage target contact, total receipt amount, payment items list, notes.
- Compute `remainingToAllocate`, `projectedBalance`, and `isComplete`.
- Expose `submitCustomerReceipt()` calling `ReceiptService.processCustomerReceipt`.

- [ ] **Step 4: Run test to verify it passes**

Run: `& "D:\flutter\bin\cache\dart-sdk\bin\dart.exe" test test/features/receipts/receipts_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add lib/features/receipts/presentation/controllers/receipts_controller.dart test/features/receipts/receipts_controller_test.dart
git commit -m "feat(receipts): implement ReceiptsController presentation state machine"
```

---

### Task 6: UI Integration & Verification

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `ReceiptsController`, `ReceiptPdfGenerator`.
- Produces: Integrated "سند قبض / קבלה" modal action in Customer Statement view.

- [ ] **Step 1: Add Payment Receipt action button and dialog in `lib/main.dart`**
- In `_buildStatementScreen()`, add a "سند قبض جديد / קבלה חדשה" button next to "تصدير PDF".
- Clicking opens a dialog allowing quick entry of Cash / Check payment, updating customer balance live in the session.

- [ ] **Step 2: Verify `dart analyze lib/main.dart`**
- Run static analyzer to confirm 0 errors and 0 warnings.

- [ ] **Step 3: Run full project test suite**
- Run all test files including receipt tests, verifying 100% green suite.

- [ ] **Step 4: Commit**

```powershell
git add lib/main.dart test/widget_test.dart
git commit -m "feat(ui): integrate customer payment receipt workflow into statement screen"
```
