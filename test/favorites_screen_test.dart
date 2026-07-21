import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/core/widgets/property_card.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:house_for_you/data/providers/favorites_controller.dart';
import 'package:house_for_you/features/favorites/favorites_screen.dart';
import 'package:house_for_you/l10n/app_localizations.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onglet Favoris, accessible sans compte (voir DECISIONS.md) : couvre
/// l'état vide et la présence réelle d'un bien favori local persisté.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets('aucun favori : état vide explicite', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        ProviderScope(child: wrap(const FavoritesScreen())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Retrouve ici les biens que tu auras sauvegardés.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('un bien ajouté aux favoris apparaît dans la liste', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final property = mockProperties.first;

      await container
          .read(favoritesControllerProvider.notifier)
          .toggle(property.id);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: wrap(const FavoritesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(formatPropertyPrice(property)), findsOneWidget);
      expect(
        find.text('Retrouve ici les biens que tu auras sauvegardés.'),
        findsNothing,
      );
    });
  });
}
