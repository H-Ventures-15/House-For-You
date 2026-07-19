import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Composants de présentation partagés par toutes les sections de la
/// feuille de filtres — aucune logique métier ici, uniquement de l'affichage
/// et des callbacks (voir `FiltersSheet` pour l'état).

class SheetSectionHeader extends StatelessWidget {
  const SheetSectionHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTypography.bodySecondary),
          ],
        ],
      ),
    );
  }
}

/// Grande carte de choix (type de transaction) — icône, libellé, sous-titre,
/// bordure et fond qui basculent avec une animation douce à la sélection.
class BigChoiceCard extends StatelessWidget {
  const BigChoiceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.primary,
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
                      label,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puce de choix générique — rayon, tri, état du bien, date, grade EPC...
class PillChoice extends StatelessWidget {
  const PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Couleur d'accent optionnelle (ex. grade EPC) remplaçant
  /// `AppColors.primary` quand sélectionnée.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? accent : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.bodySecondary.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Case d'une grille à icône — type de bien, caractéristiques.
class IconGridChoice extends StatelessWidget {
  const IconGridChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélection rapide "1+ / 2+ / 3+..." — chambres, salles de bain.
class QuickCountSelector extends StatelessWidget {
  const QuickCountSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<int> options;
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: PillChoice(
              label: '$option+',
              selected: selected == option,
              onTap: () => onChanged(selected == option ? null : option),
            ),
          ),
          if (option != options.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Slider double poignée avec champs de saisie manuelle synchronisés.
class RangeSliderField extends StatelessWidget {
  const RangeSliderField({
    required this.min,
    required this.max,
    required this.currentMin,
    required this.currentMax,
    required this.onChanged,
    required this.valueLabel,
    this.divisions,
    super.key,
  });

  final double min;
  final double max;
  final double currentMin;
  final double currentMax;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double) valueLabel;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _AmountField(
                label: 'Minimum',
                value: currentMin,
                valueLabel: valueLabel,
                onSubmitted: (value) => onChanged(
                  RangeValues(
                    value.clamp(min, currentMax),
                    currentMax,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _AmountField(
                label: 'Maximum',
                value: currentMax,
                valueLabel: valueLabel,
                onSubmitted: (value) => onChanged(
                  RangeValues(
                    currentMin,
                    value.clamp(currentMin, max),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: RangeSlider(
            min: min,
            max: max,
            divisions: divisions,
            values: RangeValues(
              currentMin.clamp(min, max),
              currentMax.clamp(min, max),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _AmountField extends StatefulWidget {
  const _AmountField({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onSubmitted,
  });

  final String label;
  final double value;
  final String Function(double) valueLabel;
  final ValueChanged<double> onSubmitted;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.valueLabel(widget.value),
  );

  @override
  void didUpdateWidget(covariant _AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.valueLabel(widget.value);
    }
  }

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(
      _controller.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (parsed != null) widget.onSubmitted(parsed);
    _controller.text = widget.valueLabel(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(widget.label, style: AppTypography.caption),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(),
            textInputAction: TextInputAction.done,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            onSubmitted: (_) => _commit(),
            onTapOutside: (_) {
              _focusNode.unfocus();
              _commit();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}
