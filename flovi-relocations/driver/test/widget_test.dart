import 'package:flutter_test/flutter_test.dart';

import 'package:driver/main.dart';

void main() {
  testWidgets('DriverApp shows the Driver App placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DriverApp());

    expect(find.text('Driver App'), findsWidgets);
  });
}
