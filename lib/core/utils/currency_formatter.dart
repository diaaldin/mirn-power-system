import 'package:intl/intl.dart';

final NumberFormat _shekelNumberFormat = NumberFormat('#,##0.00', 'en_US');

String formatCurrency(num amount) {
  final absValue = _shekelNumberFormat.format(amount.abs());
  if (amount < 0) {
    return '-₪$absValue';
  }
  return '₪$absValue';
}
