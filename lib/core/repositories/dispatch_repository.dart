import '../../features/logistics/domain/models/dispatch.dart';

abstract class DispatchRepository {
  Stream<List<Dispatch>> watchDispatches();
  Future<List<Dispatch>> getDispatches();
  Future<Dispatch?> getDispatchById(String id);
  Future<void> saveDispatch(Dispatch dispatch);
  Future<void> updateDispatchStatus(
    String id,
    DispatchStatus status, {
    int? completionOdometer,
    String? cancelReason,
  });
}
