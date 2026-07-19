import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

/// Racine de l'app, `ProviderScope` inclus — autonome pour que
/// `tester.pumpWidget(const HouseForYouApp())` fonctionne sans wrapper
/// supplémentaire (voir `main.dart`, qui ne fait qu'appeler `runApp`).
class HouseForYouApp extends StatelessWidget {
  const HouseForYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'House For You',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    );
  }
}
