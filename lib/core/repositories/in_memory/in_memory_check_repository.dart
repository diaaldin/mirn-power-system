import 'dart:async';
import '../../../features/checks/domain/models/check_record.dart';
import '../check_repository.dart';

class InMemoryCheckRepository implements CheckRepository {
  final Map<String, CheckRecord> _checks = {};
  late final StreamController<List<CheckRecord>> _controller;

  InMemoryCheckRepository({List<CheckRecord>? initialChecks}) {
    if (initialChecks != null) {
      for (final c in initialChecks) {
        _checks[c.id] = c;
      }
    }
    _controller = StreamController<List<CheckRecord>>.broadcast(
      onListen: () => _controller.add(_currentList),
    );
  }

  List<CheckRecord> get _currentList => List.unmodifiable(_checks.values);

  @override
  Stream<List<CheckRecord>> watchChecks() => _controller.stream;

  @override
  Future<List<CheckRecord>> getChecks() async => _currentList;

  @override
  Future<CheckRecord?> getCheckById(String id) async => _checks[id];

  @override
  Future<void> saveCheck(CheckRecord check) async {
    _checks[check.id] = check;
    _controller.add(_currentList);
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
    _controller.add(_currentList);
  }

  void dispose() {
    _controller.close();
  }
}
