import 'package:flutter/material.dart';
import '../../data/models/agency.dart';
import '../../data/models/property.dart';
import '../../data/models/property_media.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'snappy_page_physics.dart';

/// Un seul composant, deux variantes — garantit la cohérence visuelle entre
/// le feed Découvrir (`.feed()`, plein écran) et les listes de résultats /
/// favoris (`.list()`, compacte). Voir architecture-mvp.md, section 8.
class PropertyCard extends StatelessWidget {
  const PropertyCard.feed({
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required bool Function() this.onToggleFavorite,
    required VoidCallback this.onShare,
    this.agency,
    this.onContact,
    super.key,
  }) : _variant = _PropertyCardVariant.feed;

  const PropertyCard.list({
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required bool Function() this.onToggleFavorite,
    this.onContact,
    super.key,
  })  : _variant = _PropertyCardVariant.list,
        onShare = null,
        agency = null;

  final Property property;
  final bool isFavorite;
  final VoidCallback onTap;

  /// Retourne `false` si l'action a été bloquée (invité non authentifié) —
  /// utilisé pour ne déclencher l'animation du double tap que si le favori
  /// a réellement changé (voir `_FeedCard`).
  final bool Function()? onToggleFavorite;
  final VoidCallback? onContact;
  final VoidCallback? onShare;
  final Agency? agency;
  final _PropertyCardVariant _variant;

  String get _priceLabel => formatPropertyPrice(property);

  String get _subtitle {
    return '${propertyTypeLabel(property.propertyType)} · ${property.city}';
  }

  @override
  Widget build(BuildContext context) {
    if (_variant == _PropertyCardVariant.feed) {
      return _FeedCard(
        property: property,
        isFavorite: isFavorite,
        onTap: onTap,
        onToggleFavorite: onToggleFavorite!,
        onShare: onShare!,
        agency: agency,
        priceLabel: _priceLabel,
        subtitle: _subtitle,
      );
    }
    return _buildList();
  }

  Widget _buildList() {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: _CoverImage(url: property.coverPhotoUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_priceLabel, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_subtitle, style: AppTypography.bodySecondary),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${property.bedrooms} ch. · ${property.surface.toStringAsFixed(0)} m²',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _FavoriteButton(
                isFavorite: isFavorite,
                onTap: () => onToggleFavorite!(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PropertyCardVariant { feed, list }

/// Formatage prix partagé par la carte et la fiche détail.
String formatPropertyPrice(Property property) {
  final formatted = property.price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
  final suffix =
      property.transactionType == TransactionType.rent ? '/mois' : '';
  return '$formatted € $suffix'.trim();
}

/// Libellé de type de bien partagé par la carte et la fiche détail.
String propertyTypeLabel(PropertyType type) {
  return switch (type) {
    PropertyType.house => 'Maison',
    PropertyType.apartment => 'Appartement',
    PropertyType.land => 'Terrain',
    PropertyType.other => 'Bien',
  };
}

/// Ombre légère commune aux boutons circulaires flottants (favori, partage,
/// retour...) — les détache visuellement de l'image derrière eux.
const List<BoxShadow> kFloatingButtonShadow = [
  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
];

/// Légère ombre portée sur le texte superposé aux photos — garde le prix et
/// les libellés lisibles quel que soit le contraste de l'image derrière.
const List<Shadow> kOverlayTextShadow = [
  Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1)),
];

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.border,
        child: const Icon(
          Icons.home_outlined,
          color: AppColors.textSecondary,
          size: 32,
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.border,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(
                  begin: 0.6,
                  end: 1.25,
                ).chain(CurveTween(curve: Curves.easeOutBack)),
                weight: 60,
              ),
              TweenSequenceItem(
                tween: Tween(
                  begin: 1.25,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOut)),
                weight: 40,
              ),
            ]).animate(animation),
            child: child,
          ),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(isFavorite),
            color: isFavorite ? AppColors.error : AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap});

  final VoidCallback onTap;

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
        child: const Icon(
          Icons.share_outlined,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

/// Carte plein écran du feed Découvrir — galerie photo/vidéo swipable
/// horizontalement, indépendante du swipe vertical qui fait défiler les
/// biens (voir `DiscoverScreen`). Conserve son état (photo affichée) tant
/// que le bien reste dans la fenêtre du `PageView` vertical grâce à
/// `AutomaticKeepAliveClientMixin`.
///
/// Deux zones de gestes bien distinctes, jamais mélangées :
/// - le média (photo/vidéo) : swipe horizontal → change de photo ;
///   double tap → like/unlike avec animation.
/// - le bloc texte (prix/titre/description) en bas : tap → ouvre la fiche.
class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onShare,
    required this.priceLabel,
    required this.subtitle,
    this.agency,
  });

  final Property property;
  final bool isFavorite;
  final VoidCallback onTap;
  final bool Function() onToggleFavorite;
  final VoidCallback onShare;
  final String priceLabel;
  final String subtitle;
  final Agency? agency;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard>
    with AutomaticKeepAliveClientMixin {
  // Espace réservé au-dessus du bloc prix/description pour que le rail
  // d'actions (favori/partager) ne le recouvre pas.
  static const double _actionRailBottomOffset = AppSpacing.xxl * 4;

  final PageController _galleryController = PageController();
  int _photoIndex = 0;
  Offset? _likeBurstPosition;
  int _likeBurstId = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _likeBurstPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    final proceeded = widget.onToggleFavorite();
    if (!proceeded) return;
    setState(() => _likeBurstId++);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final media = widget.property.media;
    final property = widget.property;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: _handleDoubleTap,
          child: _Gallery(
            media: media,
            controller: _galleryController,
            onPageChanged: (index) => setState(() => _photoIndex = index),
          ),
        ),
        // Assombrit légèrement le haut de l'image pour garder l'indicateur
        // photo et le badge agence lisibles sur un ciel clair, par exemple.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 110,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xxl * 1.5,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.55, 1],
                  colors: [
                    Colors.transparent,
                    Color(0x99000000),
                    AppColors.overlayScrim,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.priceLabel,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        shadows: kOverlayTextShadow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySecondary.copyWith(
                        color: Colors.white70,
                        shadows: kOverlayTextShadow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatsRow(property: property),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      property.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySecondary.copyWith(
                        color: Colors.white70,
                        shadows: kOverlayTextShadow,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Voir plus',
                      style: AppTypography.bodySecondary.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: kOverlayTextShadow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (media.length > 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    0,
                  ),
                  child: _PhotoIndicator(
                    count: media.length,
                    currentIndex: _photoIndex,
                  ),
                ),
              ),
            ),
          ),
        if (widget.agency != null)
          Positioned(
            left: AppSpacing.md,
            top: media.length > 1 ? AppSpacing.xxl : AppSpacing.md,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: _AgencyBadge(agency: widget.agency!),
              ),
            ),
          ),
        Positioned(
          right: AppSpacing.md,
          bottom: _actionRailBottomOffset,
          child: Column(
            children: [
              _FavoriteButton(
                isFavorite: widget.isFavorite,
                onTap: widget.onToggleFavorite,
              ),
              const SizedBox(height: AppSpacing.md),
              _ShareButton(onTap: widget.onShare),
            ],
          ),
        ),
        if (_likeBurstPosition != null)
          _LikeBurst(
            key: ValueKey(_likeBurstId),
            position: _likeBurstPosition!,
            onCompleted: () => setState(() => _likeBurstPosition = null),
          ),
      ],
    );
  }
}

