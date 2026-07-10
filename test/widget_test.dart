import 'package:flutter_test/flutter_test.dart';
import 'package:ketta/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KettaApp());
    expect(find.text('ቀጥታ'), findsOneWidget);
  });
}
