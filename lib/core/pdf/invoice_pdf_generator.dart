import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/sales/domain/models/sale_invoice.dart';
import '../utils/currency_formatter.dart';

class CompanyInfo {
  final String name;
  final String subtitleHebrew;
  final String subtitleArabic;
  final String taxId;
  final String phone;
  final String address;

  const CompanyInfo({
    required this.name,
    required this.subtitleHebrew,
    required this.subtitleArabic,
    required this.taxId,
    required this.phone,
    required this.address,
  });
}

class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  static Future<Uint8List> generate({
    required SaleInvoice invoice,
    required CompanyInfo company,
  }) async {
    final pdf = pw.Document();

    final goldColor = PdfColor.fromHex('#C5A059');
    final darkColor = PdfColor.fromHex('#1E1E24');
    final lightGrey = PdfColor.fromHex('#F5F5F7');

    final String docTitle = invoice.isPaidInFull
        ? 'חשבונית מס קבלה / فاتورة ضريبية وسند قبض'
        : 'חשבונית מס / فاتورة ضريبية';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: goldColor, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          company.name,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${company.subtitleHebrew} | ${company.subtitleArabic}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'עוסק מורשה / ח.פ.: ${company.taxId} | טלפון: ${company.phone}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'כתובת: ${company.address}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                        pw.Text(
                          'תאריך: ${invoice.date.year}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.day.toString().padLeft(2, '0')}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        if (invoice.allocationNumber != null &&
                            invoice.allocationNumber!.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: lightGrey,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: goldColor, width: 0.5),
                            ),
                            child: pw.Text(
                              'מספר הקצאה רשות המיסים: ${invoice.allocationNumber}',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Title Header
              pw.Center(
                child: pw.Text(
                  docTitle,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Customer Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('שם הלקוח: ${invoice.customerName}'),
                    if (invoice.customerTaxId.isNotEmpty)
                      pw.Text('ח.פ. / ת.ז.: ${invoice.customerTaxId}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Items Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: lightGrey),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['תיאור פריט / تفاصيل', 'יחידה / وحدة', 'כמות', 'מחיר יח\'', 'סה\"כ'],
                data: invoice.items.map((item) {
                  return [
                    item.productName,
                    item.unitType.hebrewLabel,
                    item.quantity.toString(),
                    formatCurrency(item.unitPrice),
                    formatCurrency(item.subtotal),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),

              // Totals Summary
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: goldColor, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('סה\"כ לפני מע\"מ:', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(formatCurrency(invoice.subtotal),
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('מע\"מ (${(invoice.vatRate * 100).toInt()}%):',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(formatCurrency(invoice.vatAmount),
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Divider(color: goldColor, thickness: 0.5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('סה\"כ לתשלום:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text(formatCurrency(invoice.totalAmount),
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: goldColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // Payment Breakdown Table
              pw.Text('פירוט תקבולים / تفاصيل الدفعات:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: pw.BoxDecoration(color: lightGrey),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headers: ['אמצעי תשלום / وسيلة الدفع', 'אסמכתא / مرجع', 'סכום'],
                data: invoice.payments.map((p) {
                  return [
                    p.method.hebrewLabel,
                    p.reference ?? '-',
                    formatCurrency(p.amount),
                  ];
                }).toList(),
              ),

              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'M.I.R.N POWER - תודה על קנייתכם! | شكراً لتعاملكم معنا!',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
