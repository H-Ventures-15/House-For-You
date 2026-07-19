import 'package:go_router/go_router.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import 'branch_fade_container.dart';
import 'main_shell.dart';

/// Config GoRouter — étape 1 : coquille de navigation à 4 onglets
/// (Découvrir, Rechercher, Favoris, Profil), tous accessibles sans compte.
/// Chaque onglet a sa propre branche (pile de navigation indépendante,
/// préservée lors des changements d'onglet).
final GoRouter appRouter = GoRouter(
  initialLocation: '/discover',
  routes: [
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          BranchFadeContainer(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => const DiscoverScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
