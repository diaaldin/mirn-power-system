import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/logistics/domain/models/dispatch.dart';
import '../utils/currency_formatter.dart';
import 'invoice_pdf_generator.dart'; // for CompanyInfo

/// Israeli Standard A4 Delivery Note / Transport Voucher PDF Generator.
/// Follows M.I.R.N POWER luxury styling with dual Hebrew/Arabic typography.
class DeliveryNotePdfGenerator {
  DeliveryNotePdfGenerator._();

  static const PdfColor _goldColor = PdfColor.fromInt(0xFFC5A059);
  static const PdfColor _darkSlate = PdfColor.fromInt(0xFF1E1E24);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F7);

  static Future<Uint8List> generate({
    required Dispatch dispatch,
    required CompanyInfo company,
    double? deliveryFee, // optional ILS amount; if null shows 'N/A'
    pw.Font? baseFont,
    pw.Font? boldFont,
  }) async {
    final docTheme = pw.ThemeData.withFont(
      base: baseFont ?? pw.Font.helvetica(),
      bold: boldFont ?? pw.Font.helveticaBold(),
    );

    final pdf = pw.Document(theme: docTheme);

    const String docTitle = 'תעודת משלוח והובלה / سند إرسالية ونقل';

    final String dateFormatted =
        '${dispatch.date.year}-${dispatch.date.month.toString().padLeft(2, '0')}-${dispatch.date.day.toString().padLeft(2, '0')}';

    final hebrewName = company.nameHebrew ?? company.name;
    final arabicName = company.nameArabic ?? company.name;

    final invoiceRef = dispatch.invoiceNumber ?? 'N/A';
    final deliveryFeeText =
        deliveryFee != null ? formatCurrency(deliveryFee) : 'N/A';

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
                          dispatch.dispatchNumber,
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

              // 2. Customer & Delivery Block
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
                    // Left: Customer Info
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'לקוח / عميل',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          dispatch.customerName,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'טלפון / هاتف: ${dispatch.customerPhone}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    // Right: Delivery Address
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'כתובת למשלוח / عنوان التسليم',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          dispatch.deliveryAddress,
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

              // 3. Cargo Description Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: _darkSlate),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['תיאור המטען / وصف البضاعة'],
                data: [
                  [dispatch.cargoDescription],
                ],
              ),
              pw.SizedBox(height: 12),

              // 4. Transport Details Row
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: _lightGrey,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'רכב / مركبة',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${dispatch.vehicleName} (${dispatch.plateNumber})',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'נהג / سائق',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _goldColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          dispatch.driverName,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 5. Linked Documents
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'אסמכתא חשבונית / مرجع الفاتورة:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      invoiceRef,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _goldColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 6. Financial Summary
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 230,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _goldColor, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: _lightGrey,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'דמי הובלה / رسوم النقل:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        deliveryFeeText,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // 7. Signature Block — 3 columns
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Driver signature + stamp
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
                        'חתימת הנהג וחותמת / توقيع السائق والختم',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // Customer / Recipient signature
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
                        'חתימת הלקוח / המקבל / توقيع العميل / المستلم',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // Company stamp
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

              // 8. Footer
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
