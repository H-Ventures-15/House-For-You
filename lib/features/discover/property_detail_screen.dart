import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/auth_guard.dart';
import '../../core/services/session_id.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/ph_button.dart';
import '../../core/widgets/property_card.dart';
import '../../data/models/agency.dart';
import '../../data/models/property.dart';
import '../../data/models/property_event.dart';
import '../../data/models/property_media.dart';
import '../../data/providers/favorites_controller.dart';
import '../../data/providers/feed_providers.dart';
import '../../data/providers/repository_providers.dart';

/// Fiche détail d'un bien — route push plein écran réutilisée partout
/// (feed, futurs résultats de recherche), voir architecture-mvp.md
/// section 7. Données mock uniquement, aucune connexion Supabase à cette
/// étape.
class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _trackedOpen = false;

  /// 0 = fiche au repos, 1 = fiche totalement "balancée" hors de l'écran.
  /// Suit le doigt en direct pendant le drag ; s'anime jusqu'à 0 ou 1 au
  /// relâchement (voir `_SwipeToDismiss`).
  late final AnimationController _dismissController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  void _onDismissDragUpdate(DragUpdateDetails details) {
    final width = MediaQuery.of(context).size.width;
    _dismissController.value =
        (_dismissController.value + details.delta.dx / width).clamp(0.0, 1.0);
  }

  void _onDismissDragEnd(DragEndDetails details) {
    final shouldDismiss = _dismissController.value > 0.32 ||
        details.velocity.pixelsPerSecond.dx > 700;
    if (shouldDismiss) {
      _dismissController
          .animateTo(
        1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeIn,
      )
          .whenComplete(() {
        if (mounted) context.pop();
      });
    } else {
      _dismissController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
      );
    }
  }

  void _trackDetailOpenOnce() {
    if (_trackedOpen) return;
    _trackedOpen = true;
    ref.read(analyticsServiceProvider).track(
          PropertyEvent(
            propertyId: widget.propertyId,
            userId: isAuthenticated(ref) ? mockSessionUserId : null,
            sessionId: ref.read(sessionIdProvider),
            eventType: PropertyEventType.detailOpen,
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

  void _handleContact() {
    final granted = requireAuth(
      context,
      ref,
      message: 'Connecte-toi pour contacter l\'agence',
    );
    if (!granted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Le formulaire de contact arrive bientôt.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyByIdProvider(widget.propertyId));
    final agenciesAsync = ref.watch(agenciesByIdProvider);
    final favoriteIds = ref.watch(favoritesControllerProvider);

    return Scaffold(
      // Transparent : la route est `opaque: false` (voir app_router.dart)
      // pour que le feed reste peint dessous pendant le swipe de fermeture.
      // `_DetailBody` porte son propre fond opaque au repos — voir plus bas.
      backgroundColor: Colors.transparent,
      body: propertyAsync.when(
        loading: () => const ColoredBox(
          color: AppColors.background,
          child: LoadingState(),
        ),
        error: (error, stackTrace) => ColoredBox(
          color: AppColors.background,
          child: ErrorState(
            message: 'Impossible de charger ce bien. Réessaie.',
            onRetry: () =>
                ref.invalidate(propertyByIdProvider(widget.propertyId)),
          ),
        ),
        data: (property) {
          if (property == null) {
            return const ColoredBox(
              color: AppColors.background,
              child: ErrorState(message: 'Ce bien n\'est plus disponible.'),
            );
          }
          _trackDetailOpenOnce();
          final agency = agenciesAsync.valueOrNull?[property.agencyId];
          final galleryHeight = MediaQuery.of(context).size.height * 0.48;
          return _SwipeToDismiss(
            controller: _dismissController,
            galleryHeight: galleryHeight,
            onDragUpdate: _onDismissDragUpdate,
            onDragEnd: _onDismissDragEnd,
            child: _DetailBody(
              property: property,
              agency: agency,
              isFavorite: favoriteIds.contains(property.id),
              galleryHeight: galleryHeight,
              onShare: () => _handleShare(property),
              onToggleFavorite: () => _handleToggleFavorite(property),
              onContact: _handleContact,
            ),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.property,
    required this.agency,
    required this.isFavorite,
    required this.galleryHeight,
    required this.onShare,
    required this.onToggleFavorite,
    required this.onContact,
  });

  final Property property;
  final Agency? agency;
  final bool isFavorite;
  final double galleryHeight;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    // Fond opaque normal au repos. Il vit à l'intérieur du contenu balancé
    // par `_SwipeToDismiss` : pendant le swipe de fermeture, il s'estompe
    // avec le reste et laisse transparaître le feed déjà chargé en dessous
    // — jamais de flash blanc.
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DetailGallery(
                  media: property.media,
                  height: galleryHeight,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      formatPropertyPrice(property),
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(property.title, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${propertyTypeLabel(property.propertyType)} · '
                      '${property.city} (${property.postalCode})',
                      style: AppTypography.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DetailStatsRow(property: property),
                    const Divider(height: AppSpacing.xxl * 2),
                    _Section(
                      title: 'Description',
                      child:
                          Text(property.description, style: AppTypography.body),
                    ),
                    _Section(
                      title: 'Localisation',
                      child: _LocationBlock(property: property),
                    ),
                    _Section(
                      title: 'Caractéristiques',
                      child: _FeatureTags(tags: _characteristicTags(property)),
                    ),
                    if (property.features.isNotEmpty)
                      _Section(
                        title: 'Équipements',
                        child: _FeatureTags(
                          tags: property.features
                              .map((f) => '${f.featureKey}: ${f.featureValue}')
                              .toList(),
                        ),
                      ),
                    _Section(
                      title: 'Consommation énergétique',
                      child: _EnergyBadge(score: property.energyScore),
                    ),
                    if (agency != null)
                      _Section(
                        title: 'Agence',
                        child: _AgencyBlock(agency: agency!),
                      ),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    Row(
                      children: [
                        _RoundIconButton(
                          icon: isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          iconColor: isFavorite ? AppColors.error : null,
                          onTap: onToggleFavorite,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _RoundIconButton(
                          icon: Icons.share_outlined,
                          onTap: onShare,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: PhButton(
                  label: 'Contacter l\'agence',
                  icon: Icons.chat_bubble_outline_rounded,
                  expand: true,
                  onPressed: onContact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _characteristicTags(Property property) {
    return [
      '${property.surface.toStringAsFixed(0)} m² habitables',
      if (property.landSurface != null)
        '${property.landSurface!.toStringAsFixed(0)} m² de terrain',
      if (property.constructionYear != null)
        'Construit en ${property.constructionYear}',
      if (property.garden) 'Jardin',
      if (property.garage) 'Garage',
      if (property.terrace) 'Terrasse',
    ];
  }
}

/// Ferme la fiche par swipe horizontal vers la droite, avec un effet de
/// "balancer" (translation + légère rotation autour du bord gauche). La
/// zone de détection se limite à la partie sous la galerie photo : la
/// galerie garde son propre swipe horizontal (photo précédente/suivante)
/// sans ambiguïté de geste. Le suivi du doigt est direct (1:1), pas une
/// simple apparition/disparition.
class _SwipeToDismiss extends StatelessWidget {
  const _SwipeToDismiss({
    required this.controller,
    required this.galleryHeight,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  final AnimationController controller;
  final double galleryHeight;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, animatedChild) {
            final t = controller.value;
            return Opacity(
              opacity: 1 - t * 0.55,
              child: Transform.translate(
                offset: Offset(t * screenWidth * 1.3, 0),
                child: Transform.rotate(
                  angle: t * 0.10,
                  alignment: Alignment.centerLeft,
                  child: animatedChild,
                ),
              ),
            );
          },
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: galleryHeight,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: onDragEnd,
          ),
        ),
      ],
    );
  }
}

class _DetailGallery extends StatefulWidget {
  const _DetailGallery({required this.media, required this.height});

  final List<PropertyMedia> media;
  final double height;

  @override
  State<_DetailGallery> createState() => _DetailGalleryState();
}

class _DetailGalleryState extends State<_DetailGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media.isEmpty)
            Container(
              color: AppColors.border,
              child: const Icon(
                Icons.home_outlined,
                color: AppColors.textSecondary,
                size: 48,
              ),
            )
          else
            PageView.builder(
              controller: _controller,
              itemCount: media.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = media[i].thumbnailUrl ?? media[i].storagePath;
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.border,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          if (media.length > 1)
            Positioned(
              bottom: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${_index + 1}/${media.length}',
                  style: AppTypography.caption.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailStatsRow extends StatelessWidget {
  const _DetailStatsRow({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.square_foot,
          label: '${property.surface.toStringAsFixed(0)} m²',
        ),
        _StatItem(
          icon: Icons.bed_outlined,
          label: '${property.bedrooms} ch.',
        ),
        if (property.bathrooms != null)
          _StatItem(
            icon: Icons.bathtub_outlined,
            label: '${property.bathrooms} SdB',
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.bodySecondary),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            [
              property.city,
              property.postalCode,
              if (property.province != null) property.province,
            ].join(' · '),
            style: AppTypography.body,
          ),
        ),
      ],
    );
  }
}

class _FeatureTags extends StatelessWidget {
  const _FeatureTags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Text('Non renseigné', style: AppTypography.bodySecondary);
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                tag,
                style: AppTypography.bodySecondary.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EnergyBadge extends StatelessWidget {
  const _EnergyBadge({required this.score});

  final String? score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            score ?? '?',
            style: AppTypography.titleMedium.copyWith(color: AppColors.accent),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Text(
            'Certificat PEB — détails complets à venir.',
            style: AppTypography.bodySecondary,
          ),
        ),
      ],
    );
  }
}

class _AgencyBlock extends StatelessWidget {
  const _AgencyBlock({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.border,
          backgroundImage:
              agency.logoUrl != null ? NetworkImage(agency.logoUrl!) : null,
          child: agency.logoUrl == null
              ? const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.textSecondary,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      agency.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (agency.verified) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ],
              ),
              if (agency.city != null)
                Text(agency.city!, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
          boxShadow: kFloatingButtonShadow,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
      ),
    );
  }
}
