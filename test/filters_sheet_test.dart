import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/features/discover/discover_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

/// La feuille de filtres est un `ListView` : comme tout `Sliver`, seuls les
/// enfants dans la fenêtre visible (+ cache extent) sont réellement montés,
/// même avec des enfants passés en liste plutôt qu'un `.builder` — un
/// `find.text` sur une section basse échoue tant qu'on ne l'a pas fait
/// défiler en vue. Ce helper fait défiler la feuille par petits pas jusqu'à
/// ce que la cible apparaisse.
Future<void> _scrollUntilFound(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    if (target.evaluate().isNotEmpty) break;
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
  }
  expect(target, findsWidgets);
  // Un widget peut exister dans l'arbre (cache extent du Sliver) sans être
  // réellement visible/cliquable à l'écran — `ensureVisible` termine le
  // défilement nécessaire pour qu'il le soit vraiment.
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

/// Couvre la hiérarchie des filtres (Sprint 2.4) : critères principaux
/// toujours visibles, critères avancés repliés sous "Plus de filtres",
/// enregistrement d'une recherche, incompatibilité budget/transaction,
/// état "zéro résultat".
void main() {
  testWidgets(
    'Plus de filtres est replié par défaut et révèle les critères avancés '
    'au tap',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Filtres'));
        await tester.pumpAndSettle();

        // Critères principaux immédiatement visibles, sans défiler.
        expect(find.text('Localisation'), findsOneWidget);
        expect(find.text('Type de transaction'), findsOneWidget);

        // Critères avancés absents du tout tant que la section n'est pas
        // dépliée (branche conditionnelle, pas seulement masquée).
        expect(find.text('Salles de bain'), findsNothing);
        expect(find.text('Certificat énergétique (PEB)'), findsNothing);
        expect(find.text('Ambiance de vie'), findsNothing);

        await _scrollUntilFound(tester, find.text('Type de bien'));
        expect(find.text('Type de bien'), findsOneWidget);

        await _scrollUntilFound(tester, find.text('Chambres'));
        expect(find.text('Chambres'), findsOneWidget);

        await _scrollUntilFound(tester, find.text('Plus de filtres'));
        await tester.tap(find.text('Plus de filtres'));
        await tester.pumpAndSettle();

        await _scrollUntilFound(tester, find.text('Salles de bain'));
        expect(find.text('Salles de bain'), findsOneWidget);

        await _scrollUntilFound(
          tester,
          find.text('Certificat énergétique (PEB)'),
        );
        expect(find.text('Certificat énergétique (PEB)'), findsOneWidget);

        await _scrollUntilFound(tester, find.text('Ambiance de vie'));
        expect(find.text('Ambiance de vie'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'enregistrer la recherche courante ouvre un dialogue prérempli et '
    'confirme visuellement',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Filtres'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Louer'));
        await tester.pump();

        await _scrollUntilFound(
          tester,
          find.text('Enregistrer cette recherche'),
        );
        await tester.tap(find.text('Enregistrer cette recherche'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        final dialogField = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        expect(
          tester.widget<TextField>(dialogField).controller!.text,
          isNotEmpty,
        );

        await tester.enterText(dialogField, 'Ma recherche test');
        await tester.tap(find.widgetWithText(TextButton, 'Enregistrer'));
        await tester.pumpAndSettle();

        // Confirmation visuelle (SnackBar) et apparition dans l'aperçu.
        expect(find.textContaining('Ma recherche test'), findsWidgets);
      });
    },
  );

  testWidgets(
    'changer le type de transaction réinitialise un budget déjà choisi '
    '(échelles achat/location incompatibles)',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Filtres'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Acheter'));
        await tester.pump();

        final maxField = find.widgetWithText(TextField, '1000k €');
        await _scrollUntilFound(tester, maxField);
        await tester.enterText(maxField, '500000');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('500k €'), findsOneWidget);

        // Le Type de transaction a défilé hors de la fenêtre montée du
        // Sliver pendant qu'on renseignait le budget — revenir en haut de
        // la feuille pour pouvoir taper "Louer".
        for (var attempt = 0;
            attempt < 10 && find.text('Louer').evaluate().isEmpty;
            attempt++) {
          await tester.drag(find.byType(ListView), const Offset(0, 250));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Louer'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Louer'));
        await tester.pump();

        // L'ancien budget "vente" (500k €) ne doit jamais survivre au
        // passage à l'échelle "location" (max 3000 €).
        expect(find.text('500k €'), findsNothing);
        expect(find.text('3000 €'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'zéro résultat après filtrage affiche les trois actions de secours',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Filtres'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('filters-location-field')),
          'Ville totalement inexistante zzz',
        );
        await tester.pump();

        await tester.tap(find.byTooltip('Fermer'));
        await tester.pumpAndSettle();

        expect(
          find.text('Aucun bien ne correspond à ces filtres.'),
          findsOneWidget,
        );
        expect(find.text('Modifier les filtres'), findsOneWidget);
        expect(find.text('Charger une recherche sauvegardée'), findsOneWidget);
        expect(find.text('Réinitialiser les filtres'), findsOneWidget);
      });
    },
  );
}
