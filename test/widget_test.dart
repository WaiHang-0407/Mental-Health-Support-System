import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindly_admin/presentation/screens/home.dart';

void main() {
  testWidgets('renders admin home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('Admin Home'), findsOneWidget);
    expect(find.text('Moderation Queue'), findsOneWidget);
  });
}
