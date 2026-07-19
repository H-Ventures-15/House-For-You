import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:house_for_you/features/discover/property_detail_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

void main() {
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

  testWidgets('le favori invité affiche une invite de connexion', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        _wrap(const PropertyDetailScreen(propertyId: 'prop-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(
        find.text('Connecte-toi pour ajouter ce bien à tes favoris'),
        findsOneWidget,
      );
    });
  });
}
