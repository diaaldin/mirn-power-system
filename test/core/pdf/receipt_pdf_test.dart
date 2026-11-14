import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/receipt_pdf_generator.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/features/receipts/domain/models/payment_receipt.dart';

void main() {
  group('ReceiptPdfGenerator Tests', () {
    const company = CompanyInfo(
      nameArabic: 'شركة م.ي.ר.ن باور م.ض',
      nameHebrew: 'מ.י.ר.ן פאוור בע"מ',
      subtitleArabic: 'كلים סניטריים, שיש, אבן והובלה',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      taxId: '515892104',
      phone: '02-1234567',
      address: 'אזור התעשייה עטרות / عطروت',
    );

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
          ReceiptPaymentItem(method: PaymentMethod.cash, amount: 5000.0),
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

    test('generates valid PDF bytes for supplier payment voucher with balance reconciliation', () async {
      final voucher = PaymentReceipt(
        id: 'pay-001',
        receiptNumber: 'PAY-2026-00001',
        date: DateTime(2026, 11, 14, 14, 30),
        partyType: ContactType.supplier,
        contactId: 'supp-201',
        contactName: 'ספקי שיש איטליה בע"מ',
        totalAmount: 25000.0,
        payments: [
          ReceiptPaymentItem(
            method: PaymentMethod.bankTransfer,
            amount: 25000.0,
            reference: 'TR-998877',
          ),
        ],
        createdBy: 'finance_manager',
        createdAt: DateTime.now(),
      );

      const supplier = Contact(
        id: 'supp-201',
        type: ContactType.supplier,
        name: 'ספקי שיש איטליה בע"מ',
        phone: '03-9876543',
        address: 'חיפה',
        taxId: '514332211',
        debtWarningLimit: 100000.0,
        currentBalance: -50000.0,
      );

      final pdfBytes = await ReceiptPdfGenerator.generate(
        receipt: voucher,
        contact: supplier,
        company: company,
        previousBalance: -75000.0,
        newBalance: -50000.0,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });

    test('renders multi-check and cash split breakdown into valid PDF bytes', () async {
      final receipt = PaymentReceipt(
        id: 'rec-002',
        receiptNumber: 'REC-2026-00002',
        date: DateTime(2026, 11, 14, 15, 45),
        partyType: ContactType.customer,
        contactId: 'cust-102',
        contactName: 'חברת הבנייה המודרנית בע"מ',
        totalAmount: 32500.0,
        payments: [
          ReceiptPaymentItem(method: PaymentMethod.cash, amount: 2500.0),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 15000.0,
            checkNumber: '44551',
            bankName: 'בנק לאומי',
            branchNumber: '802',
            accountNumber: '112233',
            dueDate: DateTime(2026, 12, 10),
            drawerName: 'דוד לוי',
          ),
          ReceiptPaymentItem(
            method: PaymentMethod.check,
            amount: 15000.0,
            checkNumber: '44552',
            bankName: 'בנק לאומי',
            branchNumber: '802',
            accountNumber: '112233',
            dueDate: DateTime(2027, 1, 10),
            drawerName: 'דוד לוי',
          ),
        ],
        createdBy: 'cashier',
        createdAt: DateTime.now(),
      );

      const contact = Contact(
        id: 'cust-102',
        type: ContactType.customer,
        name: 'חברת הבנייה המודרנית בע"מ',
        phone: '054-9988776',
        address: 'תל אביב - יפו',
        taxId: '512345678',
        debtWarningLimit: 80000.0,
        currentBalance: 12000.0,
      );

      final pdfBytes = await ReceiptPdfGenerator.generate(
        receipt: receipt,
        contact: contact,
        company: company,
        previousBalance: 44500.0,
        newBalance: 12000.0,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });
  });
}
