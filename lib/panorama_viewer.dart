import 'dart:async';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

// Assuming your graph types are here
import 'types/graph.dart';

class VirtualTourViewer extends StatefulWidget {
  final Map<String, GraphNode> graph;
  final String initialNodeId;
  final bool debugMode;

  const VirtualTourViewer({
    super.key,
    required this.graph,
    required this.initialNodeId,
    this.debugMode = false,
  });

  @override
  State<VirtualTourViewer> createState() => _VirtualTourViewerState();
}

class _VirtualTourViewerState extends State<VirtualTourViewer> {
  late String _currentNodeId;

  // REPLACEMENT FOR CONTROLLER:
  // We track the view angles directly in the state.
  double _viewLat = 0.0;
  double _viewLon = 0.0;

  @override
  void initState() {
    super.initState();
    _currentNodeId = widget.initialNodeId;
    // Initial setup if needed
  }

  void _loadNode(String targetNodeId) {
    if (!widget.graph.containsKey(targetNodeId)) return;

    final targetNode = widget.graph[targetNodeId]!;

    setState(() {
      _currentNodeId = targetNodeId;

      // OPTIONAL: Reset view to center (0,0) when entering a new node
      // Or calculate a specific entry angle based on where you came from.
      _viewLat = 0.0;
      _viewLon = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentNode = widget.graph[_currentNodeId];

    if (currentNode == null || currentNode.panoramaUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. Convert Graph Edges to Hotspots
    List<Hotspot> hotspots = currentNode.edges.map((edge) {
      // Calculate position
      double hotspotLongitude = edge.heading - currentNode.rotationOffset;

      return Hotspot(
        latitude: 0,
        longitude: hotspotLongitude,
        width: 90.0,
        height: 90.0,
        widget: _buildHotspotWidget(edge),
      );
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          PanoramaViewer(
            // CONTROLLER REPLACEMENT:
            // Pass the variables directly. Changing them triggers rotation.
            latitude: _viewLat,
            longitude: _viewLon,

            // IMPORTANT: Sync user drag back to our variables
            onViewChanged: (longitude, latitude, tilt) {
              _viewLon = longitude;
              _viewLat = latitude;
            },

            minZoom: 0.5,
            maxZoom: 2.0,
            hotspots: hotspots,
            child: Image.network(currentNode.panoramaUrl!),
          ),

          if (widget.debugMode) _buildDebugOverlay(currentNode),
        ],
      ),
    );
  }

  Widget _buildHotspotWidget(GraphEdge edge) {
    return GestureDetector(
      onTap: () => _loadNode(edge.targetNodeId),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent, width: 2),
              boxShadow: const [
                BoxShadow(blurRadius: 5, color: Colors.black45),
              ],
            ),
            child: const Icon(
              Icons.arrow_upward,
              color: Colors.blueAccent,
              size: 28,
            ),
          ),
          // Label
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              edge.targetNodeId, // Or a readable name if you have one
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOverlay(GraphNode node) {
    return Positioned(
      top: 40,
      right: 10,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Node: ${node.id}",
                style: const TextStyle(color: Colors.yellow),
              ),
              Text(
                "Lat: ${_viewLat.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Lon: ${_viewLon.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
