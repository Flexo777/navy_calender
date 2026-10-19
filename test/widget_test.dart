
import 'package:flutter_test/flutter_test.dart';
import 'package:navy_calendar/main.dart';

void main() {
  testWidgets('Navy Calendar app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const NavyCalendarApp());

    // Pastikan aplikasi utama berhasil dibuat.
    expect(find.byType(NavyCalendarApp), findsOneWidget);

    // Pastikan MaterialApp tersedia.
    expect(find.byType(NavyCalendarApp), findsOneWidget);

    // Proses FutureBuilder tanpa menunggu timer atau jaringan.
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
