import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/blurred_modal_sheet.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../data/models/property.dart';
import '../../../data/models/saved_search.dart';
import '../../../data/models/search_filters.dart';
import '../../../data/providers/saved_searches_controller.dart';
import '../../../data/providers/search_filters_controller.dart';
import 'filter_options.dart';
import 'filter_widgets.dart';
import 'saved_search_name_dialog.dart';

/// Feuille de filtres plein écran — monte depuis le bas avec un fond
/// flouté (voir `showBlurredModalSheet`), jamais une nouvelle page. Les
/// sélections s'appliquent immédiatement au provider global
/// `searchFiltersControllerProvider` : pas de distinction brouillon/validé,
/// chaque interaction met à jour en direct le résumé de la barre flottante
/// et le compteur simulé en bas de feuille.
Future<void> showFiltersSheet(BuildContext context) {
  return showBlurredModalSheet<void>(
    context: context,
    builder: (context) => const FiltersSheet(),
  );
}

class FiltersSheet extends ConsumerStatefulWidget {
  const FiltersSheet({super.key});

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  static const double _rentBudgetMax = 3000;
  static const double _saleBudgetMax = 1000000;
  static const double _surfaceMax = 400;
  static const double _landSurfaceMax = 3000;

  late final TextEditingController _locationController = TextEditingController(
    text: ref.read(searchFiltersControllerProvider).city ?? '',
  );
  final FocusNode _locationFocusNode = FocusNode();
  bool _locationFieldFocused = false;

