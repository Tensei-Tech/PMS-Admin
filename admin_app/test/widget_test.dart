import 'package:flutter_test/flutter_test.dart';
import 'package:pms_admin_console/screens/main_dashboard.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Main Dashboard renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainDashboard(),
      ),
    );

    expect(find.text('Welcome to Master Admin Console 🚀'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Officers Directory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
