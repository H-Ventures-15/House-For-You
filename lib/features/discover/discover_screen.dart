import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_guard.dart';
import '../../core/services/session_id.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/floating_search_bar.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/property_card.dart';
import '../../data/models/agency.dart';
import '../../data/models/property.dart';
import '../../data/models/property_event.dart';
import '../../data/providers/favorites_controller.dart';
import '../../data/providers/feed_providers.dart';
import '../../data/providers/repository_providers.dart';
import '../../data/providers/search_filters_controller.dart';
import 'filters/filter_options.dart';
import 'filters/filters_sheet.dart';
import 'saved_searches_sheet.dart';

/// Onglet Découvrir — feed vertical plein écran, un bien par page. Le swipe
/// vertical fait défiler les biens ; le swipe horizontal, à l'intérieur de
/// chaque carte, fait défiler ses photos — les deux gestes sont indépendants
/// (voir `PropertyCard.feed` / `_Gallery`).
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedPropertiesProvider);
    final agenciesAsync = ref.watch(agenciesByIdProvider);
    final filters = ref.watch(searchFiltersControllerProvider);

    return Scaffold(
      body: feedAsync.when(
        loading: () => const LoadingState(),
        error: (error, stackTrace) => ErrorState(
          message: 'Impossible de charger les biens. Réessaie.',
          onRetry: () => ref.invalidate(feedPropertiesProvider),
        ),
        data: (properties) {
          if (properties.isEmpty) {
            return const ErrorState(
              message: 'Aucun bien à afficher pour le moment.',
            );
          }
          final filtered = filters.isEmpty
              ? properties
              : properties.where(filters.matches).toList();
          if (filtered.isEmpty) {
            return ErrorState(
              message: 'Aucun bien ne correspond à ces filtres. '
                  'Essaie d\'en retirer quelques-uns.',
              onRetry: () =>
                  ref.read(searchFiltersControllerProvider.notifier).reset(),
            );
          }
          return _DiscoverFeed(
            properties: filtered,
            agenciesById: agenciesAsync.valueOrNull ?? const {},
          );
        },
      ),
    );
  }
}

class _DiscoverFeed extends ConsumerStatefulWidget {
  const _DiscoverFeed({required this.properties, required this.agenciesById});

  final List<Property> properties;
  final Map<String, Agency> agenciesById;

  @override
  ConsumerState<_DiscoverFeed> createState() => _DiscoverFeedState();
}

class _DiscoverFeedState extends ConsumerState<_DiscoverFeed> {
  final PageController _controller = PageController();
  final Set<String> _trackedImpressions = {};

  /// 1 = barre flottante entièrement visible, 0 = entièrement masquée.
  /// Suit le doigt en continu pendant le drag (pas un show/hide binaire) —
  /// voir `_onScroll` — puis se recale exactement sur 0 ou 1 dès qu'une
  /// page est réellement franchie — voir `_onPageChanged` — pour ne jamais
  /// rester bloquée sur une valeur intermédiaire à cause d'un léger
  /// dépassement de la simulation physique en fin de geste.
  final ValueNotifier<double> _barVisibility = ValueNotifier(1);
  double? _lastRawPage;
  int _lastSettledIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackImpression(0);
      _precacheNeighbors(0);
    });
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _barVisibility.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final page = _controller.page;
    if (page == null) return;
    if (_lastRawPage != null) {
      final delta = page - _lastRawPage!;
      _barVisibility.value = (_barVisibility.value - delta).clamp(0.0, 1.0);
    }
    _lastRawPage = page;
  }

  void _onPageChanged(int index) {
    _trackImpression(index);
    _precacheNeighbors(index);
    _barVisibility.value = index > _lastSettledIndex ? 0 : 1;
    _lastSettledIndex = index;
  }

  /// Précharge les photos du bien précédent et du bien suivant pour que le
  /// swipe vertical paraisse instantané (voir `Image.network` + le cache
  /// d'images Flutter, qui réutilise cette précharge sans nouvelle requête
  /// une fois la carte réellement construite).
  void _precacheNeighbors(int index) {
    for (final neighbor in [index - 1, index + 1]) {
      if (neighbor < 0 || neighbor >= widget.properties.length) continue;
      for (final media in widget.properties[neighbor].media.take(2)) {
        final url = media.thumbnailUrl ?? media.storagePath;
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  void _trackImpression(int index) {
    if (index < 0 || index >= widget.properties.length) return;
    final property = widget.properties[index];
    if (!_trackedImpressions.add(property.id)) return;
    ref.read(analyticsServiceProvider).track(
          PropertyEvent(
            propertyId: property.id,
            userId: isAuthenticated(ref) ? mockSessionUserId : null,
            sessionId: ref.read(sessionIdProvider),
            eventType: PropertyEventType.feedImpression,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> _handleShare(Property property) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Découvre ce bien sur House For You : ${property.title} — '
            '${formatPropertyPrice(property)} à ${property.city}.',
      ),
    );
    await ref.read(analyticsServiceProvider).track(
          PropertyEvent(
            propertyId: property.id,
            userId: isAuthenticated(ref) ? mockSessionUserId : null,
            sessionId: ref.read(sessionIdProvider),
            eventType: PropertyEventType.share,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Retourne `true` si le favori a effectivement changé (session
  /// authentifiée) — `false` si bloqué par la porte d'authentification, pour
  /// que l'appelant (bouton ou double tap) sache s'il doit animer.
  bool _handleToggleFavorite(Property property) {
    final granted = requireAuth(
      context,
      ref,
      message: 'Connecte-toi pour ajouter ce bien à tes favoris',
    );
    if (!granted) return false;
    ref.read(favoritesControllerProvider.notifier).toggle(property.id);
    return true;
  }

  void _handleFilters() {
    showFiltersSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoritesControllerProvider);
    final filtersSummary = summarizeFilters(
      ref.watch(searchFiltersControllerProvider),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond sombre plutôt que blanc : le léger espace visuel révélé par
        // l'effet de profondeur entre deux biens ne doit jamais lire comme
        // un blanc de page, mais comme une immersion continue façon
        // TikTok/Instagram — jamais de flash blanc pendant le swipe.
        const ColoredBox(color: Color(0xFF0B0B0C)),
        PageView.builder(
          key: const Key('discover-feed'),
          controller: _controller,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: widget.properties.length,
          itemBuilder: (context, index) {
            final property = widget.properties[index];
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final page = _controller.hasClients
                    ? (_controller.page ?? _controller.initialPage.toDouble())
                    : index.toDouble();
                final distance = (page - index).abs().clamp(0.0, 1.0);
                final scale = 1 - distance * 0.06;
                return Transform.scale(scale: scale, child: child);
              },
              child: PropertyCard.feed(
                key: ValueKey(property.id),
                property: property,
                isFavorite: favoriteIds.contains(property.id),
                agency: widget.agenciesById[property.agencyId],
                onTap: () => context.push('/property/${property.id}'),
                onToggleFavorite: () => _handleToggleFavorite(property),
                onShare: () => _handleShare(property),
              ),
            );
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: ValueListenableBuilder<double>(
                valueListenable: _barVisibility,
                builder: (context, visibility, child) {
                  return Opacity(
                    opacity: visibility,
                    child: Transform.translate(
                      offset: Offset(0, (1 - visibility) * -32),
                      child: child,
                    ),
                  );
                },
                child: FloatingSearchBar(
                  summary: filtersSummary,
                  onTap: _handleFilters,
                  onFilters: _handleFilters,
                  onSavedSearches: () => showSavedSearchesSheet(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
