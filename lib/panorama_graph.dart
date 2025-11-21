import 'dart:convert';
import 'package:flutter/services.dart';

class PanoramaNode {
  final int id;
  final String panorama; // filename only, e.g. lobby1.jpg
  final double rotationOffset;
  final List<PanoramaNeighbor> neighbors;

  PanoramaNode({
    required this.id,
    required this.panorama,
    required this.rotationOffset,
    required this.neighbors,
  });

  factory PanoramaNode.fromJson(Map<String, dynamic> j) {
    return PanoramaNode(
      id: j['id'] as int,
      panorama: j['panorama'] as String,
      rotationOffset: (j['rotation_offset'] as num).toDouble(),
      neighbors:
          (j['neighbors'] as List<dynamic>?)
              ?.map((n) => PanoramaNeighbor.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PanoramaNeighbor {
  final int target;
  final double heading;

  PanoramaNeighbor({required this.target, required this.heading});

  factory PanoramaNeighbor.fromJson(Map<String, dynamic> j) {
    return PanoramaNeighbor(
      target: j['target'] as int,
      heading: (j['heading'] as num).toDouble(),
    );
  }
}

class PanoramaGraph {
  final List<PanoramaNode> nodes;

  PanoramaGraph({required this.nodes});

  factory PanoramaGraph.fromJson(Map<String, dynamic> j) {
    return PanoramaGraph(
      nodes: (j['nodes'] as List<dynamic>)
          .map((n) => PanoramaNode.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }

  PanoramaNode? nodeById(int id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }
}

/// Loads `assets/graph_data.json` and returns a parsed [PanoramaGraph].
Future<PanoramaGraph> loadPanoramaGraph([
  String path = 'assets/graph_data.json',
]) async {
  final data = await rootBundle.loadString(path);
  final json = jsonDecode(data) as Map<String, dynamic>;
  return PanoramaGraph.fromJson(json);
}
