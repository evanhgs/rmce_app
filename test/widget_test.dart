// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:rmce_app/app/app.dart';

void main() {
  testWidgets('shell affiche la navigation principale', (WidgetTester tester) async {
    await tester.pumpWidget(const RmceApp());

    expect(find.text('Chrono'), findsWidgets);
    expect(find.text('Parcours'), findsOneWidget);
    expect(find.text('Amis'), findsOneWidget);
    expect(find.text('Classements'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
