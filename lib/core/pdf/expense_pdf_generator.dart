import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/expenses/domain/models/expense.dart';
import '../../features/fleet/domain/models/driver.dart';
import '../../features/fleet/domain/models/vehicle.dart';
import '../utils/currency_formatter.dart';
import 'invoice_pdf_generator.dart'; // for CompanyInfo

/// Israeli Standard A4 Expense Voucher / Payment Out Generator.
/// Follows M.I.R.N POWER luxury styling with dual Hebrew/Arabic typography.
class ExpensePdfGenerator {
  ExpensePdfGenerator._();

  static const PdfColor _goldColor = PdfColor.fromInt(0xFFC5A059);
  static const PdfColor _darkSlate = PdfColor.fromInt(0xFF1E1E24);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F7);

  static Future<Uint8List> generate({
    required Expense expense,
    required CompanyInfo company,
    Vehicle? vehicle,
    Driver? driver,
    pw.Font? baseFont,
    pw.Font? boldFont,
  }) async {
    final docTheme = pw.ThemeData.withFont(
      base: baseFont ?? pw.Font.helvetica(),
      bold: boldFont ?? pw.Font.helveticaBold(),
    );

    final pdf = pw.Document(theme: docTheme);

    const String docTitle = 'שובר תשלום והוצאה / سند صرف ومصروفات';

    final String dateFormatted =
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';

    final hebrewName = company.nameHebrew ?? company.name;
    final arabicName = company.nameArabic ?? company.name;

    final hasAttribution =
        vehicle != null || driver != null || expense.odometerReading != null;

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
                        if (company.subtitleHebrew != null &&
                            company.subtitleHebrew!.isNotEmpty)
                          pw.Text(
                            company.subtitleHebrew!,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (company.subtitleArabic != null &&
                            company.subtitleArabic!.isNotEmpty)
                          pw.Text(
                            company.subtitleArabic!,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        pw.SizedBox(height: 3),
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
                    // Document Metadata
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          docTitle,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _darkSlate,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          expense.expenseNumber,
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'תאריך / التاريخ: $dateFormatted',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 2. Metadata & Payment Method Block (2-column card)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Payment Method & Reference
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'אמצעי תשלום / طريقة الدفع',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${expense.paymentMethod.hebrewLabel} / ${expense.paymentMethod.arabicLabel}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'אסמכתא / مرجع',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          expense.reference ?? 'N/A',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    // Right: Created by & Category
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'נוצר ע"י / أنشئ بواسطة',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          expense.createdBy ?? 'N/A',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'קטגוריה / تصنيف',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${expense.category.hebrewLabel} / ${expense.category.arabicLabel}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 3. Vehicle & Driver Attribution Block (if vehicle or driver tagged)
              if (hasAttribution) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: _lightGrey,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Tagged Vehicle
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'רכב ושיוך צי / مركبة وأسطول',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _goldColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            vehicle != null
                                ? '${vehicle.name} (${vehicle.plateNumber})'
                                : 'N/A',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'מד אוץ / قراءة العداد: ${expense.odometerReading != null ? '${expense.odometerReading} كم' : 'N/A'}',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      // Tagged Driver
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'נהג משויך / سائق مرتبط',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _goldColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            driver != null ? driver.fullName : 'N/A',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          if (driver != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'טלפון / هاتف: ${driver.phone} | רשיון / رخصة: ${driver.licenseNumber}',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // 4. Expense Breakdown Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: _darkSlate),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: [
                  'קטגוריה / تصنيف',
                  'תיאור ההוצאה / بيان المصروف',
                  'סכום לתשלום / المبلغ',
                ],
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                },
                headerAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(4.5),
                  2: const pw.FlexColumnWidth(2),
                },
                data: [
                  [
                    '${expense.category.hebrewLabel} / ${expense.category.arabicLabel}',
                    expense.description,
                    formatCurrency(expense.amount),
                  ],
                ],
              ),
              pw.SizedBox(height: 12),

              // 5. Grand Total Box
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 230,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _goldColor, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: _lightGrey,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'סה"כ לתשלום / المبلغ الإجمالي:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _darkSlate,
                        ),
                      ),
                      pw.Text(
                        formatCurrency(expense.amount),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // 6. Dual Signature Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Column 1: Authorized Signatory (+ Company Stamp)
                  pw.Row(
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
                            child: pw.SizedBox(height: 25),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'חתימת מורשה חתימה / توقيع المفوض بالتوقيع',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        width: 80,
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
                  // Column 2: Payee / Driver Signature
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 160,
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
                        'חתימת המקבל / توقيع المستلم',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // 7. Footer
              pw.Center(
                child: pw.Text(
                  'M.I.R.N POWER MANAGEMENT SYSTEM',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: _goldColor,
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
}
