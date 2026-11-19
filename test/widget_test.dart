// This is a basic Flutter widget test for Hanap Gawa app.

import 'package:flutter_test/flutter_test.dart';
import 'package:hanapgawaapk/main.dart';

void main() {
  testWidgets('Hanap Gawa app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HanapGawaApp());

    // Verify that Hanap Gawa app title or logo text renders.
    expect(find.textContaining('HANAP'), findsOneWidget);
    expect(find.textContaining('GAWA'), findsWidgets);
  });
}
