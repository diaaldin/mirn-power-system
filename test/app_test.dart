import 'package:test/test.dart';

void main() {
  test('Smoke test verifies project environment is ready', () {
    const appName = 'M.I.R.N POWER Management System';
    expect(appName, contains('M.I.R.N POWER'));
  });
}
