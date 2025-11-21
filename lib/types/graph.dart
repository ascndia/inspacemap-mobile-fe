// =============================================================================
// MODEL DATA GRAPH (Sesuai JSON)
// =============================================================================
class GraphNode {
  final int id;
  final double x; // Tambahan untuk hitung jarak
  final double y; // Tambahan untuk hitung jarak
  final String panoramaFile;
  final double rotationOffset;
  final List<GraphEdge> edges;

  GraphNode({
    required this.id,
    required this.x,
    required this.y,
    required this.panoramaFile,
    this.rotationOffset = 0.0,
    required this.edges,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'],
      // Default ke 0 jika json lama belum ada koordinatnya
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      panoramaFile: json['panorama'],
      rotationOffset: (json['rotation_offset'] ?? 0.0).toDouble(),
      edges: (json['neighbors'] as List)
          .map((e) => GraphEdge.fromJson(e))
          .toList(),
    );
  }
}

class GraphEdge {
  final int targetNodeId;
  final double heading;

  GraphEdge({required this.targetNodeId, required this.heading});

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      targetNodeId: json['target'],
      heading: (json['heading'] ?? 0.0).toDouble(),
    );
  }
}
