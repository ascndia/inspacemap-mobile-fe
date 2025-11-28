import 'dart:math';
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

  // Debug rotation offset adjustment
  double _debugRotationOffset = 0.0;
  // Debug toggle: when true, try to preserve world yaw; otherwise orient to travel direction
  bool _preserveWorldYaw = false;

  @override
  void initState() {
    super.initState();
    if (widget.graph.isEmpty) {
      _currentNodeId = ''; // No nodes
    } else if (!widget.graph.containsKey(widget.initialNodeId)) {
      _currentNodeId = widget.graph.keys.first; // Fallback to first node
    } else {
      _currentNodeId = widget.initialNodeId;
    }

    // Set initial view for the starting node
    final initialNode = widget.graph[_currentNodeId];
    if (initialNode != null) {
      _viewLat = 0.0;
      _viewLon =
          ((-initialNode.rotationOffset - _debugRotationOffset) % 360 + 360) %
          360;
    }

    // Debug: Print initial node
    if (widget.debugMode) {
      final initialNode = widget.graph[_currentNodeId];
      if (initialNode != null) {
        print(
          'Entering panorama at node: ${initialNode.id}, Floor: ${initialNode.floorId}, Panorama: ${initialNode.panoramaUrl}, Rotation Offset: ${initialNode.rotationOffset}, Initial viewLon: ${_viewLon}, Initial worldYaw: ${((_viewLon + initialNode.rotationOffset) % 360 + 360) % 360}',
        );
      } else {
        print(
          'Initial node not found: ${widget.initialNodeId}, Graph size: ${widget.graph.length}',
        );
      }
    }
  }

  void _loadNode(String targetNodeId) {
    if (!widget.graph.containsKey(targetNodeId)) return;

    final currentNode = widget.graph[_currentNodeId]!;
    final targetNode = widget.graph[targetNodeId]!;

    // Calculate direction from current to target (ground truth)
    final dx = targetNode.x - currentNode.x;
    final dy = targetNode.y - currentNode.y;
    final yaw = atan2(dy, dx) * 180 / pi;

    final targetOffset = targetNode.rotationOffset;
    var viewLongitude = 0.0;
    if (_preserveWorldYaw) {
      // Preserve absolute world yaw
      final currentOffset = currentNode.rotationOffset;
      final worldYaw = ((_viewLon + currentOffset) % 360 + 360) % 360;
      viewLongitude =
          ((worldYaw - targetOffset + _debugRotationOffset) % 360 + 360) % 360;
    } else {
      // Orient to direction of travel (yaw)
      viewLongitude =
          ((yaw - targetOffset + _debugRotationOffset) % 360 + 360) % 360;
    }

    setState(() {
      _currentNodeId = targetNodeId;
      _viewLat = 0.0;
      _viewLon = viewLongitude;
    });

    // Debug: Print navigation info
    if (widget.debugMode) {
      print(
        'Navigating to node: $targetNodeId, Floor: ${targetNode.floorId}, Panorama: ${targetNode.panoramaUrl}, Rotation Offset: ${targetNode.rotationOffset}, Yaw: $yaw, TargetOffset: $targetOffset, NewViewLon: $viewLongitude',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graph.isEmpty) {
      return const Center(child: Text('No nodes in graph'));
    }

    final currentNode = widget.graph[_currentNodeId];

    if (currentNode == null) {
      return const Center(child: Text('Node not found'));
    }

    if (currentNode.panoramaUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No panorama image for this node'),
            Text('Node ID: ${currentNode.id}'),
            Text('Floor: ${currentNode.floorId}'),
            if (widget.debugMode) ...[
              Text('Edges: ${currentNode.edges.length}'),
              ...currentNode.edges.map((e) => Text('-> ${e.targetNodeId}')),
            ],
          ],
        ),
      );
    }

    // 1. Convert Graph Edges to Hotspots (using ground-truth geometry)
    List<Hotspot> hotspots = currentNode.edges.map((edge) {
      // Get neighbor node
      final neighborNode = widget.graph[edge.targetNodeId];
      if (neighborNode == null) {
        // Fallback if neighbor not found - use edge heading
        final effectiveRotationOffset =
            currentNode.rotationOffset + _debugRotationOffset;
        final hotspotLongitude =
            ((edge.heading - effectiveRotationOffset) % 360 + 360) % 360;
        if (widget.debugMode) {
          print(
            'Neighbor node ${edge.targetNodeId} not found, using heading: ${edge.heading}, longitude=$hotspotLongitude',
          );
        }
        return Hotspot(
          latitude: 0,
          longitude: hotspotLongitude,
          width: 90.0,
          height: 90.0,
          widget: _buildHotspotWidget(edge),
        );
      }

      // Calculate relative position (ground truth)
      final dx = neighborNode.x - currentNode.x;
      final dy = neighborNode.y - currentNode.y;

      // Calculate yaw (horizontal angle)
      final yaw = (atan2(dy, dx) * 180) / pi;

      // Effective offset (rotation offset of the current node + debug)
      final effectiveRotationOffset =
          currentNode.rotationOffset + _debugRotationOffset;

      // Final viewer longitude uses yaw - offset (consistent with viewer's mapping)
      final hotspotLongitude =
          ((yaw - effectiveRotationOffset) % 360 + 360) % 360;

      if (widget.debugMode) {
        print(
          'Hotspot for ${edge.targetNodeId}: dx=$dx, dy=$dy, yaw=$yaw, hotspotLon=$hotspotLongitude, heading=${edge.heading}',
        );
      }

      return Hotspot(
        latitude: 0, // Force horizon mode
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
              _viewLon = ((longitude % 360) + 360) % 360;
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
                "Floor: ${node.floorId}",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Panorama: ${node.panoramaUrl ?? 'None'}",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Edges: ${node.edges.length}",
                style: const TextStyle(color: Colors.white),
              ),
              if (node.edges.isNotEmpty) ...[
                const Text("Edges:", style: TextStyle(color: Colors.cyan)),
                ...node.edges.map(
                  (e) => Text(
                    "  -> ${e.targetNodeId}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
              Text(
                "Lat: ${_viewLat.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Lon: ${_viewLon.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Rotation Offset: ${node.rotationOffset.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "Debug Offset: ${_debugRotationOffset.toStringAsFixed(1)}°",
                style: const TextStyle(color: Colors.white),
              ),
              Row(
                children: [
                  const Text(
                    'Preserve World Yaw',
                    style: TextStyle(color: Colors.white),
                  ),
                  Switch(
                    value: _preserveWorldYaw,
                    onChanged: (v) => setState(() => _preserveWorldYaw = v),
                    activeColor: Colors.lightGreen,
                  ),
                ],
              ),
              Slider(
                value: _debugRotationOffset,
                min: -180.0,
                max: 180.0,
                divisions: 360,
                label: _debugRotationOffset.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _debugRotationOffset = value;
                    // Update view immediately
                    _viewLon =
                        ((-node.rotationOffset - _debugRotationOffset) % 360 +
                            360) %
                        360;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
