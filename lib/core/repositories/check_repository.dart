import '../../features/checks/domain/models/check_record.dart';

abstract class CheckRepository {
  Stream<List<CheckRecord>> watchChecks();
  Future<List<CheckRecord>> getChecks();
  Future<CheckRecord?> getCheckById(String id);
  Future<void> saveCheck(CheckRecord check);
  Future<void> updateCheckStatus(
    String id,
    CheckStatus status, {
    DateTime? date,
    String? note,
  });
}
