import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/discover/property_detail_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import 'branch_fade_container.dart';
import 'main_shell.dart';

/// Config GoRouter — étape 1 : coquille de navigation à 4 onglets
/// (Découvrir, Rechercher, Favoris, Profil), tous accessibles sans compte.
/// Chaque onglet a sa propre branche (pile de navigation indépendante,
/// préservée lors des changements d'onglet).
///
/// La fiche détail bien (`/property/:id`) est un top-level `GoRoute`, hors
/// du shell : poussée sur le Navigator racine, elle occupe tout l'écran
/// sans la bottom bar, avec une transition fondu + léger glissement (voir
/// architecture-mvp.md, section 7 — "route push réutilisée partout").
final GoRouter appRouter = GoRouter(
  initialLocation: '/discover',
  routes: [
    GoRoute(
      path: '/property/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PropertyDetailScreen(propertyId: id),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
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
