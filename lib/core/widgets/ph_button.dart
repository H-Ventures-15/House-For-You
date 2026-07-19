import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum PhButtonVariant { primary, secondary, text }

/// Bouton arrondi réutilisable — variantes primaire/secondaire/texte.
/// Tout écran doit utiliser ce composant plutôt qu'un ElevatedButton brut,
/// pour garder une apparence cohérente (voir architecture-mvp.md, section 8).
class PhButton extends StatelessWidget {
  const PhButton({
    required this.label,
    required this.onPressed,
    this.variant = PhButtonVariant.primary,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final PhButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      PhButtonVariant.primary => ElevatedButton(
          onPressed: onPressed,
          child: child,
        ),
      PhButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            textStyle: AppTypography.button,
          ),
          child: child,
        ),
      PhButtonVariant.text => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.button,
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
