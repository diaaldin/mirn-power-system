import '../../../accounts/domain/models/contact.dart';
import '../../../accounts/domain/models/statement_entry.dart';
import '../models/check_record.dart';

class InvalidStateTransitionException implements Exception {
  final CheckStatus from;
  final CheckStatus to;

  InvalidStateTransitionException(this.from, this.to);

  @override
  String toString() {
    return 'InvalidStateTransitionException: Cannot transition check from ${from.name} to ${to.name}';
  }
}

class InvalidCheckEndorsementException implements Exception {
  @override
  String toString() {
    return 'InvalidCheckEndorsementException: Endorsing a check requires a valid target partyId (endorsedToPartyId)';
  }
}

class CheckTransitionResult {
  final CheckRecord updatedCheck;
  final Contact? updatedContact;
  final StatementEntry? statementEntry;

  const CheckTransitionResult({
    required this.updatedCheck,
    this.updatedContact,
    this.statementEntry,
  });
}

class CheckStateMachine {
  CheckStateMachine._();

  static const Map<CheckStatus, List<CheckStatus>> _allowedTransitions = {
    CheckStatus.pending: [
      CheckStatus.deposited,
      CheckStatus.bounced,
      CheckStatus.returned,
      CheckStatus.endorsed,
    ],
    CheckStatus.deposited: [
      CheckStatus.cleared,
      CheckStatus.bounced,
    ],
    CheckStatus.bounced: [
      CheckStatus.deposited,
      CheckStatus.returned,
    ],
    CheckStatus.endorsed: [
      CheckStatus.bounced,
    ],
    CheckStatus.cleared: [],
    CheckStatus.returned: [],
  };

  /// Transitions a check record to `targetStatus`, enforcing validity, recording history,
  /// and atomically restoring customer debt in case of check bounce.
  static CheckTransitionResult transition({
    required CheckRecord check,
    required CheckStatus targetStatus,
    String? notes,
    String? changedBy,
    String? endorsedToPartyId,
    Contact? contact,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final allowed = _allowedTransitions[check.status] ?? [];

    if (!allowed.contains(targetStatus)) {
      throw InvalidStateTransitionException(check.status, targetStatus);
    }

    if (targetStatus == CheckStatus.endorsed) {
      if (endorsedToPartyId == null || endorsedToPartyId.trim().isEmpty) {
        throw InvalidCheckEndorsementException();
      }
    }

    final newHistory = List<CheckHistoryEntry>.from(check.history)
      ..add(
        CheckHistoryEntry(
          status: targetStatus,
          changedAt: now,
          notes: notes,
          changedBy: changedBy,
        ),
      );

    final updatedCheck = check.copyWith(
      status: targetStatus,
      endorsedToPartyId: targetStatus == CheckStatus.endorsed
          ? endorsedToPartyId
          : check.endorsedToPartyId,
      history: newHistory,
    );

    Contact? updatedContact;
    StatementEntry? statementEntry;

    // Bounce protection: When a received customer check bounces, restore customer debt
    if (targetStatus == CheckStatus.bounced &&
        check.type == CheckType.received &&
        contact != null) {
      final double newBalance =
          ((contact.currentBalance + check.amount) * 100).roundToDouble() / 100.0;

      updatedContact = contact.copyWith(
        currentBalance: newBalance,
        updatedAt: now,
      );

      statementEntry = StatementEntry(
        id: 'stmt-chk-bounce-${check.id}',
        contactId: contact.id,
        contactType: ContactType.customer,
        date: now,
        type: StatementEntryType.checkBounced,
        referenceNumber: 'CHK-${check.checkNumber}',
        debit: check.amount,
        credit: 0.0,
        runningBalance: newBalance,
        description: 'שיק שחזר מספר ${check.checkNumber} (${notes ?? 'ללא כיסוי'})',
      );
    }

    return CheckTransitionResult(
      updatedCheck: updatedCheck,
      updatedContact: updatedContact,
      statementEntry: statementEntry,
    );
  }
}
