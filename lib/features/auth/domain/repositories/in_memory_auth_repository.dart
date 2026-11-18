import 'dart:async';
import '../models/app_user.dart';
import 'auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  final Map<String, AppUser> _users = {};
  AppUser? _currentUser;
  final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();

  InMemoryAuthRepository({List<AppUser>? initialUsers, AppUser? initialUser}) {
    final defaultUsers = initialUsers ??
        [
          AppUser(
            id: 'usr-admin',
            name: 'ضياء الدين / דיאאלדין',
            email: 'admin@mirnpower.com',
            role: UserRole.admin,
            pinCode: '1234',
            createdAt: DateTime(2026, 1, 1),
            lastLoginAt: DateTime.now(),
          ),
          AppUser(
            id: 'usr-acc',
            name: 'أحمد النتشة / אחמד נתשה',
            email: 'accounting@mirnpower.com',
            role: UserRole.accountant,
            pinCode: '2222',
            createdAt: DateTime(2026, 1, 1),
          ),
          AppUser(
            id: 'usr-cashier',
            name: 'سامح الجعبري / סאמח ג\'עברי',
            email: 'pos@mirnpower.com',
            role: UserRole.cashier,
            pinCode: '3333',
            createdAt: DateTime(2026, 1, 1),
          ),
          AppUser(
            id: 'usr-disp',
            name: 'خليل بركات / חליל ברכאת',
            email: 'fleet@mirnpower.com',
            role: UserRole.dispatcher,
            pinCode: '4444',
            createdAt: DateTime(2026, 1, 1),
          ),
        ];

    for (final u in defaultUsers) {
      _users[u.id] = u;
    }
    _currentUser = initialUser ?? _users['usr-admin'];
  }

  @override
  AppUser? get currentUser => _currentUser;

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(_currentUser);
    }
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    late StreamController<AppUser?> subCtrl;
    StreamSubscription<AppUser?>? subscription;
    subCtrl = StreamController<AppUser?>.broadcast(
      onListen: () {
        subCtrl.add(_currentUser);
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
  Future<AppUser> signInWithEmailPassword(String email, String password) async {
    final user = _users.values.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw ArgumentError('User with email $email not found'),
    );
    if (!user.isActive) {
      throw StateError('User account is deactivated');
    }
    _currentUser = user.copyWith(lastLoginAt: DateTime.now());
    _users[user.id] = _currentUser!;
    _notify();
    return _currentUser!;
  }

  @override
  Future<AppUser> signInWithPin(String pin) async {
    final user = _users.values.firstWhere(
      (u) => u.pinCode == pin.trim(),
      orElse: () => throw ArgumentError('Invalid PIN code'),
    );
    if (!user.isActive) {
      throw StateError('User account is deactivated');
    }
    _currentUser = user.copyWith(lastLoginAt: DateTime.now());
    _users[user.id] = _currentUser!;
    _notify();
    return _currentUser!;
  }

  @override
  Future<void> switchUser(String userId) async {
    final user = _users[userId];
    if (user == null) {
      throw ArgumentError('User with id $userId not found');
    }
    _currentUser = user.copyWith(lastLoginAt: DateTime.now());
    _users[userId] = _currentUser!;
    _notify();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _notify();
  }

  @override
  Future<List<AppUser>> getAllUsers() async => List.unmodifiable(_users.values);

  @override
  Future<void> saveUser(AppUser user) async {
    _users[user.id] = user;
    if (_currentUser?.id == user.id) {
      _currentUser = user;
      _notify();
    }
  }

  void dispose() {
    _controller.close();
  }
}
