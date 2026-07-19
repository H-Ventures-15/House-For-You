import 'package:flutter/material.dart';
import '../../data/models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Un seul composant, deux variantes — garantit la cohérence visuelle entre
/// le feed Découvrir (`.feed()`, plein écran) et les listes de résultats /
/// favoris (`.list()`, compacte). Voir architecture-mvp.md, section 8.
class PropertyCard extends StatelessWidget {
  const PropertyCard.feed({
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.onContact,
    super.key,
  }) : _variant = _PropertyCardVariant.feed;

  const PropertyCard.list({
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.onContact,
    super.key,
  }) : _variant = _PropertyCardVariant.list;

  final Property property;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onContact;
  final _PropertyCardVariant _variant;

  String get _priceLabel {
    final formatted = property.price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
    final suffix =
        property.transactionType == TransactionType.rent ? '/mois' : '';
    return '$formatted € $suffix'.trim();
  }

  String get _subtitle {
    final type = switch (property.propertyType) {
      PropertyType.house => 'Maison',
      PropertyType.apartment => 'Appartement',
      PropertyType.land => 'Terrain',
      PropertyType.other => 'Bien',
    };
    return '$type · ${property.city}';
  }

  @override
  Widget build(BuildContext context) {
    return _variant == _PropertyCardVariant.feed ? _buildFeed() : _buildList();
  }

  Widget _buildFeed() {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CoverImage(url: property.coverPhotoUrl),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.overlayScrim],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _priceLabel,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$_subtitle · ${property.bedrooms} ch. · ${property.surface.toStringAsFixed(0)} m²',
                      style: AppTypography.bodySecondary.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: _FavoriteButton(
                isFavorite: isFavorite,
                onTap: onToggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
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
                onTap: onToggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PropertyCardVariant { feed, list }

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.error : AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