  /// Filtres avancés repliés par défaut — seuls les critères principaux
  /// (localisation, transaction, budget, type de bien, chambres) sont
  /// immédiatement visibles, pour ne jamais donner l'impression de remplir
  /// un formulaire administratif (voir UX_RULES.md section 9 bis).
  bool _showMoreFilters = false;

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      setState(() => _locationFieldFocused = _locationFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _updateFilters(SearchFilters Function(SearchFilters) updater) {
    ref.read(searchFiltersControllerProvider.notifier).update(updater);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersControllerProvider);
    final count = ref.watch(filteredPropertyCountProvider);
    final savedSearches =
        ref.watch(savedSearchesControllerProvider).valueOrNull ?? const [];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _Header(
              hasActiveFilters: !filters.isEmpty,
              onClose: () => Navigator.of(context).maybePop(),
              onReset: () =>
                  ref.read(searchFiltersControllerProvider.notifier).reset(),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _locationFocusNode.unfocus(),
                child: ListView(
                  // Toujours "draggable", même quand le contenu tient déjà
                  // dans la hauteur visible (peu de filtres actifs) — sans
                  // cela, aucune notification de scroll ne remonte et le
                  // swipe de fermeture de la feuille (voir
                  // `BlurredModalSheet`) resterait inopérant dans ce cas.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    // --- Filtres principaux : toujours visibles, jamais
                    // noyés parmi les critères avancés (voir UX_RULES.md
                    // section 9 bis).
                    _buildLocationSection(filters),
                    if (_locationFieldFocused &&
                        _locationController.text.isNotEmpty)
                      _buildSuggestions(),
                    const SizedBox(height: AppSpacing.md),
                    _buildRadiusSection(filters),
                    _sectionDivider(),
                    _buildTransactionSection(filters),
                    _sectionDivider(),
                    _buildBudgetSection(filters),
                    _sectionDivider(),
                    _buildPropertyTypeSection(filters),
                    _sectionDivider(),
                    _buildBedroomsSection(filters),
                    _sectionDivider(),
                    _buildSavedSearchesSection(filters, savedSearches),
                    _sectionDivider(),
                    // --- Critères avancés : repliés par défaut.
                    _buildMoreFiltersToggle(filters),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: !_showMoreFilters
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSpacing.xl),
                                _buildBathroomsSection(filters),
                                _sectionDivider(),
                                _buildSurfaceSection(filters),
                                if (_showsLandSurface(filters)) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildLandSurfaceSection(filters),
                                ],
                                _sectionDivider(),
                                _buildEnergySection(filters),
                                _sectionDivider(),
                                _buildCharacteristicsSection(filters),
                                _sectionDivider(),
                                _buildConditionSection(filters),
                                _sectionDivider(),
                                _buildPublicationSection(filters),
                                _sectionDivider(),
                                _buildSortSection(filters),
                                _sectionDivider(),
                                _buildAmbianceSection(filters),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              count: count,
              onShowResults: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Divider(height: 1),
    );
  }

  bool _showsLandSurface(SearchFilters filters) {
    if (filters.propertyTypes.isEmpty) return true;
    return filters.propertyTypes.contains(PropertyType.house) ||
        filters.propertyTypes.contains(PropertyType.land);
  }

  /// Nombre de critères avancés actifs (tout ce qui vit sous "Plus de
  /// filtres") — affiché en badge quand la section est repliée, pour que
  /// l'utilisateur ne perde jamais de vue qu'un critère avancé est actif
  /// même sans la déplier.
  int _advancedFilterCount(SearchFilters filters) {
    var count = 0;
    if (filters.minBathrooms != null) count++;
    if (filters.minSurface != null || filters.maxSurface != null) count++;
    if (filters.minLandSurface != null || filters.maxLandSurface != null) {
      count++;
    }
    if (filters.energyScores.isNotEmpty) count++;
    if (filters.characteristics.isNotEmpty) count++;
    if (filters.condition != null) count++;
    if (filters.publicationRecency != null) count++;
    if (filters.sortOption != SortOption.relevance) count++;
    if (filters.ambiances.isNotEmpty) count++;
    return count;
  }

  Widget _buildMoreFiltersToggle(SearchFilters filters) {
    final advancedCount = _advancedFilterCount(filters);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => setState(() => _showMoreFilters = !_showMoreFilters),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Text(
                'Plus de filtres',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (advancedCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$advancedCount',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              AnimatedRotation(
                duration: const Duration(milliseconds: 220),
                turns: _showMoreFilters ? 0.5 : 0,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Localisation ---------------------------------------------------

  Widget _buildLocationSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(
          title: 'Localisation',
          subtitle: 'Ville, code postal, province ou région',
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            key: const Key('filters-location-field'),
            controller: _locationController,
            focusNode: _locationFocusNode,
            textInputAction: TextInputAction.search,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: 'Ex. Mons, 7000, Namur...',
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              suffixIcon: _locationController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _locationController.clear();
                        _updateFilters((f) => f.copyWith(city: () => null));
                        setState(() {});
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
              ),
            ),
            onChanged: (value) {
              _updateFilters(
                (f) => f.copyWith(city: () => value.isEmpty ? null : value),
              );
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    final query = _locationController.text.toLowerCase();
    final matches = locationSuggestions
        .where((s) => s.toLowerCase().contains(query))
        .take(5)
        .toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final suggestion in matches)
            InkWell(
              onTap: () {
                _locationController.text = suggestion;
                _updateFilters((f) => f.copyWith(city: () => suggestion));
                _locationFocusNode.unfocus();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.north_west_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(suggestion, style: AppTypography.body),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadiusSection(SearchFilters filters) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in radiusOptions)
          PillChoice(
            label: option.label,
            selected: filters.radiusKm == option.km,
            onTap: () =>
                _updateFilters((f) => f.copyWith(radiusKm: () => option.km)),
          ),
      ],
    );
  }

  // --- Type de transaction ---------------------------------------------

  Widget _buildTransactionSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Type de transaction'),
        for (final option in transactionOptions) ...[
          BigChoiceCard(
            icon: option.icon,
            label: option.label,
            subtitle: option.subtitle,
            selected: filters.transactionType == option.value,
            onTap: () {
              final changingTransaction =
                  filters.transactionType != option.value;
              if (changingTransaction) HapticFeedback.selectionClick();
              _updateFilters(
                (f) => f.copyWith(
                  transactionType: () => option.value,
                  // Achat et location vivent sur des échelles de prix sans
                  // rapport (ex. 350 000 € vs 700 €/mois) — garder l'ancien
                  // budget au changement de transaction produirait un
                  // filtre incompatible avec la nouvelle échelle (voir
                  // UX_RULES.md section 17, "filtres incompatibles").
                  // Un simple re-tap de la même option ne doit en revanche
                  // jamais effacer un budget déjà choisi.
                  budgetMin: changingTransaction ? () => null : null,
                  budgetMax: changingTransaction ? () => null : null,
                ),
              );
            },
          ),
          if (option != transactionOptions.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // --- Budget ------------------------------------------------------------

  Widget _buildBudgetSection(SearchFilters filters) {
    final isRent = filters.transactionType == TransactionType.rent;
    final max = isRent ? _rentBudgetMax : _saleBudgetMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Budget'),
        RangeSliderField(
          min: 0,
          max: max,
          currentMin: (filters.budgetMin ?? 0).toDouble(),
          currentMax: (filters.budgetMax ?? max).toDouble(),
          divisions: 40,
          valueLabel: (value) =>
              isRent ? '${value.round()} €' : '${(value / 1000).round()}k €',
          onChanged: (values) => _updateFilters(
            (f) => f.copyWith(
              budgetMin: () => values.start <= 0 ? null : values.start,
              budgetMax: () => values.end >= max ? null : values.end,
            ),
          ),
        ),
      ],
    );
  }

  // --- Type de bien --------------------------------------------------

  Widget _buildPropertyTypeSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Type de bien'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.05,
          children: [
            for (final option in propertyTypeOptions)
              IconGridChoice(
                icon: option.icon,
                label: option.label,
                selected: filters.propertyTypes.contains(option.type),
                onTap: () {
                  final updated = {...filters.propertyTypes};
                  if (updated.contains(option.type)) {
                    updated.remove(option.type);
                  } else {
                    updated.add(option.type);
                  }
                  _updateFilters((f) => f.copyWith(propertyTypes: updated));
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- Chambres (principal) / salles de bain (avancé) -------------------

  Widget _buildBedroomsSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Chambres'),
        QuickCountSelector(
          options: bedroomQuickOptions,
          selected: filters.minBedrooms,
          onChanged: (value) =>
              _updateFilters((f) => f.copyWith(minBedrooms: () => value)),
        ),
      ],
    );
  }

  Widget _buildBathroomsSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Salles de bain'),
        QuickCountSelector(
          options: bathroomQuickOptions,
          selected: filters.minBathrooms,
          onChanged: (value) =>
              _updateFilters((f) => f.copyWith(minBathrooms: () => value)),
        ),
      ],
    );
  }

  // --- Surfaces ------------------------------------------------------

  Widget _buildSurfaceSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Surface habitable'),
        RangeSliderField(
          min: 0,
          max: _surfaceMax,
          currentMin: (filters.minSurface ?? 0).toDouble(),
          currentMax: (filters.maxSurface ?? _surfaceMax).toDouble(),
          divisions: 40,
          valueLabel: (value) => '${value.round()} m²',
          onChanged: (values) => _updateFilters(
            (f) => f.copyWith(
              minSurface: () => values.start <= 0 ? null : values.start,
              maxSurface: () => values.end >= _surfaceMax ? null : values.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandSurfaceSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Surface du terrain'),
        RangeSliderField(
          min: 0,
          max: _landSurfaceMax,
          currentMin: (filters.minLandSurface ?? 0).toDouble(),
          currentMax: (filters.maxLandSurface ?? _landSurfaceMax).toDouble(),
          divisions: 30,
          valueLabel: (value) => '${value.round()} m²',
          onChanged: (values) => _updateFilters(
            (f) => f.copyWith(
              minLandSurface: () => values.start <= 0 ? null : values.start,
              maxLandSurface: () =>
                  values.end >= _landSurfaceMax ? null : values.end,
            ),
          ),
        ),
      ],
    );
  }

  // --- Certificat énergétique -----------------------------------------

  Widget _buildEnergySection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Certificat énergétique (PEB)'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final grade in energyScoreOptions)
              PillChoice(
                label: grade,
                color: energyScoreColors[grade],
                selected: filters.energyScores.contains(grade),
                onTap: () {
                  final updated = {...filters.energyScores};
                  if (!updated.remove(grade)) updated.add(grade);
                  _updateFilters((f) => f.copyWith(energyScores: updated));
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- Caractéristiques ------------------------------------------------

  Widget _buildCharacteristicsSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Caractéristiques'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.05,
          children: [
            for (final option in characteristicOptions)
              IconGridChoice(
                icon: option.icon,
                label: option.label,
                selected: filters.characteristics.contains(option.key),
                onTap: () {
                  final updated = {...filters.characteristics};
                  if (!updated.remove(option.key)) updated.add(option.key);
                  _updateFilters((f) => f.copyWith(characteristics: updated));
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- État du bien ----------------------------------------------------

  Widget _buildConditionSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'État du bien'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in conditionOptions)
              PillChoice(
                label: option.label,
                selected: filters.condition == option.value,
                onTap: () => _updateFilters(
                  (f) => f.copyWith(
                    condition: () =>
                        filters.condition == option.value ? null : option.value,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- Date de publication ---------------------------------------------

  Widget _buildPublicationSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Date de publication'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in publicationOptions)
              PillChoice(
                label: option.label,
                selected: filters.publicationRecency == option.value,
                onTap: () => _updateFilters(
                  (f) => f.copyWith(
                    publicationRecency: () =>
                        filters.publicationRecency == option.value
                            ? null
                            : option.value,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- Tri -------------------------------------------------------------

  Widget _buildSortSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Trier par'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in sortOptions)
              PillChoice(
                label: option.label,
                selected: filters.sortOption == option.value,
                onTap: () => _updateFilters(
                  (f) => f.copyWith(sortOption: option.value),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- Ambiance de vie ---------------------------------------------------

  Widget _buildAmbianceSection(SearchFilters filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(
          title: 'Ambiance de vie',
          subtitle: 'Explore autrement qu\'avec des critères techniques',
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in ambianceOptions)
              PillChoice(
                label: '${option.emoji}  ${option.label}',
                selected: filters.ambiances.contains(option.key),
                onTap: () {
                  final updated = {...filters.ambiances};
                  if (!updated.remove(option.key)) updated.add(option.key);
                  _updateFilters((f) => f.copyWith(ambiances: updated));
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- Recherches enregistrées ------------------------------------------

  Widget _buildSavedSearchesSection(
    SearchFilters filters,
    List<SavedSearch> savedSearches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetSectionHeader(title: 'Recherches enregistrées'),
        if (savedSearches.isNotEmpty) ...[
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: savedSearches.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final search = savedSearches[index];
                return Semantics(
                  button: true,
                  label: 'Charger la recherche « ${search.label} »',
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => _handleLoadSavedSearch(search),
                      child: Container(
                        width: 148,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              savedSearchIcon(search.filters),
                              color: AppColors.primary,
                              size: 20,
                            ),
                            Text(
                              search.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextButton.icon(
          onPressed: () => _handleSaveSearch(filters),
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Enregistrer cette recherche'),
        ),
      ],
    );
  }

  void _handleLoadSavedSearch(SavedSearch search) {
    HapticFeedback.selectionClick();
    ref.read(searchFiltersControllerProvider.notifier).update(
          (_) => search.filters,
        );
    _locationController.text = search.filters.city ?? '';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('« ${search.label} » chargée.')));
  }

  Future<void> _handleSaveSearch(SearchFilters filters) async {
    final defaultName = defaultSavedSearchName(filters);
    final name = await promptSavedSearchName(
      context: context,
      title: 'Enregistrer cette recherche',
      initialValue: defaultName,
    );
    // `null` = dialogue annulé ; une saisie vide retombe sur le nom par
    // défaut plutôt que de créer une recherche sans nom (voir UX_RULES.md
    // section 17, "recherche sans nom").
    if (name == null) return;
    final finalName = name.trim().isEmpty ? defaultName : name.trim();
    await ref.read(savedSearchesControllerProvider.notifier).save(
          finalName,
          filters,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('« $finalName » enregistrée.')),
      );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.hasActiveFilters,
    required this.onClose,
    required this.onReset,
  });

  final bool hasActiveFilters;
  final VoidCallback onClose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
                tooltip: 'Fermer',
              ),
              const Expanded(
                child: Text(
                  'Filtres',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium,
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: hasActiveFilters ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !hasActiveFilters,
                  child: TextButton(
                    onPressed: onReset,
                    child: const Text('Réinitialiser'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.count, required this.onShowResults});

  final int count;
  final VoidCallback onShowResults;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: PressableScale(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onShowResults();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                textStyle: AppTypography.button.copyWith(fontSize: 17),
              ),
              child: Text('Afficher $count biens'),
            ),
          ),
        ),
      ),
    );
  }
}
