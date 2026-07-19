import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/app.dart';
import 'package:house_for_you/core/router/app_router.dart';

void main() {
  setUp(() {
    // Repart de l'onglet initial avant chaque test — `appRouter` est un
    // singleton partagé entre les tests de ce fichier.
    appRouter.go('/discover');
  });

  testWidgets('affiche les 4 onglets et démarre sur Découvrir', (
    tester,
  ) async {
    await tester.pumpWidget(const HouseForYouApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Découvrir'), findsWidgets);
    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('taper sur un onglet affiche son contenu', (tester) async {
    await tester.pumpWidget(const HouseForYouApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();

    expect(
      find.text('Retrouve ici les biens que tu auras sauvegardés.'),
      findsOneWidget,
    );
  });
}
