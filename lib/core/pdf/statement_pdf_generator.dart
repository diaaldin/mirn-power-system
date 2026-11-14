import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/accounts/domain/models/contact.dart';
import '../../features/accounts/domain/models/statement_entry.dart';
import '../utils/currency_formatter.dart';
import 'invoice_pdf_generator.dart';

class StatementPdfGenerator {
  StatementPdfGenerator._();

  static Future<Uint8List> generate({
    required Contact contact,
    required List<StatementEntry> entries,
    required CompanyInfo company,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = pw.Document();

    final goldColor = PdfColor.fromHex('#C5A059');
    final darkColor = PdfColor.fromHex('#1E1E24');
    final lightGrey = PdfColor.fromHex('#F5F5F7');

    final double totalDebits = entries.fold(0.0, (sum, e) => sum + e.debit);
    final double totalCredits = entries.fold(0.0, (sum, e) => sum + e.credit);
    final double closingBalance = entries.isNotEmpty
        ? entries.last.runningBalance
        : contact.currentBalance;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Company Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: goldColor, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        company.name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      pw.Text(
                        '${company.subtitleHebrew} | ${company.subtitleArabic}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'כشف حساب / דף חשבון לקוח',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                      pw.Text(
                        'הופק בתאריך: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Contact Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('שם: ${contact.name}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text('טלפון: ${contact.phone.isNotEmpty ? contact.phone : '-'}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (contact.taxId.isNotEmpty)
                        pw.Text('ח.פ. / ע.מ.: ${contact.taxId}',
                            style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('כתובת: ${contact.address.isNotEmpty ? contact.address : '-'}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Entries Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: lightGrey),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headers: ['תאריך', 'סוג תנועה', 'אסמכתא', 'תיאור', 'חובה (+)', 'זכות (-)', 'יתרה'],
              data: entries.map((e) {
                return [
                  '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                  e.type.localizedName,
                  e.referenceNumber,
                  e.description,
                  e.debit > 0 ? formatCurrency(e.debit) : '-',
                  e.credit > 0 ? formatCurrency(e.credit) : '-',
                  formatCurrency(e.runningBalance),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 12),

            // Summary Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 240,
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
                        pw.Text('סה\"כ חיובי חובה (קניות):',
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(formatCurrency(totalDebits),
                            style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('סה\"כ זיכויים ותשלומים:',
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(formatCurrency(totalCredits),
                            style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Divider(color: goldColor, thickness: 0.5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('יתרה לתשלום (חוב נוכחי):',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          formatCurrency(closingBalance),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
