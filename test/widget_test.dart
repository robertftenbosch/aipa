import 'package:flutter_test/flutter_test.dart';

import 'package:aipa/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const AipaApp());
    expect(find.text('AIPA'), findsOneWidget);
  });
}
