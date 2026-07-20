import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/data/models/saved_search.dart';
import 'package:house_for_you/data/models/search_filters.dart';
import 'package:house_for_you/data/providers/repository_providers.dart';
import 'package:house_for_you/data/repositories/saved_searches_repository.dart';
import 'package:house_for_you/features/discover/discover_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

/// Un repository vide pour tester l'état "aucune recherche enregistrée"
/// sans dépendre de la suppression successive des 4 recherches de démo.
class _EmptySavedSearchesRepository implements SavedSearchesRepository {
  @override
  Future<List<SavedSearch>> getAll(String userId) async => const [];

  @override
  Future<SavedSearch> save(
    String userId,
    String label,
    SearchFilters filters,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> rename(String userId, String searchId, String newLabel) async {
    throw UnimplementedError();
  }

  @override
  Future<void> remove(String userId, String searchId) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets(
    'charger une recherche enregistrée applique ses critères et ferme le '
    'panneau',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Recherches enregistrées'));
        await tester.pumpAndSettle();

        // Deuxième élément de la liste (correspond à un bien mock réel,
        // contrairement à "Maison à Mons" — voir le test dédié à l'état
        // zéro résultat plus bas) : garanti visible sans avoir à faire
        // défiler la feuille (`DraggableScrollableSheet` à 55% de hauteur).
        expect(find.text('Appartement à Bruxelles'), findsOneWidget);
        await tester.tap(find.text('Appartement à Bruxelles'));
        await tester.pumpAndSettle();

        // Le panneau se ferme...
        expect(find.text('Recherches enregistrées'), findsNothing);
        // ...et le résumé de la barre flottante reflète les critères
        // chargés (ville Bruxelles).
        expect(find.textContaining('Bruxelles'), findsOneWidget);
      });
    },
  );

  testWidgets('renommer une recherche depuis le panneau rapide', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(_wrap(const DiscoverScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Recherches enregistrées'));
      await tester.pumpAndSettle();

      expect(find.text('Villa à Namur'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Renommer « Villa à Namur »'));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(dialogField).controller!.text,
        'Villa à Namur',
      );

      await tester.enterText(dialogField, 'Villa avec piscine à Namur');
      await tester.tap(find.widgetWithText(TextButton, 'Renommer'));
      await tester.pumpAndSettle();

      expect(find.text('Villa avec piscine à Namur'), findsOneWidget);
      expect(find.text('Villa à Namur'), findsNothing);
    });
    handle.dispose();
  });

  testWidgets(
    'supprimer une recherche la retire de la liste et affiche une '
    'confirmation',
    (tester) async {
      final handle = tester.ensureSemantics();
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Recherches enregistrées'));
        await tester.pumpAndSettle();

        // Deuxième élément de la liste : garanti visible sans avoir à
        // faire défiler la feuille.
        expect(find.text('Appartement à Bruxelles'), findsOneWidget);

        await tester.tap(
          find.bySemanticsLabel('Supprimer « Appartement à Bruxelles »'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Supprimer cette recherche ?'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
        await tester.pumpAndSettle();

        expect(find.text('Appartement à Bruxelles'), findsNothing);
        expect(find.textContaining('supprimée.'), findsOneWidget);
      });
      handle.dispose();
    },
  );

  testWidgets(
    'charger une recherche sauvegardée sans résultat affiche l\'état '
    'zéro résultat avec ses trois actions',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Recherches enregistrées'));
        await tester.pumpAndSettle();

        // "Maison à Mons" ne correspond volontairement à aucun bien mock
        // (voir MockSavedSearchesDataSource) — sert de démonstration prête
        // à l'emploi de l'état "zéro résultat".
        await tester.tap(find.text('Maison à Mons'));
        await tester.pumpAndSettle();

        expect(
          find.text('Aucun bien ne correspond à ces filtres.'),
          findsOneWidget,
        );
        expect(find.text('Charger une recherche sauvegardée'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'aucune recherche enregistrée affiche un état vide explicite',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              savedSearchesRepositoryProvider.overrideWithValue(
                _EmptySavedSearchesRepository(),
              ),
            ],
            child: const MaterialApp(home: DiscoverScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Recherches enregistrées'));
        await tester.pumpAndSettle();

        expect(
          find.text('Aucune recherche enregistrée pour l\'instant.'),
          findsOneWidget,
        );
      });
    },
  );
}
