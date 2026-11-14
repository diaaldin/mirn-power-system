import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/test.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/purchase_pdf_generator.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/inventory/domain/models/product.dart';
import 'package:sales_logistics_system/features/purchases/domain/models/purchase_invoice.dart';

void main() {
  group('PurchasePdfGenerator Tests', () {
    const company = CompanyInfo(
      name: 'M.I.R.N POWER Ltd.',
      nameArabic: 'شركة م.ي.ר.ن باور م.ض',
      nameHebrew: 'מ.י.ר.ן פאוור בע"מ',
      subtitleArabic: 'أדوات صحية، رخام، حجر، ونقل وشحن',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      taxId: '515892104',
      phone: '02-1234567',
      address: 'אזור התעשייה עטרות / عطروت, ירושלים',
    );

    const supplierContact = Contact(
      id: 'supp-201',
      type: ContactType.supplier,
      name: 'מחצבות ירושלים ושיש בע"מ / محاجر القدس للرخام',
      phone: '02-9876543',
      address: 'אזור תעשייה מישור אדומים',
      taxId: '514882109',
      debtWarningLimit: 100000.0,
      currentBalance: -15475.0,
    );

    test('generates valid A4 Purchase Intake PDF bytes with full supplier and external reference', () async {
      final invoice = PurchaseInvoice(
        id: 'pur-001',
        invoiceNumber: 'PUR-2026-00001',
        supplierInvoiceNumber: 'SUPP-INV-9921',
        date: DateTime(2026, 11, 14, 11, 0),
        supplierId: supplierContact.id,
        supplierName: supplierContact.name,
        supplierTaxId: supplierContact.taxId,
        items: [
          PurchaseLineItem(
            productId: 'prod-001',
            productName: 'שיש קררה איטלקי / رخام كرارا إيطالي',
            unitType: UnitType.box,
            quantity: 100,
            unitCost: 110.0,
            subtotal: 11000.0,
            convertedStockQuantity: 144.0,
          ),
          PurchaseLineItem(
            productId: 'prod-003',
            productName: 'אסלה תלויה גרואה / كرسي حمام معلق جروهي',
            unitType: UnitType.piece,
            quantity: 10,
            unitCost: 650.0,
            subtotal: 6500.0,
            convertedStockQuantity: 10.0,
          ),
        ],
        subtotal: 17500.0,
        vatRate: 0.17,
        vatAmount: 2975.0,
        totalAmount: 20475.0,
        paidAmount: 5000.0,
        onAccountAmount: 15475.0,
        notes: 'توريد دفعة رخام وأدوات صحية لمستودع قلنديا - فحص الجودة סלים',
        createdBy: 'מחסנאי ראשי אחמד / أمين المستودع أحمد',
        createdAt: DateTime(2026, 11, 14),
      );

      final Uint8List pdfBytes = await PurchasePdfGenerator.generate(
        invoice: invoice,
        company: company,
        supplier: supplierContact,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF magic number %PDF-
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });

    test('generates valid PDF when supplier contact is null and supplierInvoiceNumber is omitted', () async {
      final invoice = PurchaseInvoice(
        id: 'pur-002',
        invoiceNumber: 'PUR-2026-00002',
        supplierInvoiceNumber: null,
        date: DateTime(2026, 11, 14, 15, 30),
        supplierId: 'supp-999',
        supplierName: 'ספק כללי / مورد عام',
        supplierTaxId: '519999999',
        items: [
          PurchaseLineItem(
            productId: 'prod-010',
            productName: 'אבן ירושלמית טובזה / حجر قدسي طبزة',
            unitType: UnitType.meter,
            quantity: 45.5,
            unitCost: 80.0,
            subtotal: 3640.0,
            convertedStockQuantity: 45.5,
          ),
        ],
        subtotal: 3640.0,
        vatRate: 0.17,
        vatAmount: 618.8,
        totalAmount: 4258.8,
        paidAmount: 4258.8,
        onAccountAmount: 0.0,
        notes: null,
        createdBy: 'cashier-02',
        createdAt: DateTime(2026, 11, 14),
      );

      final Uint8List pdfBytes = await PurchasePdfGenerator.generate(
        invoice: invoice,
        company: company,
        supplier: null,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });

    test('generates valid PDF with custom fonts provided', () async {
      final invoice = PurchaseInvoice(
        id: 'pur-003',
        invoiceNumber: 'PUR-2026-00003',
        supplierInvoiceNumber: 'EXT-1234',
        date: DateTime(2026, 11, 14),
        supplierId: 'supp-001',
        supplierName: 'Supplier Direct',
        supplierTaxId: '511112222',
        items: [
          PurchaseLineItem(
            productId: 'prod-001',
            productName: 'Ceramic Floor Tiles 60x60',
            unitType: UnitType.box,
            quantity: 50,
            unitCost: 80.0,
            subtotal: 4000.0,
            convertedStockQuantity: 72.0,
          ),
        ],
        subtotal: 4000.0,
        vatRate: 0.17,
        vatAmount: 680.0,
        totalAmount: 4680.0,
        paidAmount: 0.0,
        onAccountAmount: 4680.0,
        notes: 'Full payment deferred to end of month credit account',
        createdBy: 'warehouse_mgr',
        createdAt: DateTime(2026, 11, 14),
      );

      final Uint8List pdfBytes = await PurchasePdfGenerator.generate(
        invoice: invoice,
        company: company,
        supplier: supplierContact,
        baseFont: pw.Font.courier(),
        boldFont: pw.Font.courierBold(),
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });

    test('formats stock conversion correctly across different unit types', () {
      final boxItem = PurchaseLineItem(
        productId: 'prod-001',
        productName: 'Tiles',
        unitType: UnitType.box,
        quantity: 100,
        unitCost: 50.0,
        subtotal: 5000.0,
        convertedStockQuantity: 144.0,
      );

      final meterItem = PurchaseLineItem(
        productId: 'prod-002',
        productName: 'Marble Slab',
        unitType: UnitType.meter,
        quantity: 50.25,
        unitCost: 120.0,
        subtotal: 6030.0,
        convertedStockQuantity: 50.25,
      );

      final pieceItem = PurchaseLineItem(
        productId: 'prod-003',
        productName: 'Sink',
        unitType: UnitType.piece,
        quantity: 10,
        unitCost: 300.0,
        subtotal: 3000.0,
        convertedStockQuantity: 10.0,
      );

      final pieceFractionItem = PurchaseLineItem(
        productId: 'prod-004',
        productName: 'Custom Cut Fixture',
        unitType: UnitType.piece,
        quantity: 5,
        unitCost: 150.0,
        subtotal: 750.0,
        convertedStockQuantity: 5.5,
      );

      expect(PurchasePdfGenerator.formatConvertedStock(boxItem), equals('144.00 מ"ר'));
      expect(PurchasePdfGenerator.formatConvertedStock(meterItem), equals('50.25 מ"ר'));
      expect(PurchasePdfGenerator.formatConvertedStock(pieceItem), equals('10 יח\''));
      expect(PurchasePdfGenerator.formatConvertedStock(pieceFractionItem), equals('5.50 יח\''));
    });
  });
}
