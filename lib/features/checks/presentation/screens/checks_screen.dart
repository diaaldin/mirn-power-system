import '../../../../features/accounts/domain/models/contact.dart';
import '../../domain/models/check_record.dart';
import '../../domain/services/check_state_machine.dart';

class ChecksScreenController {
  final Map<String, CheckRecord> _checksMap = {};
  CheckStatus? _statusFilter;

  ChecksScreenController({required List<CheckRecord> initialChecks}) {
    for (final c in initialChecks) {
      _checksMap[c.id] = c;
    }
  }

  void setStatusFilter(CheckStatus? status) {
    _statusFilter = status;
  }

  CheckRecord? getCheckById(String checkId) => _checksMap[checkId];

  List<CheckRecord> get filteredChecks {
    final list = _checksMap.values.toList();
    if (_statusFilter == null) return list;
    return list.where((c) => c.status == _statusFilter).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  double get totalPendingAmount {
    return _checksMap.values
        .where((c) => c.status == CheckStatus.pending)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  double get totalDepositedAmount {
    return _checksMap.values
        .where((c) => c.status == CheckStatus.deposited)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  CheckTransitionResult depositCheck({
    required String checkId,
    String? notes,
    String? changedBy,
  }) {
    final check = _checksMap[checkId];
    if (check == null) throw ArgumentError('Check not found: $checkId');

    final result = CheckStateMachine.transition(
      check: check,
      targetStatus: CheckStatus.deposited,
      notes: notes,
      changedBy: changedBy,
    );

    _checksMap[checkId] = result.updatedCheck;
    return result;
  }

  CheckTransitionResult clearCheck({
    required String checkId,
    String? notes,
    String? changedBy,
  }) {
    final check = _checksMap[checkId];
    if (check == null) throw ArgumentError('Check not found: $checkId');

    final result = CheckStateMachine.transition(
      check: check,
      targetStatus: CheckStatus.cleared,
      notes: notes,
      changedBy: changedBy,
    );

    _checksMap[checkId] = result.updatedCheck;
    return result;
  }

  CheckTransitionResult bounceCheck({
    required String checkId,
    String? notes,
    String? changedBy,
    Contact? contact,
  }) {
    final check = _checksMap[checkId];
    if (check == null) throw ArgumentError('Check not found: $checkId');

    final result = CheckStateMachine.transition(
      check: check,
      targetStatus: CheckStatus.bounced,
      notes: notes,
      changedBy: changedBy,
      contact: contact,
    );

    _checksMap[checkId] = result.updatedCheck;
    return result;
  }

  CheckTransitionResult endorseCheck({
    required String checkId,
    required String endorsedToPartyId,
    String? notes,
    String? changedBy,
  }) {
    final check = _checksMap[checkId];
    if (check == null) throw ArgumentError('Check not found: $checkId');

    final result = CheckStateMachine.transition(
      check: check,
      targetStatus: CheckStatus.endorsed,
      endorsedToPartyId: endorsedToPartyId,
      notes: notes,
      changedBy: changedBy,
    );

    _checksMap[checkId] = result.updatedCheck;
    return result;
  }
}
