import 'package:sales_logistics_system/features/accounts/domain/models/contact.dart';
import 'package:sales_logistics_system/features/accounts/domain/models/statement_entry.dart';
import 'package:sales_logistics_system/core/repositories/contact_repository.dart';
import 'package:sales_logistics_system/core/repositories/check_repository.dart';
import '../models/check_record.dart';

class CheckLifecycleOrchestrator {
  final CheckRepository checkRepository;
  final ContactRepository contactRepository;

  const CheckLifecycleOrchestrator({
    required this.checkRepository,
    required this.contactRepository,
  });

  /// Transitions a check to bounced status and reinstates the debt on the customer/party ledger.
  Future<void> processCheckBounce({
    required String checkId,
    required Contact party,
    String? reason,
  }) async {
    final check = await checkRepository.getCheckById(checkId);
    if (check == null) {
      throw ArgumentError('Check with id $checkId not found');
    }

    // 1. Guard against duplicate bouncing and party mismatch
    if (check.status == CheckStatus.bounced) {
      throw StateError('Check $checkId is already marked as bounced');
    }
    if (check.partyId != party.id) {
      throw ArgumentError('Party ID mismatch: expected ${check.partyId}, got ${party.id}');
    }

    // 2. Advance check status to bounced
    await checkRepository.updateCheckStatus(
      checkId,
      CheckStatus.bounced,
      note: reason ?? 'Bounced check (ללא כיסוי)',
    );

    // 3. Re-apply debt to the debtor's balance using fresh record
    final freshParty = await contactRepository.getContactById(party.id);
    if (freshParty == null) {
      throw StateError('Party ${party.id} not found in repository');
    }

    final bouncedAmount = check.amount;
    final newBalance = freshParty.currentBalance + bouncedAmount;

    await contactRepository.updateBalance(
      contactId: party.id,
      balanceDelta: bouncedAmount,
    );

    // 4. Post a debit entry on the statement of account ledger
    final statement = StatementEntry(
      id: 'stmt-bounce-$checkId',
      contactId: party.id,
      contactType: party.type,
      date: DateTime.now(),
      type: StatementEntryType.checkBounced,
      referenceNumber: check.checkNumber,
      debit: bouncedAmount,
      credit: 0.0,
      runningBalance: newBalance,
      description: 'شيك راجع / שיק חוזר #${check.checkNumber} (${check.bankName})',
    );
    await contactRepository.addStatementEntry(statement);
  }
}
