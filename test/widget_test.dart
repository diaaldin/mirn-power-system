import 'package:flutter_test/flutter_test.dart';
import 'package:sales_logistics_system/main.dart';

void main() {
  testWidgets('App smoke test verifies header text renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MirnPowerApp());
    expect(find.text('M.I.R.N POWER Management System'), findsOneWidget);
  });
}
