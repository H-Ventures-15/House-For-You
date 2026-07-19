import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/features/setup_check/setup_check_screen.dart';

void main() {
  testWidgets('SetupCheckScreen affiche les compteurs mock une fois chargés', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SetupCheckScreen())),
    );

    // Premier frame : chargement.
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.textContaining('biens fictifs chargés'), findsOneWidget);
    expect(find.textContaining('agences fictives chargées'), findsOneWidget);
    expect(find.text('Le setup fonctionne correctement.'), findsOneWidget);
  });
}
