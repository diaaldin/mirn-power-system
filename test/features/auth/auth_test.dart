import 'package:test/test.dart';
import 'package:sales_logistics_system/features/auth/domain/models/app_user.dart';
import 'package:sales_logistics_system/features/auth/domain/repositories/in_memory_auth_repository.dart';

void main() {
  group('RBAC & Role Permissions Tests', () {
    test('admin user has unrestricted permissions across all modules', () {
      const admin = AppUser(
        id: 'u-admin',
        name: 'Diaaldin',
        email: 'admin@mirnpower.com',
        role: UserRole.admin,
      );

      expect(admin.canAccessPos, isTrue);
      expect(admin.canManageChecks, isTrue);
      expect(admin.canApproveCreditNotes, isTrue);
      expect(admin.canManageLedgers, isTrue);
      expect(admin.canManagePurchases, isTrue);
      expect(admin.canDispatchFleet, isTrue);
      expect(admin.canRecordExpenses, isTrue);
      expect(admin.canViewReports, isTrue);
      expect(admin.canAdministerUsers, isTrue);
    });

    test('accountant user has financial permissions but no fleet dispatch or user administration', () {
      const accountant = AppUser(
        id: 'u-acc',
        name: 'Ahmad',
        email: 'acc@mirnpower.com',
        role: UserRole.accountant,
      );

      expect(accountant.canAccessPos, isFalse);
      expect(accountant.canManageChecks, isTrue);
      expect(accountant.canApproveCreditNotes, isTrue);
      expect(accountant.canManageLedgers, isTrue);
      expect(accountant.canManagePurchases, isTrue);
      expect(accountant.canDispatchFleet, isFalse);
      expect(accountant.canRecordExpenses, isTrue);
      expect(accountant.canViewReports, isTrue);
      expect(accountant.canAdministerUsers, isFalse);
    });

    test('cashier user has POS counter access but cannot manage checks or approve credit notes', () {
      const cashier = AppUser(
        id: 'u-cashier',
        name: 'Sameh',
        email: 'cashier@mirnpower.com',
        role: UserRole.cashier,
      );

      expect(cashier.canAccessPos, isTrue);
      expect(cashier.canManageChecks, isFalse);
      expect(cashier.canApproveCreditNotes, isFalse);
      expect(cashier.canManageLedgers, isFalse);
      expect(cashier.canManagePurchases, isFalse);
      expect(cashier.canDispatchFleet, isFalse);
      expect(cashier.canRecordExpenses, isFalse);
      expect(cashier.canViewReports, isFalse);
      expect(cashier.canAdministerUsers, isFalse);
    });

    test('dispatcher user has fleet dispatch access and fuel expense entry but no finance controls', () {
      const dispatcher = AppUser(
        id: 'u-disp',
        name: 'Khalil',
        email: 'disp@mirnpower.com',
        role: UserRole.dispatcher,
      );

      expect(dispatcher.canAccessPos, isFalse);
      expect(dispatcher.canManageChecks, isFalse);
      expect(dispatcher.canApproveCreditNotes, isFalse);
      expect(dispatcher.canManageLedgers, isFalse);
      expect(dispatcher.canManagePurchases, isFalse);
      expect(dispatcher.canDispatchFleet, isTrue);
      expect(dispatcher.canRecordExpenses, isTrue);
      expect(dispatcher.canViewReports, isFalse);
      expect(dispatcher.canAdministerUsers, isFalse);
    });
  });

  group('InMemoryAuthRepository Tests', () {
    late InMemoryAuthRepository authRepo;

    setUp(() {
      authRepo = InMemoryAuthRepository();
    });

    tearDown(() {
      authRepo.dispose();
    });

    test('initializes with default admin user and provides user list', () async {
      expect(authRepo.currentUser, isNotNull);
      expect(authRepo.currentUser!.role, equals(UserRole.admin));

      final users = await authRepo.getAllUsers();
      expect(users.length, equals(4));
    });

    test('signInWithPin authenticates valid PIN and updates currentUser', () async {
      final user = await authRepo.signInWithPin('2222');
      expect(user.role, equals(UserRole.accountant));
      expect(authRepo.currentUser!.email, equals('accounting@mirnpower.com'));
    });

    test('signInWithPin rejects invalid PIN', () async {
      expect(
        () => authRepo.signInWithPin('9999'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Invalid PIN'))),
      );
    });

    test('signInWithEmailPassword authenticates valid email', () async {
      final user = await authRepo.signInWithEmailPassword('fleet@mirnpower.com', 'dummyPass');
      expect(user.role, equals(UserRole.dispatcher));
      expect(authRepo.currentUser!.id, equals('usr-disp'));
    });

    test('switchUser switches active session smoothly', () async {
      await authRepo.switchUser('usr-cashier');
      expect(authRepo.currentUser!.role, equals(UserRole.cashier));
    });

    test('watchCurrentUser stream emits updates on auth state changes', () async {
      final emittedUsers = <AppUser?>[];
      final sub = authRepo.watchCurrentUser().listen(emittedUsers.add);

      await authRepo.switchUser('usr-acc');
      await authRepo.signOut();

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(emittedUsers.length, greaterThanOrEqualTo(2));
      expect(emittedUsers.last, isNull);
    });
  });
}
