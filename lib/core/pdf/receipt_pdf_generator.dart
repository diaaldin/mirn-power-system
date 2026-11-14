import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/accounts/domain/models/contact.dart';
import '../../features/receipts/domain/models/payment_receipt.dart';
import '../../features/sales/domain/models/payment_split.dart';
import '../utils/currency_formatter.dart';
import 'invoice_pdf_generator.dart';

/// Israeli Standard A4 Payment Receipt & Supplier Payment Voucher PDF Generator.
class ReceiptPdfGenerator {
  ReceiptPdfGenerator._();

  static const PdfColor _goldColor = PdfColor.fromInt(0xFFC5A059);
  static const PdfColor _darkSlate = PdfColor.fromInt(0xFF1E1E24);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F7);

  static Future<Uint8List> generate({
    required PaymentReceipt receipt,
    required Contact contact,
    required CompanyInfo company,
    required double previousBalance,
    required double newBalance,
    pw.Font? baseFont,
    pw.Font? boldFont,
  }) async {
    final docTheme = pw.ThemeData.withFont(
      base: baseFont ?? pw.Font.helvetica(),
      bold: boldFont ?? pw.Font.helveticaBold(),
    );

    final pdf = pw.Document(theme: docTheme);

    final String docTitle = receipt.isCustomerReceipt
        ? 'קבלה / سند قبض'
        : 'אישור תשלום לספק / سند صرف';

    final String partyTitle = receipt.isCustomerReceipt
        ? 'פרטי לקוח / بيانات العميل'
        : 'פרטי ספק / بيانات المورد';

    final String dateFormatted =
        '${receipt.date.year}-${receipt.date.month.toString().padLeft(2, '0')}-${receipt.date.day.toString().padLeft(2, '0')}';

    final hebrewName = company.nameHebrew ?? company.name;
    final arabicName = company.nameArabic ?? company.name;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Company Header
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
                    // Metadata box
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          receipt.receiptNumber,
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'תאריך / التاريخ: $dateFormatted',
                          style: const pw.TextStyle(fontSize: 9),
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

              // 3. Party Information Section
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
                      partyTitle,
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
                          'שם / الاسم: ${contact.name}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'ח.פ. / ת.ז: ${contact.taxId.isNotEmpty ? contact.taxId : '-'}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'טלפון / هاتف: ${contact.phone.isNotEmpty ? contact.phone : '-'}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'כתובת / عنوان: ${contact.address.isNotEmpty ? contact.address : '-'}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // 4. Total Amount Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  border: pw.Border.all(color: _goldColor, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      receipt.isCustomerReceipt
                          ? 'סה"כ שולם בקבלה / المبلغ المقبوض:'
                          : 'סה"כ שולם בשובר / المبلغ المصروف:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkSlate,
                      ),
                    ),
                    pw.Text(
                      formatCurrency(receipt.totalAmount),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _goldColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 5. Payment Breakdown Table
              pw.Text(
                'פירוט תקבולים / تفاصيل الدفع:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _darkSlate,
                ),
              ),
              pw.SizedBox(height: 4),
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
                  'אמצעי תשלום / وسيلة الدفع',
                  'פרטים / אסמכתא',
                  'סכום / المبلغ',
                ],
                data: receipt.payments.map((item) {
                  return [
                    _formatMethod(item.method),
                    _formatDetails(item),
                    formatCurrency(item.amount),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 12),

              // 6. Account Ledger Reconciliation Box
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _goldColor, width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: _lightGrey,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'התאמת יתרות כרטסת / تسوية رصيد الحساب:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _darkSlate,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'יתרה קודמת / الرصيد السابق:',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          formatCurrency(previousBalance),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'שולם בקבלה / المدفوع بالسند:',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          formatCurrency(receipt.totalAmount),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Divider(color: _goldColor, thickness: 0.5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'יתרה מעודכנת / الرصيد الجديد:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          formatCurrency(newBalance),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (receipt.notes != null && receipt.notes!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: _lightGrey,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'הערות / ملاحظات: ${receipt.notes!}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                  ),
                ),
              ],

              pw.Spacer(),

              // 7. Footer / Signature block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
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
                        child: pw.SizedBox(height: 30),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'חתימת קופאי / توقيع المستلم',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 90,
                    height: 50,
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

              // Statutory note
              pw.Center(
                child: pw.Text(
                  'מסמך ממוחשב - הופק באמצעות מערכת M.I.R.N POWER',
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

  static String _formatMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'מזומן / نقد';
      case PaymentMethod.check:
        return 'שיק / شيك';
      case PaymentMethod.bankTransfer:
        return 'העברה בנקאית / تحويل بنكي';
      case PaymentMethod.debt:
        return 'על החשבון (חוב) / ذمة';
    }
  }

  static String _formatDetails(ReceiptPaymentItem item) {
    final parts = <String>[];
    if (item.checkNumber != null && item.checkNumber!.trim().isNotEmpty) {
      parts.add('שיק מס: ${item.checkNumber}');
    }
    if (item.bankName != null && item.bankName!.trim().isNotEmpty) {
      parts.add('בנק: ${item.bankName}');
    }
    if (item.branchNumber != null && item.branchNumber!.trim().isNotEmpty) {
      parts.add('סניף: ${item.branchNumber}');
    }
    if (item.accountNumber != null && item.accountNumber!.trim().isNotEmpty) {
      parts.add('חשבון: ${item.accountNumber}');
    }
    if (item.dueDate != null) {
      final d = item.dueDate!;
      parts.add(
        'זמן פירעון: ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      );
    }
    if (item.drawerName != null && item.drawerName!.trim().isNotEmpty) {
      parts.add('מושך: ${item.drawerName}');
    }
    if (item.reference != null && item.reference!.trim().isNotEmpty) {
      parts.add('אסמכתא: ${item.reference}');
    }
    return parts.isEmpty ? '-' : parts.join(' | ');
  }
}
