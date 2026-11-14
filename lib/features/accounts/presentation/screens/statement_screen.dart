import 'dart:typed_data';
import '../../../../core/pdf/invoice_pdf_generator.dart';
import '../../../../core/pdf/statement_pdf_generator.dart';
import '../../domain/models/contact.dart';
import '../../domain/models/statement_entry.dart';

class StatementTotals {
  final double totalDebits;
  final double totalCredits;
  final double closingBalance;

  const StatementTotals({
    required this.totalDebits,
    required this.totalCredits,
    required this.closingBalance,
  });
}

class StatementScreenController {
  final Contact contact;
  final List<StatementEntry> _allEntries;
  DateTime? _fromDate;
  DateTime? _toDate;

  StatementScreenController({
    required this.contact,
    required List<StatementEntry> allEntries,
  }) : _allEntries = List.of(allEntries);

  void setDateFilter({DateTime? fromDate, DateTime? toDate}) {
    _fromDate = fromDate;
    _toDate = toDate;
  }

  void clearFilter() {
    _fromDate = null;
    _toDate = null;
  }

  List<StatementEntry> getFilteredEntries() {
    return _allEntries.where((entry) {
      if (_fromDate != null && entry.date.isBefore(_fromDate!)) {
        return false;
      }
      if (_toDate != null && entry.date.isAfter(_toDate!)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  StatementTotals getTotals() {
    final filtered = getFilteredEntries();
    double debits = 0.0;
    double credits = 0.0;

    for (final e in filtered) {
      debits += e.debit;
      credits += e.credit;
    }

    debits = (debits * 100).roundToDouble() / 100.0;
    credits = (credits * 100).roundToDouble() / 100.0;

    final double closing = filtered.isNotEmpty
        ? filtered.last.runningBalance
        : contact.currentBalance;

    return StatementTotals(
      totalDebits: debits,
      totalCredits: credits,
      closingBalance: closing,
    );
  }

  Future<Uint8List> exportPdf({required CompanyInfo company}) {
    final filtered = getFilteredEntries();
    return StatementPdfGenerator.generate(
      contact: contact,
      entries: filtered,
      company: company,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }
}
