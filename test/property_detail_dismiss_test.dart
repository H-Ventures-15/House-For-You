import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:house_for_you/features/discover/property_detail_screen.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// Vérifie la fermeture de la fiche par swipe horizontal vers la droite
/// (zone sous la galerie photo) : la fiche se ferme et le feed sous-jacent
/// redevient visible.
void main() {
  testWidgets('swipe horizontal vers la droite ferme la fiche', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final router = GoRouter(
        initialLocation: '/discover',
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('FEED'))),
          ),
          GoRoute(
            path: '/property/:id',
            builder: (context, state) => PropertyDetailScreen(
              propertyId: state.pathParameters['id']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      router.push('/property/prop-1');
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(find.text('FEED'), findsNothing);

      // Démarre sous la galerie (48% de la hauteur de l'écran de test,
      // ~288px sur 600) pour ne pas interférer avec son propre swipe
      // horizontal (photo précédente/suivante).
      await tester.dragFrom(const Offset(400, 450), const Offset(320, 0));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsNothing);
      expect(find.text('FEED'), findsOneWidget);
    });
  });

  testWidgets('un petit swipe horizontal ne ferme pas la fiche', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final router = GoRouter(
        initialLocation: '/discover',
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('FEED'))),
          ),
          GoRoute(
            path: '/property/:id',
            builder: (context, state) => PropertyDetailScreen(
              propertyId: state.pathParameters['id']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      router.push('/property/prop-1');
      await tester.pumpAndSettle();

      // Distance sous le seuil de fermeture (0.32 * largeur d'écran).
      await tester.dragFrom(const Offset(400, 450), const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });
  });
}
