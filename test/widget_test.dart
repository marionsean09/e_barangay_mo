import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_barangay_mo/auth/login_page.dart';

void main() {
  testWidgets('Login page shows the app name and login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('E-Barangay Mo'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
