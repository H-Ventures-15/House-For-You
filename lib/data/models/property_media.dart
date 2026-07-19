enum MediaType { photo, video }

enum StorageProvider { supabase, cloudflareStream, mux }

enum MediaProcessingStatus { ready, processing, failed }

/// Média d'un bien — la structure est prête pour la vidéo dès le MVP
/// (`playbackId`, `storageProvider`, `processingStatus`) même si seules les
/// photos sont peuplées au départ (voir architecture-mvp.md, section 5).
class PropertyMedia {
  const PropertyMedia({
    required this.id,
    required this.propertyId,
    required this.mediaType,
    required this.storageProvider,
    required this.storagePath,
    this.playbackId,
    this.thumbnailUrl,
    required this.position,
    this.isCover = false,
    this.processingStatus = MediaProcessingStatus.ready,
    required this.createdAt,
  });

  final String id;
  final String propertyId;
  final MediaType mediaType;
  final StorageProvider storageProvider;
  final String storagePath;
  final String? playbackId;
  final String? thumbnailUrl;
  final int position;
  final bool isCover;
  final MediaProcessingStatus processingStatus;
  final DateTime createdAt;

  factory PropertyMedia.fromJson(Map<String, dynamic> json) {
    return PropertyMedia(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      mediaType: MediaType.values.firstWhere(
        (t) => t.name == json['media_type'],
        orElse: () => MediaType.photo,
      ),
      storageProvider: StorageProvider.values.firstWhere(
        (p) => p.name == json['storage_provider'],
        orElse: () => StorageProvider.supabase,
      ),
      storagePath: json['storage_path'] as String,
      playbackId: json['playback_id'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      position: json['position'] as int? ?? 0,
      isCover: json['is_cover'] as bool? ?? false,
      processingStatus: MediaProcessingStatus.values.firstWhere(
        (s) => s.name == json['processing_status'],
        orElse: () => MediaProcessingStatus.ready,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'media_type': mediaType.name,
        'storage_provider': storageProvider.name,
        'storage_path': storagePath,
        'playback_id': playbackId,
        'thumbnail_url': thumbnailUrl,
        'position': position,
        'is_cover': isCover,
        'processing_status': processingStatus.name,
        'created_at': createdAt.toIso8601String(),
      };
}
