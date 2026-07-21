import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/app.dart';
import 'package:house_for_you/core/router/app_router.dart';
import 'package:house_for_you/core/widgets/property_card.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  setUp(() {
    // Repart de l'onglet initial avant chaque test — `appRouter` est un
    // singleton partagé entre les tests de ce fichier.
    appRouter.go('/discover');
  });

  testWidgets('affiche les 4 onglets et démarre sur Découvrir', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(const HouseForYouApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Découvrir'), findsWidgets);
      expect(find.text('Rechercher'), findsOneWidget);
      expect(find.text('Favoris'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });
  });

  testWidgets('taper sur un onglet affiche son contenu', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(const HouseForYouApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();

      expect(
        find.text('Retrouve ici les biens que tu auras sauvegardés.'),
        findsOneWidget,
      );
    });
  });

  /// Verrouille le comportement attendu du Sprint 2.5 (section 15) : chaque
  /// séquence de navigation doit ramener un contenu et un indicateur d'onglet
  /// sélectionné cohérents, sans jamais nécessiter de retour arrière.
  group('séquences de navigation Sprint 2.5', () {
    testWidgets('Découvrir -> Favoris -> Découvrir', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const HouseForYouApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Favoris'));
        await tester.pumpAndSettle();
        expect(
          find.text('Retrouve ici les biens que tu auras sauvegardés.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2,
        );

        await tester.tap(find.text('Découvrir'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('discover-feed')), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
      });
    });

    testWidgets('Découvrir -> Profil -> Découvrir', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const HouseForYouApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
        expect(
          find.text('Gère ton compte et tes préférences depuis cet onglet.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Découvrir'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('discover-feed')), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
      });
    });

    testWidgets('Favoris -> Profil -> Découvrir', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const HouseForYouApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Favoris'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Découvrir'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discover-feed')), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          0,
        );
      });
    });

    testWidgets(
      'plusieurs changements rapides d\'onglets restent cohérents',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(const HouseForYouApp());
          await tester.pumpAndSettle();

          Finder destination(String label) => find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              );

          for (final label in [
            'Favoris',
            'Rechercher',
            'Profil',
            'Découvrir',
            'Favoris',
            'Découvrir',
          ]) {
            await tester.tap(destination(label));
            await tester.pump();
          }
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('discover-feed')), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            0,
          );
        });
      },
    );

    testWidgets(
      'revenir sur Découvrir affiche le même bien et le feed reste interactif',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(const HouseForYouApp());
          await tester.pumpAndSettle();

          // Avance d'un bien avant de changer d'onglet.
          await tester.drag(
            find.byKey(const Key('discover-feed')),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          final propertyIdBefore = tester
              .widgetList<PropertyCard>(find.byType(PropertyCard))
              .first
              .property
              .id;

          await tester.tap(find.text('Favoris'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Découvrir'));
          await tester.pumpAndSettle();

          final propertyIdAfter = tester
              .widgetList<PropertyCard>(find.byType(PropertyCard))
              .first
              .property
              .id;
          expect(propertyIdAfter, propertyIdBefore);

          // Le swipe vertical doit rester fonctionnel sans avoir besoin d'un
          // retour arrière.
          await tester.drag(
            find.byKey(const Key('discover-feed')),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      },
    );

    testWidgets(
      'les filtres actifs sont conservés après un changement d\'onglet',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(const HouseForYouApp());
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.tune_rounded));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Louer'));
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining('Afficher'));
          await tester.pumpAndSettle();

          Finder destination(String label) => find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              );

          await tester.tap(destination('Favoris'));
          await tester.pumpAndSettle();
          await tester.tap(destination('Découvrir'));
          await tester.pumpAndSettle();

          expect(find.textContaining('Louer'), findsWidgets);
        });
      },
    );
  });
}
