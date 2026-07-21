import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:house_for_you/features/discover/property_detail_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

void main() {
  // Les favoris sont désormais persistés localement (`SharedPreferences`) —
  // sans ce mock, le plugin n'a pas de backend dans l'environnement de test
  // (voir CONTRIBUTING.md, piège connu).
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('affiche les informations clés du bien', (tester) async {
    await mockNetworkImagesFor(() async {
      final property = mockProperties.firstWhere((p) => p.id == 'prop-1');

      await tester.pumpWidget(
        _wrap(const PropertyDetailScreen(propertyId: 'prop-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text(property.title), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text(property.description), findsOneWidget);
      expect(find.text('Contacter l\'agence'), findsOneWidget);

      // Sections en bas de page — hors de la fenêtre de rendu lazy de la
      // sliver list tant qu'on n'a pas scrollé jusque là.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(find.text('Localisation'), findsOneWidget);
      expect(find.text('Caractéristiques'), findsOneWidget);
      expect(find.text('Consommation énergétique'), findsOneWidget);
    });
  });

  testWidgets(
    'le favori fonctionne sans compte : ajout puis retrait, sans invite de '
    'connexion',
    (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          _wrap(const PropertyDetailScreen(propertyId: 'prop-1')),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsNothing);

        // Ajout.
        await tester.tap(find.byIcon(Icons.favorite_border));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(
          find.text('Connecte-toi pour ajouter ce bien à tes favoris'),
          findsNothing,
        );

        // Retrait.
        await tester.tap(find.byIcon(Icons.favorite));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsNothing);
      });
    },
  );

  testWidgets('contacter l\'agence reste protégé par la porte de connexion', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        _wrap(const PropertyDetailScreen(propertyId: 'prop-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contacter l\'agence'));
      await tester.pump();

      expect(
        find.text('Connecte-toi pour contacter l\'agence'),
        findsOneWidget,
      );
    });
  });
}
