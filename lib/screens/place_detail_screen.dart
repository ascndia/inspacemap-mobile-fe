import 'package:flutter/material.dart';
import '../panorama_viewer.dart';
import '../models/venue_manifest.dart';
import '../types/graph.dart';
import '../debug.dart';

class PlaceDetailPage extends StatefulWidget {
  final VenueManifest venue;
  final String startNodeId;

  const PlaceDetailPage({
    super.key,
    required this.venue,
    required this.startNodeId,
  });

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late Map<String, GraphNode> _graph;
  late String _effectiveStartNodeId;

  @override
  void initState() {
    super.initState();
    _graph = {};
    for (var floor in widget.venue.floors) {
      for (var node in floor.nodes) {
        _graph[node.id] = GraphNode.fromApi(node, floor.id);
      }
    }

    // Make graph bidirectional
    _makeGraphBidirectional();

    // Validate startNodeId
    _effectiveStartNodeId = _graph.containsKey(widget.startNodeId)
        ? widget.startNodeId
        : widget.venue.startNodeId;
    if (!_graph.containsKey(_effectiveStartNodeId)) {
      // Fallback to first node if even venue startNodeId is invalid
      _effectiveStartNodeId = _graph.keys.first;
    }
    print(
      'PlaceDetailPage: requested startNodeId: ${widget.startNodeId}, effective: $_effectiveStartNodeId',
    );
  }

  void _makeGraphBidirectional() {
    final newEdges = <String, List<GraphEdge>>{};

    for (var nodeId in _graph.keys) {
      final node = _graph[nodeId]!;
      for (var edge in node.edges) {
        final targetId = edge.targetNodeId;
        if (_graph.containsKey(targetId)) {
          final targetNode = _graph[targetId]!;
          // Check if reverse edge already exists
          final hasReverse = targetNode.edges.any(
            (e) => e.targetNodeId == nodeId,
          );
          if (!hasReverse) {
            // Add reverse edge
            final reverseHeading = (edge.heading + 180) % 360;
            final reverseEdge = GraphEdge(
              targetNodeId: nodeId,
              heading: reverseHeading,
              distance: edge.distance,
              type: edge.type,
            );
            if (!newEdges.containsKey(targetId)) {
              newEdges[targetId] = [];
            }
            newEdges[targetId]!.add(reverseEdge);
          }
        }
      }
    }

    // Apply new edges
    for (var entry in newEdges.entries) {
      final node = _graph[entry.key]!;
      _graph[entry.key] = GraphNode(
        id: node.id,
        x: node.x,
        y: node.y,
        panoramaUrl: node.panoramaUrl,
        rotationOffset: node.rotationOffset,
        edges: [...node.edges, ...entry.value],
        floorId: node.floorId,
      );
    }

    if (isDebugMode) {
      print('Made graph bidirectional. Added reverse edges where missing.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background hitam agar immersif
      body: Stack(
        children: [
          // ---- LAYER 1: ENGINE PANORAMA ----
          Positioned.fill(
            child: VirtualTourViewer(
              graph: _graph,
              initialNodeId: _effectiveStartNodeId,
              debugMode: isDebugMode,
            ),
          ),

          // ---- LAYER 2: Tombol Kembali ----
          Positioned(
            top: 50.0,
            left: 20.0,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // ---- LAYER 3: Floor Selector Minimalis (Opsional) ----
          // Karena drawer dihapus, saya taruh selector lantai melayang di bawah tengah
          // Hapus bagian ini jika benar-benar ingin bersih total
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.layers, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Lantai 1", // Bisa dibuat dinamis nanti
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
