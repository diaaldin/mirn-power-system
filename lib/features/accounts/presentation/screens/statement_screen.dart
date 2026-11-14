import 'dart:typed_data';
import '../../../../core/pdf/invoice_pdf_generator.dart';
import '../../../../core/pdf/statement_pdf_generator.dart';
import '../../domain/models/contact.dart';
import '../../domain/models/statement_entry.dart';

class StatementTotals {
  final double openingBalance;
  final double totalDebits;
  final double totalCredits;
  final double closingBalance;

  const StatementTotals({
    this.openingBalance = 0.0,
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
    if (toDate != null) {
      // Adjust to end of the day to include transactions with time components
      _toDate = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);
    } else {
      _toDate = null;
    }
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
    double opening = 0.0;
    if (_fromDate != null) {
      final priorEntries = _allEntries.where((e) => e.date.isBefore(_fromDate!)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (priorEntries.isNotEmpty) {
        opening = priorEntries.last.runningBalance;
      }
    }

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
        : (opening > 0 ? opening : contact.currentBalance);

    return StatementTotals(
      openingBalance: opening,
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
