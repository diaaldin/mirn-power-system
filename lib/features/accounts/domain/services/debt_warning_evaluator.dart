import '../../../../core/utils/currency_formatter.dart';
import '../models/contact.dart';

class DebtWarningResult {
  final bool isExceeded;
  final double totalProjectedDebt;
  final double exceededAmount;
  final bool canProceed;
  final String? warningMessage;

  const DebtWarningResult({
    required this.isExceeded,
    required this.totalProjectedDebt,
    required this.exceededAmount,
    this.canProceed = true,
    this.warningMessage,
  });
}

class DebtWarningEvaluator {
  DebtWarningEvaluator._();

  /// Evaluates whether adding `additionalDebt` to `contact` exceeds their `debtWarningLimit`.
  ///
  /// CRITICAL ANTI-GOAL: `canProceed` is ALWAYS true.
  /// The system issues a soft warning prompt to staff without blocking the sale.
  static DebtWarningResult evaluate({
    required Contact contact,
    required num additionalDebt,
  }) {
    final double add = additionalDebt.toDouble();
    final double totalProjected = ((contact.currentBalance + add) * 100).roundToDouble() / 100.0;

    // A limit of 0 or negative indicates no limit configured
    if (contact.debtWarningLimit <= 0) {
      return DebtWarningResult(
        isExceeded: false,
        totalProjectedDebt: totalProjected,
        exceededAmount: 0.0,
        canProceed: true,
      );
    }

    if (totalProjected > contact.debtWarningLimit) {
      final double exceeded = ((totalProjected - contact.debtWarningLimit) * 100).roundToDouble() / 100.0;
      final currentFormatted = formatCurrency(contact.currentBalance);
      final limitFormatted = formatCurrency(contact.debtWarningLimit);
      final exceededFormatted = formatCurrency(exceeded);

      return DebtWarningResult(
        isExceeded: true,
        totalProjectedDebt: totalProjected,
        exceededAmount: exceeded,
        canProceed: true, // Soft warning, never hard-blocks!
        warningMessage:
            'تنبيه سقف المديونية: رصيد العميل الحالي ($currentFormatted) مع العملية يتجاوز السقف ($limitFormatted) بمقدار $exceededFormatted.\nהתראת תקרת חוב: יתרת הלקוח הנוכחית חורגת מהתקרה ב-$exceededFormatted.',
      );
    }

    return DebtWarningResult(
      isExceeded: false,
      totalProjectedDebt: totalProjected,
      exceededAmount: 0.0,
      canProceed: true,
    );
  }
}
