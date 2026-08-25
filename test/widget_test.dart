import 'package:flutter_test/flutter_test.dart';
import 'package:aivlm_ic/main.dart';

void main() {
  testWidgets('AIVLM-I&C app starts successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
  });
}