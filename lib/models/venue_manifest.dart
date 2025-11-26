// Helper to replace localhost:9000 with localhost:9002 for dev
String? _fixUrl(String? url) {
  if (url == null) return null;
  return url.replaceAll('localhost:9000', 'localhost:9002');
}

class VenueManifest {
  final String venueId;
  final String venueName;
  final String slug;
  final String? description;
  final String? address;
  final String? city;
  final GeoPoint? coordinates;
  final String? coverImageUrl;
  final String lastUpdated;
  final String startNodeId;
  final List<FloorData> floors;
  final List<GalleryItem> gallery;

  VenueManifest({
    required this.venueId,
    required this.venueName,
    required this.slug,
    this.description,
    this.address,
    this.city,
    this.coordinates,
    this.coverImageUrl,
    required this.lastUpdated,
    required this.startNodeId,
    required this.floors,
    required this.gallery,
  });

  factory VenueManifest.fromJson(Map<String, dynamic> json) {
    return VenueManifest(
      venueId: json['venue_id'],
      venueName: json['venue_name'],
      slug: json['slug'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      coordinates: json['coordinates'] != null
          ? GeoPoint.fromJson(json['coordinates'])
          : null,
      coverImageUrl: _fixUrl(json['cover_image_url']),
      lastUpdated: json['last_updated'],
      startNodeId: json['start_node_id'],
      floors: (json['floors'] is List)
          ? (json['floors'] as List).map((f) => FloorData.fromJson(f)).toList()
          : [],
      gallery: (json['gallery'] is List)
          ? (json['gallery'] as List)
                .map((g) => GalleryItem.fromJson(g))
                .toList()
          : [],
    );
  }
}

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint({required this.latitude, required this.longitude});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}

class FloorData {
  final String id;
  final String name;
  final int levelIndex;
  final String? mapImageUrl;
  final int width;
  final int height;
  final List<NodeData> nodes;
  final List<AreaData> areas;

  FloorData({
    required this.id,
    required this.name,
    required this.levelIndex,
    this.mapImageUrl,
    required this.width,
    required this.height,
    required this.nodes,
    required this.areas,
  });

  factory FloorData.fromJson(Map<String, dynamic> json) {
    return FloorData(
      id: json['id'],
      name: json['name'],
      levelIndex: json['level_index'],
      mapImageUrl: _fixUrl(json['map_image_url']),
      width: json['width'],
      height: json['height'],
      nodes: (json['nodes'] is List)
          ? (json['nodes'] as List).map((n) => NodeData.fromJson(n)).toList()
          : [],
      areas: (json['areas'] is List)
          ? (json['areas'] as List).map((a) => AreaData.fromJson(a)).toList()
          : [],
    );
  }
}

class NodeData {
  final String id;
  final int x;
  final int y;
  final String? panoramaUrl;
  final double rotationOffset;
  final String? label;
  // Ignoring area_id and area_name as per instructions
  final List<NeighborData> neighbors;

  NodeData({
    required this.id,
    required this.x,
    required this.y,
    this.panoramaUrl,
    required this.rotationOffset,
    this.label,
    required this.neighbors,
  });

  factory NodeData.fromJson(Map<String, dynamic> json) {
    return NodeData(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      panoramaUrl: _fixUrl(json['panorama_url']),
      rotationOffset: json['rotation_offset'].toDouble(),
      label: json['label'],
      neighbors: (json['neighbors'] is List)
          ? (json['neighbors'] as List)
                .map((n) => NeighborData.fromJson(n))
                .toList()
          : [],
    );
  }
}

class NeighborData {
  final String targetNodeId;
  final double heading;
  final double distance;
  final String type;
  final bool? isActive;

  NeighborData({
    required this.targetNodeId,
    required this.heading,
    required this.distance,
    required this.type,
    this.isActive,
  });

  factory NeighborData.fromJson(Map<String, dynamic> json) {
    return NeighborData(
      targetNodeId: json['target_node_id'],
      heading: json['heading'].toDouble(),
      distance: json['distance'].toDouble(),
      type: json['type'],
      isActive: json['is_active'],
    );
  }
}

class GalleryItem {
  final String mediaId;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final bool? isFeatured;

  GalleryItem({
    required this.mediaId,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.isFeatured,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      mediaId: json['media_id'],
      url: _fixUrl(json['url']) ?? '',
      thumbnailUrl: _fixUrl(json['thumbnail_url']),
      caption: json['caption'],
      isFeatured: json['is_featured'],
    );
  }
}

class AreaData {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final double? latitude;
  final double? longitude;
  final List<BoundaryPoint> boundary;
  final String? startNodeId;
  final String? coverImageUrl;
  final List<AreaGalleryDetail> gallery;

  AreaData({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.latitude,
    this.longitude,
    required this.boundary,
    this.startNodeId,
    this.coverImageUrl,
    required this.gallery,
  });

  factory AreaData.fromJson(Map<String, dynamic> json) {
    return AreaData(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      boundary: (json['boundary'] is List)
          ? (json['boundary'] as List)
                .map((b) => BoundaryPoint.fromJson(b))
                .toList()
          : [],
      startNodeId: json['start_node_id'],
      coverImageUrl: _fixUrl(json['cover_image_url']),
      gallery: (json['gallery'] is List)
          ? (json['gallery'] as List)
                .map((g) => AreaGalleryDetail.fromJson(g))
                .toList()
          : [],
    );
  }
}

class BoundaryPoint {
  final double x;
  final double y;

  BoundaryPoint({required this.x, required this.y});

  factory BoundaryPoint.fromJson(Map<String, dynamic> json) {
    return BoundaryPoint(x: json['x'].toDouble(), y: json['y'].toDouble());
  }
}

class AreaGalleryDetail {
  final String mediaId;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final int sortOrder;

  AreaGalleryDetail({
    required this.mediaId,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    required this.sortOrder,
  });

  factory AreaGalleryDetail.fromJson(Map<String, dynamic> json) {
    return AreaGalleryDetail(
      mediaId: json['media_id'],
      url: _fixUrl(json['url']) ?? '',
      thumbnailUrl: _fixUrl(json['thumbnail_url']),
      caption: json['caption'],
      sortOrder: json['sort_order'],
    );
  }
}
