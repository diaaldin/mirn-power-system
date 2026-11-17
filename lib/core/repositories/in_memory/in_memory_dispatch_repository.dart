import 'dart:async';
import '../../../features/logistics/domain/models/dispatch.dart';
import '../dispatch_repository.dart';

class InMemoryDispatchRepository implements DispatchRepository {
  final Map<String, Dispatch> _dispatches = {};
  late final StreamController<List<Dispatch>> _controller;

  InMemoryDispatchRepository({List<Dispatch>? initialDispatches}) {
    if (initialDispatches != null) {
      for (final d in initialDispatches) {
        _dispatches[d.id] = d;
      }
    }
    _controller = StreamController<List<Dispatch>>.broadcast(
      onListen: () => _controller.add(_currentList),
    );
  }

  List<Dispatch> get _currentList => List.unmodifiable(_dispatches.values);

  @override
  Stream<List<Dispatch>> watchDispatches() => _controller.stream;

  @override
  Future<List<Dispatch>> getDispatches() async => _currentList;

  @override
  Future<Dispatch?> getDispatchById(String id) async => _dispatches[id];

  @override
  Future<void> saveDispatch(Dispatch dispatch) async {
    _dispatches[dispatch.id] = dispatch;
    _controller.add(_currentList);
  }

  @override
  Future<void> updateDispatchStatus(
    String id,
    DispatchStatus status, {
    String? notes,
  }) async {
    final existing = _dispatches[id];
    if (existing == null) {
      throw ArgumentError('Dispatch with id $id not found');
    }
    final updated = existing.copyWith(
      status: status,
      notes: notes ?? existing.notes,
      updatedAt: DateTime.now(),
    );
    _dispatches[id] = updated;
    _controller.add(_currentList);
  }

  void dispose() {
    _controller.close();
  }
}
