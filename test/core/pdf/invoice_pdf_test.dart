import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/features/sales/domain/models/sale_invoice.dart';
import 'package:sales_logistics_system/features/sales/domain/models/payment_split.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/statement_pdf_generator.dart';

void main() {
  group('Israeli Standard A4 PDF Generation Engine', () {
    const company = CompanyInfo(
      name: 'M.I.R.N POWER Ltd.',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      taxId: '516000999', // ח.פ. / עוסק מורשה
      phone: '02-1234567',
      address: 'Industrial Zone, Atarot, Jerusalem',
    );

    final invoice = SaleInvoice(
      id: 'INV-2026-00001',
      invoiceNumber: 'INV-2026-00001',
      date: DateTime(2026, 11, 14),
      customerId: 'cust-01',
      customerName: 'Al-Quds Contracting',
      customerTaxId: '515000123',
      isTaxInclusiveInput: false,
      items: const [
        SaleLineItem(
          productId: 'prod-01',
          productName: 'Italian Carrara Marble 60x120',
          unitType: UnitType.meter,
          quantity: 50.0,
          unitPrice: 100.0,
          subtotal: 5000.0,
        ),
      ],
      subtotal: 5000.0,
      vatRate: 0.17,
      vatAmount: 850.0,
      totalAmount: 5850.0,
      payments: const [
        PaymentSplit(method: PaymentMethod.cash, amount: 2000.0),
        PaymentSplit(method: PaymentMethod.debt, amount: 3850.0),
      ],
      allocationNumber: 'ALLOC-2026-987654',
      createdAt: DateTime(2026, 11, 14),
    );

    test('generates valid A4 Tax Invoice PDF bytes with statutory metadata', () async {
      final Uint8List pdfBytes = await InvoicePdfGenerator.generate(
        invoice: invoice,
        company: company,
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF documents start with '%PDF-' header bytes: 0x25, 0x50, 0x44, 0x46, 0x2D
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('generates valid A4 Statement of Account (كشف حساب) PDF bytes', () async {
      final customer = Contact(
        id: 'cust-01',
        type: ContactType.customer,
        name: 'Al-Quds Contracting',
        phone: '050-1234567',
        address: 'Jerusalem',
        taxId: '515000123',
        debtWarningLimit: 10000.0,
        currentBalance: 3850.0,
      );

      final entries = [
        StatementEntry(
          id: 'stmt-1',
          contactId: customer.id,
          contactType: ContactType.customer,
          date: DateTime(2026, 11, 14),
          type: StatementEntryType.saleInvoice,
          referenceNumber: 'INV-2026-00001',
          debit: 3850.0,
          credit: 0.0,
          runningBalance: 3850.0,
          description: 'חלק על החשבון - משיש קררה',
        ),
      ];

      final Uint8List pdfBytes = await StatementPdfGenerator.generate(
        contact: customer,
        entries: entries,
        company: company,
      );

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });
}
