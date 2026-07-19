import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/core/widgets/floating_search_bar.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:house_for_you/features/discover/discover_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

/// Même tri que `MockPropertyDataSource.getFeed()` (nouveauté d'abord) —
/// recalculé ici pour ne jamais dépendre d'un id de bien précis.
List<String> get _feedOrder {
  final published = mockProperties.where((p) => p.isPublished).toList()
    ..sort(
      (a, b) => (b.publishedAt ?? b.createdAt).compareTo(
        a.publishedAt ?? a.createdAt,
      ),
    );
  return published.map((p) => p.id).toList();
}

void main() {
  testWidgets('le swipe vertical fait défiler vers le bien suivant', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final order = _feedOrder;
      final first = order[0];
      final second = order[1];

      await tester.pumpWidget(_wrap(const DiscoverScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey(first)), findsOneWidget);
      expect(find.byKey(ValueKey(second)), findsNothing);

      // Distance < 1 page (viewport de test 600px de haut) pour n'avancer
      // que d'un seul bien, tout en dépassant le seuil de snap (50%).
      await tester.drag(
        find.byKey(const Key('discover-feed')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byKey(ValueKey(second))),
        offsetMoreOrLessEquals(Offset.zero, epsilon: 1),
      );
    });
  });

  testWidgets(
    'le swipe horizontal change de photo sans changer de bien ni de page',
    (tester) async {
      await mockNetworkImagesFor(() async {
        final first = _feedOrder[0];
        final firstPhotoKey = ValueKey('media-$first-media-0');
        final secondPhotoKey = ValueKey('media-$first-media-1');

        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        // 1re photo du 1er bien visible, page verticale au repos.
        expect(find.byKey(firstPhotoKey), findsOneWidget);
        final verticalPositionBefore = tester.getTopLeft(
          find.byKey(ValueKey(first)),
        );

        // Distance < 1 page (viewport de test 800px de large) pour ne
        // changer qu'une seule photo.
        await tester.drag(find.byKey(ValueKey(first)), const Offset(-500, 0));
        await tester.pumpAndSettle();

        // La 2e photo du même bien devient visible...
        expect(
          tester.getTopLeft(find.byKey(secondPhotoKey)),
          offsetMoreOrLessEquals(Offset.zero, epsilon: 1),
        );
        // ...et le bien affiché (page verticale) n'a pas bougé.
        expect(find.byKey(ValueKey(first)), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(ValueKey(first))),
          offsetMoreOrLessEquals(verticalPositionBefore, epsilon: 1),
        );
      });
    },
  );

  testWidgets('favori et partage sont affichés sur la carte visible', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(_wrap(const DiscoverScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });
  });

  testWidgets(
    'la barre de recherche se masque en avançant et réapparaît en reculant',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_wrap(const DiscoverScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingSearchBar), findsOneWidget);
        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);

        // Une page pile (viewport de test 600px de haut) : la barre doit
        // finir totalement masquée, pas seulement atténuée.
        await tester.drag(
          find.byKey(const Key('discover-feed')),
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();

        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.0);

        await tester.drag(
          find.byKey(const Key('discover-feed')),
          const Offset(0, 600),
        );
        await tester.pumpAndSettle();

        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);
      });
    },
  );

  testWidgets('le bouton filtres affiche un message', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(_wrap(const DiscoverScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filtres'));
      await tester.pump();

      expect(find.text('Filtres bientôt disponibles.'), findsOneWidget);
    });
  });

  testWidgets('les recherches enregistrées s\'ouvrent depuis la barre', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(_wrap(const DiscoverScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Recherches enregistrées'));
      await tester.pumpAndSettle();

      expect(find.text('Recherches enregistrées'), findsOneWidget);
      expect(find.text('Maison à Mons'), findsOneWidget);
      expect(find.text('Appartement à Bruxelles'), findsOneWidget);
      expect(find.text('Villa à Namur'), findsOneWidget);
    });
  });
}
