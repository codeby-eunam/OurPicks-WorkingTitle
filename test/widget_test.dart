import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ourpicks/app.dart';

void main() {
  testWidgets('App boots to the home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OurPicksApp()));
    await tester.pumpAndSettle();

    expect(find.text('당맷치'), findsWidgets);
  });
}
