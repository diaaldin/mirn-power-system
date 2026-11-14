import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/accounts/domain/models/contact.dart';
import '../../features/inventory/domain/models/product.dart';
import '../../features/purchases/domain/models/purchase_invoice.dart';
import '../utils/currency_formatter.dart';
import 'invoice_pdf_generator.dart';

/// Israeli Standard A4 Purchase Intake / Voucher PDF Generator.
/// Follows M.I.R.N POWER luxury styling with dual Hebrew/Arabic typography.
class PurchasePdfGenerator {
  PurchasePdfGenerator._();

  static const PdfColor _goldColor = PdfColor.fromInt(0xFFC5A059);
  static const PdfColor _darkSlate = PdfColor.fromInt(0xFF1E1E24);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F7);

  static Future<Uint8List> generate({
    required PurchaseInvoice invoice,
    required CompanyInfo company,
    Contact? supplier,
    pw.Font? baseFont,
    pw.Font? boldFont,
  }) async {
    final docTheme = pw.ThemeData.withFont(
      base: baseFont ?? pw.Font.helvetica(),
      bold: boldFont ?? pw.Font.helveticaBold(),
    );

    final pdf = pw.Document(theme: docTheme);

    const String docTitle = 'חשבונית רכש וקליטת מלאי / فاتورة مشتريات وتوريد مخزون';
    final String dateFormatted =
        '${invoice.date.year}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.day.toString().padLeft(2, '0')}';

    final hebrewName = company.nameHebrew ?? company.name;
    final arabicName = company.nameArabic ?? company.name;

    final suppName = supplier?.name ?? invoice.supplierName;
    final suppTaxId = supplier != null && supplier.taxId.isNotEmpty
        ? supplier.taxId
        : (invoice.supplierTaxId.isNotEmpty ? invoice.supplierTaxId : '-');
    final suppPhone =
        supplier != null && supplier.phone.isNotEmpty ? supplier.phone : '-';
    final suppAddress =
        supplier != null && supplier.address.isNotEmpty ? supplier.address : '-';

    final supplierInvoiceRef =
        (invoice.supplierInvoiceNumber != null &&
                invoice.supplierInvoiceNumber!.trim().isNotEmpty)
            ? invoice.supplierInvoiceNumber!.trim()
            : 'N/A';

    final createdByKeeper =
        invoice.createdBy.trim().isNotEmpty ? invoice.createdBy.trim() : 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _goldColor, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Company Info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          hebrewName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: _darkSlate,
                          ),
                        ),
                        if (arabicName.isNotEmpty && arabicName != hebrewName)
                          pw.Text(
                            arabicName,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkSlate,
                            ),
                          ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${company.subtitleHebrew} | ${company.subtitleArabic}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'ח.פ. / ע.מ: ${company.taxId}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'טלפון: ${company.phone} | כתובת: ${company.address}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    // Metadata Box
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'אסמכתא / חשבונית ספק: $supplierInvoiceRef',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _darkSlate,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'תאריך / التاريخ: $dateFormatted',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'מחסנאי / קולט מלאי: $createdByKeeper',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // 2. Document Title Bar
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  docTitle,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkSlate,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // 3. Supplier Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'פרטי ספק / بيانات المورد',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _goldColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'שם הספק / اسم المورد: $suppName',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'ח.פ. / עוסק מורשה: $suppTaxId',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'טלפון / هاتف: $suppPhone',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'כתובת / عنوان: $suppAddress',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 4. Itemized Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: _darkSlate,
                ),
                headerDecoration: const pw.BoxDecoration(color: _lightGrey),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  'תיאור פריט / تفاصيل',
                  'יחידה / وحدة',
                  'כמות / الكمية',
                  'תוספת מלאי בפועל / الإضافة',
                  'מחיר יח\' (לפני מע"מ)',
                  'סה"כ / המجموع',
                ],
                data: invoice.items.map((item) {
                  return [
                    item.productName,
                    '${item.unitType.hebrewLabel} / ${item.unitType.arabicLabel}',
                    item.quantity.toString(),
                    formatConvertedStock(item),
                    formatCurrency(item.unitCost),
                    formatCurrency(item.subtotal),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),

              // 5. Financial Summary Box
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _goldColor, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: _lightGrey,
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'סה"כ לפני מע"מ / المجموع:',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            formatCurrency(invoice.subtotal),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'מע"מ (${(invoice.vatRate * 100).toInt()}%):',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            formatCurrency(invoice.vatAmount),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                      pw.Divider(color: _goldColor, thickness: 0.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'סה"כ לתשלום / الإجمالي:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            formatCurrency(invoice.totalAmount),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _goldColor,
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'שולם במעמד הקליטה / المدفوع:',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            formatCurrency(invoice.paidAmount),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'על החשבון (חוב לספק) / ذمة:',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            formatCurrency(invoice.onAccountAmount),
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Notes Section
              if (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: _lightGrey,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'הערות / ملاحظات: ${invoice.notes!}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                  ),
                ),
              ],

              pw.Spacer(),

              // 7. Dual Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Warehouse Receiver Signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 140,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey500,
                              width: 1,
                            ),
                          ),
                        ),
                        child: pw.SizedBox(height: 25),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'חתימת מקבל המלאי / توقيع مستلم البضاعة',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // Supplier / Driver Signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 140,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey500,
                              width: 1,
                            ),
                          ),
                        ),
                        child: pw.SizedBox(height: 25),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'חתימת הספק או הנהג / توقيع المورد أو السائق',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // Company Stamp Box
                  pw.Container(
                    width: 90,
                    height: 45,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.8,
                        style: pw.BorderStyle.dashed,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'חותמת העסק\nختم الشركة',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Statutory Footer
              pw.Center(
                child: pw.Text(
                  'מסמך ממוחשב - הופק באמצעות מערכת M.I.R.N POWER | תעודת קליטת מלאי ורכש',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Formats the converted stock addition quantity based on unit type.
  /// Box units convert to square meters (מ"ר).
  /// Meter units display in square meters (מ"ר).
  /// Piece units display in pieces (יח').
  static String formatConvertedStock(PurchaseLineItem item) {
    switch (item.unitType) {
      case UnitType.box:
        return '${item.convertedStockQuantity.toStringAsFixed(2)} מ"ר';
      case UnitType.meter:
        return '${item.convertedStockQuantity.toStringAsFixed(2)} מ"ר';
      case UnitType.piece:
        final isWhole = item.convertedStockQuantity % 1 == 0;
        final qtyStr = isWhole
            ? item.convertedStockQuantity.toInt().toString()
            : item.convertedStockQuantity.toStringAsFixed(2);
        return '$qtyStr יח\'';
    }
  }
}
