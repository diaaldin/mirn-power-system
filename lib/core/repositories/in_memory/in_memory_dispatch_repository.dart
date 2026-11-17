import 'dart:async';
import '../../../features/logistics/domain/models/dispatch.dart';
import '../dispatch_repository.dart';

class InMemoryDispatchRepository implements DispatchRepository {
  final Map<String, Dispatch> _dispatches = {};
  final StreamController<List<Dispatch>> _controller = StreamController<List<Dispatch>>.broadcast();

  InMemoryDispatchRepository({List<Dispatch>? initialDispatches}) {
    if (initialDispatches != null) {
      for (final d in initialDispatches) {
        _dispatches[d.id] = d;
      }
    }
  }

  List<Dispatch> get _currentList => List.unmodifiable(_dispatches.values);

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_currentList);
    }
  }

  @override
  Stream<List<Dispatch>> watchDispatches() {
    late StreamController<List<Dispatch>> subCtrl;
    StreamSubscription<List<Dispatch>>? subscription;
    subCtrl = StreamController<List<Dispatch>>.broadcast(
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
  Future<List<Dispatch>> getDispatches() async => _currentList;

  @override
  Future<Dispatch?> getDispatchById(String id) async => _dispatches[id];

  @override
  Future<void> saveDispatch(Dispatch dispatch) async {
    _dispatches[dispatch.id] = dispatch;
    _notify();
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
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
