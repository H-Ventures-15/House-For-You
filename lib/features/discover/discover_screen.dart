import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_guard.dart';
import '../../core/services/session_id.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/property_card.dart';
import '../../data/models/agency.dart';
import '../../data/models/property.dart';
import '../../data/models/property_event.dart';
import '../../data/providers/favorites_controller.dart';
import '../../data/providers/feed_providers.dart';
import '../../data/providers/repository_providers.dart';

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
          return _DiscoverFeed(
            properties: properties,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackImpression(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  void _handleToggleFavorite(Property property) {
    final granted = requireAuth(
      context,
      ref,
      message: 'Connecte-toi pour ajouter ce bien à tes favoris',
    );
    if (!granted) return;
    ref.read(favoritesControllerProvider.notifier).toggle(property.id);
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoritesControllerProvider);

    return PageView.builder(
      key: const Key('discover-feed'),
      controller: _controller,
      scrollDirection: Axis.vertical,
      onPageChanged: _trackImpression,
      itemCount: widget.properties.length,
      itemBuilder: (context, index) {
        final property = widget.properties[index];
        return PropertyCard.feed(
          key: ValueKey(property.id),
          property: property,
          isFavorite: favoriteIds.contains(property.id),
          agency: widget.agenciesById[property.agencyId],
          onTap: () => context.push('/property/${property.id}'),
          onToggleFavorite: () => _handleToggleFavorite(property),
          onShare: () => _handleShare(property),
        );
      },
    );
  }
}
