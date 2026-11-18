import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchCurrentUser();
  AppUser? get currentUser;
  Future<AppUser> signInWithEmailPassword(String email, String password);
  Future<AppUser> signInWithPin(String pin);
  Future<void> switchUser(String userId);
  Future<void> signOut();
  Future<List<AppUser>> getAllUsers();
  Future<void> saveUser(AppUser user);
}
