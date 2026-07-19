import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../data/providers/repository_providers.dart';

/// Page temporaire de l'étape 0 — confirme que le scaffold Flutter, Riverpod,
/// GoRouter, le design system et les datasources mock fonctionnent bout en
/// bout. Sera remplacée par la coquille de navigation à l'étape 1.
class SetupCheckScreen extends ConsumerWidget {
  const SetupCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(_propertiesCountProvider);
    final agenciesAsync = ref.watch(_agenciesCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('House For You')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_work_outlined,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Configuration du projet',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Étape 0 — vérification du setup',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.xxl),
            propertiesAsync.when(
              data: (count) =>
                  _CheckLine(label: '$count biens fictifs chargés'),
              loading: () => const LoadingState(),
              error: (err, st) => ErrorState(message: 'Erreur biens : $err'),
            ),
            const SizedBox(height: AppSpacing.sm),
            agenciesAsync.when(
              data: (count) =>
                  _CheckLine(label: '$count agences fictives chargées'),
              loading: () => const LoadingState(),
              error: (err, st) => ErrorState(message: 'Erreur agences : $err'),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (propertiesAsync.hasValue && agenciesAsync.hasValue)
              const _CheckLine(
                label: 'Le setup fonctionne correctement.',
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                bold: true,
              ),
          ],
        ),
      ),
    );
  }
}

final _propertiesCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  final properties = await repo.getFeed();
  return properties.length;
});

final _agenciesCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(agencyRepositoryProvider);
  final agencies = await repo.getAll();
  return agencies.length;
});

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.label,
    this.icon = Icons.check,
    this.iconColor = AppColors.primary,
    this.bold = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: bold
              ? AppTypography.body.copyWith(fontWeight: FontWeight.w600)
              : AppTypography.body,
        ),
      ],
    );
  }
}
