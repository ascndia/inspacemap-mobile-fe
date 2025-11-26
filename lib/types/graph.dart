// =============================================================================
// MODEL DATA GRAPH (Updated for API)
// =============================================================================
import '../models/venue_manifest.dart';

class GraphNode {
  final String id; // Changed to String to match API
  final double x; // Tambahan untuk hitung jarak
  final double y; // Tambahan untuk hitung jarak
  final String? panoramaUrl; // Changed from panoramaFile to URL, optional
  final double rotationOffset;
  final List<GraphEdge> edges;
  final String floorId; // Add floor reference

  GraphNode({
    required this.id,
    required this.x,
    required this.y,
    this.panoramaUrl,
    this.rotationOffset = 0.0,
    required this.edges,
    required this.floorId,
  });

  factory GraphNode.fromApi(NodeData node, String floorId) {
    return GraphNode(
      id: node.id,
      x: node.x.toDouble(),
      y: node.y.toDouble(),
      panoramaUrl: node.panoramaUrl,
      rotationOffset: node.rotationOffset,
      edges: node.neighbors
          .where(
            (n) => n.isActive ?? true,
          ) // Include if isActive is true or null
          .fold<Map<String, NeighborData>>(
            {},
            (map, n) => map..[n.targetNodeId] = n,
          )
          .values
          .map((n) => GraphEdge.fromApi(n))
          .toList(),
      floorId: floorId,
    );
  }

  // Keep old fromJson for backward compatibility if needed
  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'].toString(),
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      panoramaUrl: json['panorama'],
      rotationOffset: (json['rotation_offset'] ?? 0.0).toDouble(),
      edges: (json['neighbors'] as List)
          .map((e) => GraphEdge.fromJson(e))
          .toList(),
      floorId: '', // Default empty
    );
  }
}

class GraphEdge {
  final String targetNodeId; // Changed to String
  final double heading;
  final double distance; // Add distance from API
  final String type; // Add type (walk, stairs, etc.)

  GraphEdge({
    required this.targetNodeId,
    required this.heading,
    required this.distance,
    required this.type,
  });

  factory GraphEdge.fromApi(NeighborData neighbor) {
    return GraphEdge(
      targetNodeId: neighbor.targetNodeId,
      heading: neighbor.heading,
      distance: neighbor.distance,
      type: neighbor.type,
    );
  }

  // Keep old fromJson for backward compatibility
  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      targetNodeId: json['target'].toString(),
      heading: (json['heading'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'walk',
    );
  }
}
