import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/property_card.dart';
import '../../data/providers/favorites_controller.dart';
import '../../data/providers/feed_providers.dart';
import '../../l10n/app_localizations.dart';

/// Onglet Favoris — accessible sans compte (voir DECISIONS.md) : la liste
/// des biens favoris de l'appareil, persistés localement
/// (`MockFavoritesDataSource`). L'écran de listing complet (multi-appareil,
/// synchronisé) reste prévu à l'étape 6 — ceci n'anticipe que le strict
/// nécessaire pour valider le favori sans compte sur iPhone.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoriteIds = ref.watch(favoritesControllerProvider);
    final feedAsync = ref.watch(feedPropertiesProvider);

    return Scaffold(
      body: SafeArea(
        child: feedAsync.when(
          loading: () => const LoadingState(),
          error: (error, stackTrace) => ErrorState(
            message: 'Impossible de charger tes favoris. Réessaie.',
            onRetry: () => ref.invalidate(feedPropertiesProvider),
          ),
          data: (properties) {
            final favorites =
                properties.where((p) => favoriteIds.contains(p.id)).toList();
            if (favorites.isEmpty) {
              return _EmptyFavorites(
                title: l10n.navFavorites,
                subtitle: l10n.favoritesComingSoon,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final property = favorites[index];
                return PropertyCard.list(
                  key: ValueKey(property.id),
                  property: property,
                  isFavorite: true,
                  onTap: () => context.push('/property/${property.id}'),
                  onToggleFavorite: () {
                    ref
                        .read(favoritesControllerProvider.notifier)
                        .toggle(property.id);
                    return true;
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
