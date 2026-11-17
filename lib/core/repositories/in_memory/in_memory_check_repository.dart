import 'dart:async';
import '../../../features/checks/domain/models/check_record.dart';
import '../check_repository.dart';

class InMemoryCheckRepository implements CheckRepository {
  final Map<String, CheckRecord> _checks = {};
  final StreamController<List<CheckRecord>> _controller = StreamController<List<CheckRecord>>.broadcast();

  InMemoryCheckRepository({List<CheckRecord>? initialChecks}) {
    if (initialChecks != null) {
      for (final c in initialChecks) {
        _checks[c.id] = c;
      }
    }
  }

  List<CheckRecord> get _currentList => List.unmodifiable(_checks.values);

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_currentList);
    }
  }

  @override
  Stream<List<CheckRecord>> watchChecks() {
    late StreamController<List<CheckRecord>> subCtrl;
    StreamSubscription<List<CheckRecord>>? subscription;
    subCtrl = StreamController<List<CheckRecord>>.broadcast(
      onListen: () {
        subCtrl.add(_currentList);
        subscription = _controller.stream.listen(
          (data) {
            if (!subCtrl.isClosed) subCtrl.add(data);
          },
          onError: subCtrl.addError,
          onDone: subCtrl.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return subCtrl.stream;
  }

  @override
  Future<List<CheckRecord>> getChecks() async => _currentList;

  @override
  Future<CheckRecord?> getCheckById(String id) async => _checks[id];

  @override
  Future<void> saveCheck(CheckRecord check) async {
    _checks[check.id] = check;
    _notify();
  }

  @override
  Future<void> updateCheckStatus(
    String id,
    CheckStatus status, {
    DateTime? date,
    String? note,
  }) async {
    final existing = _checks[id];
    if (existing == null) {
      throw ArgumentError('Check with id $id not found');
    }
    final historyEntry = CheckHistoryEntry(
      status: status,
      changedAt: date ?? DateTime.now(),
      notes: note,
    );
    final updated = existing.copyWith(
      status: status,
      history: [...existing.history, historyEntry],
    );
    _checks[id] = updated;
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