/// Grand cœur qui apparaît, rebondit puis s'efface au point du double tap —
/// retrait automatique via [onCompleted] une fois l'animation terminée.
class _LikeBurst extends StatefulWidget {
  const _LikeBurst({
    required this.position,
    required this.onCompleted,
    super.key,
  });

  final Offset position;
  final VoidCallback onCompleted;

  @override
  State<_LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<_LikeBurst>
    with SingleTickerProviderStateMixin {
  static const double _iconSize = 96;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.3,
        end: 1.2,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.2,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
  ]).animate(_controller);
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 30,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - _iconSize / 2,
      top: widget.position.dy - _iconSize / 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(scale: _scale.value, child: child),
            );
          },
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: _iconSize,
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 20),
              Shadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodySecondary.copyWith(
      color: Colors.white70,
      shadows: kOverlayTextShadow,
    );
    const iconShadows = kOverlayTextShadow;
    return Row(
      children: [
        const Icon(
          Icons.square_foot,
          color: Colors.white70,
          size: 16,
          shadows: iconShadows,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('${property.surface.toStringAsFixed(0)} m²', style: style),
        const SizedBox(width: AppSpacing.md),
        const Icon(
          Icons.bed_outlined,
          color: Colors.white70,
          size: 16,
          shadows: iconShadows,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('${property.bedrooms} ch.', style: style),
        if (property.bathrooms != null) ...[
          const SizedBox(width: AppSpacing.md),
          const Icon(
            Icons.bathtub_outlined,
            color: Colors.white70,
            size: 16,
            shadows: iconShadows,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('${property.bathrooms} SdB', style: style),
        ],
      ],
    );
  }
}

class _AgencyBadge extends StatelessWidget {
  const _AgencyBadge({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: kFloatingButtonShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.white24,
            backgroundImage:
                agency.logoUrl != null ? NetworkImage(agency.logoUrl!) : null,
            child: agency.logoUrl == null
                ? const Icon(
                    Icons.apartment_rounded,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            agency.name,
            style: AppTypography.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PhotoIndicator extends StatelessWidget {
  const _PhotoIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index <= currentIndex ? Colors.white : Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Galerie photo/vidéo plein écran d'un bien — swipe horizontal indépendant
/// du swipe vertical du feed (axes de scroll opposés, désambiguïsés
/// nativement par l'arène de gestes de Flutter).
class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.media,
    required this.controller,
    required this.onPageChanged,
  });

  final List<PropertyMedia> media;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return Container(
        color: AppColors.border,
        child: const Icon(
          Icons.home_outlined,
          color: AppColors.textSecondary,
          size: 48,
        ),
      );
    }
    return PageView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      onPageChanged: onPageChanged,
      physics: const SnappyPageScrollPhysics(),
      allowImplicitScrolling: true,
      itemCount: media.length,
      itemBuilder: (context, index) => _MediaItem(
        key: ValueKey('media-${media[index].id}'),
        media: media[index],
      ),
    );
  }
}

class _MediaItem extends StatelessWidget {
  const _MediaItem({required this.media, super.key});

  final PropertyMedia media;

  @override
  Widget build(BuildContext context) {
    final url = media.thumbnailUrl ?? media.storagePath;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
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
        ),
        if (media.mediaType == MediaType.video)
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 56,
            ),
          ),
      ],
    );
  }
}
