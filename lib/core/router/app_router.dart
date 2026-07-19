import 'package:go_router/go_router.dart';
import '../../features/setup_check/setup_check_screen.dart';

/// Config GoRouter — étape 0 : une seule route (page de confirmation du
/// setup). L'étape 1 remplacera ceci par un `StatefulShellRoute` à 4 onglets
/// (Découvrir, Rechercher, Favoris, Profil), tous accessibles sans compte
/// (voir architecture-mvp.md, section 7).
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SetupCheckScreen()),
  ],
);
