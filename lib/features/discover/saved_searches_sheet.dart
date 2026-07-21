import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/saved_search.dart';
import '../../data/providers/saved_searches_controller.dart';
import '../../data/providers/search_filters_controller.dart';
import 'filters/filter_options.dart';
import 'filters/saved_search_name_dialog.dart';

/// Panneau "recherches enregistrées", accessible en un geste depuis la
/// barre flottante du feed (voir `FloatingSearchBar`) — permet de changer de
/// recherche sans rouvrir toute la feuille de filtres (voir PRODUCT_SPEC.md
/// section 10.2). Charger une recherche ne nécessite pas de session
/// (lecture seule) ; renommer/supprimer non plus à cette étape (voir
/// DECISIONS.md ADR-016).
Future<void> showSavedSearchesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _SavedSearchesSheet(),
  );
}

class _SavedSearchesSheet extends ConsumerWidget {
  const _SavedSearchesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchesAsync = ref.watch(savedSearchesControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recherches enregistrées',
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: searchesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Impossible de charger tes recherches.',
                        style: AppTypography.bodySecondary,
                      ),
                    ),
                  ),
                  data: (searches) {
                    if (searches.isEmpty) {
                      return const _EmptySavedSearches();
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: searches.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _SavedSearchTile(search: searches[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptySavedSearches extends StatelessWidget {
  const _EmptySavedSearches();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Aucune recherche enregistrée pour l\'instant.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Enregistre tes critères depuis la feuille de filtres pour '
              'les retrouver ici.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedSearchTile extends ConsumerWidget {
  const _SavedSearchTile({required this.search});

  final SavedSearch search;

  Future<void> _handleRename(BuildContext context, WidgetRef ref) async {
    final name = await promptSavedSearchName(
      context: context,
      title: 'Renommer cette recherche',
      initialValue: search.label,
      confirmLabel: 'Renommer',
    );
    if (name == null) return;
    final finalName = name.trim().isEmpty ? search.label : name.trim();
    await ref
        .read(savedSearchesControllerProvider.notifier)
        .rename(search.id, finalName);
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette recherche ?'),
        content: Text('« ${search.label} » sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(savedSearchesControllerProvider.notifier).remove(search.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('« ${search.label} » supprimée.')),
      );
  }

  void _handleLoad(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    ref
        .read(searchFiltersControllerProvider.notifier)
        .update((_) => search.filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Charger la recherche « ${search.label} »',
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _handleLoad(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    savedSearchIcon(search.filters),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        search.label,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        savedSearchSubtitle(search.filters),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Renommer « ${search.label} »',
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => _handleRename(context, ref),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Supprimer « ${search.label} »',
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => _handleDelete(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
