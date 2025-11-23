import 'dart:async';
import 'dart:convert'; // Untuk JSON
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io'; // <--- Tambahkan baris ini
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vec;

import 'types/graph.dart'; // Import the file where GraphNode and GraphEdge are defined

class PanoramaViewer extends StatefulWidget {
  final int initialNodeId;
  final bool debugMode;

  const PanoramaViewer({
    super.key,
    required this.initialNodeId,
    this.debugMode = false,
  });

  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer>
    with TickerProviderStateMixin {
  ui.FragmentProgram? _shaderProgram;
  Map<int, GraphNode> _graph = {};

  double _debugRotationOffset = 0.0;

  ui.Image? _currentTexture;
  ui.Image? _previousTexture;

  bool _isReady = false;
  late int _currentNodeId;

  // Camera State
  double _yaw = 0.0;
  double _pitch = 0.0;
  double _fov = 1.0;

  // Physics
  late AnimationController _inertiaController;
  Animation<Offset>? _inertiaAnimation;

  double _yawBeforeTransition = 0.0;
  double _pitchBeforeTransition = 0.0;

  // --- TRANSITION ---
  late AnimationController _transitionController;
  late Animation<double> _opacityAnimation;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentNodeId = widget.initialNodeId;

    _inertiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_applyInertia);

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Transisi cepat 400ms
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    _initResources();
  }

  @override
  void dispose() {
    _inertiaController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _initResources() async {
    try {
      _shaderProgram = await ui.FragmentProgram.fromAsset(
        'shaders/panorama.frag',
      );
      final String jsonString = await rootBundle.loadString(
        'assets/graph_data.json',
      );
      final jsonData = jsonDecode(jsonString);
      for (var n in jsonData['nodes']) {
        var node = GraphNode.fromJson(n);
        _graph[node.id] = node;
      }
      // Load awal tanpa transisi
      await _loadNode(_currentNodeId, withTransition: false);
    } catch (e) {
      debugPrint("Error Init: $e");
    }
  }

  // Future<void> _loadNode(int targetNodeId) async {
  //   if (!_graph.containsKey(targetNodeId)) return;
  //   double currentGlobalHeading = 0.0;
  //   if (_isReady && _graph.containsKey(_currentNodeId)) {
  //     final currentNode = _graph[_currentNodeId]!;
  //     double currentYawDeg = _yaw * (180.0 / pi);
  //     currentGlobalHeading =
  //         currentYawDeg + currentNode.rotationOffset + _debugRotationOffset;
  //     currentGlobalHeading = currentGlobalHeading % 360.0;
  //   }
  //   try {
  //     final targetNode = _graph[targetNodeId]!;
  //     final image = await _decodeImage(
  //       'assets/panoramas/${targetNode.panoramaFile}',
  //     );
  //     double newYawDeg = currentGlobalHeading - targetNode.rotationOffset;
  //     double newYawRad = newYawDeg * (pi / 180.0);
  //     setState(() {
  //       _currentTexture = image;
  //       _currentNodeId = targetNodeId;
  //       _isReady = true;
  //       _yaw = newYawRad;
  //       _pitch = 0.0;
  //       _inertiaController.stop();
  //     });
  //   } catch (e) {
  //     debugPrint("Error loading node: $e");
  //   }
  // }

  // Future<void> _loadNode(int targetNodeId, {bool withTransition = true}) async {
  //   // if (!_graph.containsKey(targetNodeId)) return;
  //   // if (_isReady && _graph.containsKey(_currentNodeId)) {
  //   //   final oldNode = _graph[_currentNodeId]!;
  //   //   double savedOffset =
  //   //       (oldNode.rotationOffset + _debugRotationOffset) % 360.0;
  //   //   _graph[_currentNodeId] = GraphNode(
  //   //     id: oldNode.id,
  //   //     x: oldNode.x,
  //   //     y: oldNode.y,
  //   //     panoramaFile: oldNode.panoramaFile,
  //   //     rotationOffset: savedOffset,
  //   //     edges: oldNode.edges,
  //   //   );
  //   // }
  //   double currentGlobalHeading = 0.0;
  //   if (_isReady) {
  //     double currentYawDeg = _yaw * (180.0 / pi);
  //     currentGlobalHeading =
  //         currentYawDeg + _graph[_currentNodeId]!.rotationOffset;
  //   }
  //   try {
  //     final targetNode = _graph[targetNodeId]!;
  //     final image = await _decodeImage(
  //       'assets/panoramas/${targetNode.panoramaFile}',
  //     );
  //     double newYawDeg = currentGlobalHeading - targetNode.rotationOffset;
  //     double newYawRad = newYawDeg * (pi / 180.0);
  //     _debugRotationOffset = 0.0;
  //     setState(() {
  //       _previousTexture = _currentTexture;
  //       _currentTexture = image;
  //       _currentNodeId = targetNodeId;
  //       _yaw = newYawRad;
  //       _pitch = 0.0;
  //       _inertiaController.stop();
  //       _isReady = true;
  //       _isTransitioning = withTransition && (_previousTexture != null);
  //     });

  //     if (_isTransitioning) {
  //       _transitionController.forward(from: 0.0).then((_) {
  //         setState(() {
  //           _isTransitioning = false;
  //           _previousTexture = null;
  //         });
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error loading node: $e");
  //   }
  // }

  Future<void> _loadNode(int targetNodeId, {bool withTransition = true}) async {
    if (!_graph.containsKey(targetNodeId)) return;
    if (_isReady && _graph.containsKey(_currentNodeId)) {
      final oldNode = _graph[_currentNodeId]!;
      double savedOffset =
          (oldNode.rotationOffset + _debugRotationOffset) % 360.0;
      _graph[_currentNodeId] = GraphNode(
        id: oldNode.id,
        x: oldNode.x,
        y: oldNode.y,
        panoramaFile: oldNode.panoramaFile,
        rotationOffset: savedOffset,
        edges: oldNode.edges,
      );
    }
    double currentGlobalHeading = 0.0;
    if (_isReady) {
      double currentYawDeg = _yaw * (180.0 / pi);
      currentGlobalHeading =
          currentYawDeg + _graph[_currentNodeId]!.rotationOffset;
    }
    try {
      final targetNode = _graph[targetNodeId]!;
      final image = await _decodeImage(
        'assets/panoramas/${targetNode.panoramaFile}',
      );
      double newYawDeg = currentGlobalHeading - targetNode.rotationOffset;
      double newYawRad = newYawDeg * (pi / 180.0);
      _debugRotationOffset = 0.0; // Reset slider debug
      setState(() {
        _yawBeforeTransition = _yaw;
        _pitchBeforeTransition = _pitch;

        _previousTexture = _currentTexture;
        _currentTexture = image;
        _currentNodeId = targetNodeId;
        _yaw = newYawRad;
        _pitch = 0.0;
        _inertiaController.stop();
        _isReady = true;
        _isTransitioning = withTransition && (_previousTexture != null);
      });
      if (_isTransitioning) {
        _transitionController.reset();
        _transitionController.forward().then((_) {
          setState(() {
            _isTransitioning = false;
            _previousTexture = null;
          });
        });
      }
    } catch (e) {
      debugPrint("Error loading node: $e");
    }
  }

  double _calculateScale(int targetId) {
    final current = _graph[_currentNodeId];
    final target = _graph[targetId];
    if (current == null || target == null) return 1.0;
    double dx = target.x - current.x;
    double dy = target.y - current.y;
    double distance = sqrt(dx * dx + dy * dy);
    double scale = (400 / distance).clamp(0.6, 1.2);

    return scale;
  }

  void _adjustNeighborHeading(int targetId, double delta) {
    setState(() {
      final node = _graph[_currentNodeId];
      if (node != null) {
        final index = node.edges.indexWhere((e) => e.targetNodeId == targetId);
        if (index != -1) {
          final oldEdge = node.edges[index];
          final newEdge = GraphEdge(
            targetNodeId: oldEdge.targetNodeId,
            heading: (oldEdge.heading + delta) % 360.0, // Jaga agar tetap 0-360
          );
          node.edges[index] = newEdge;
        }
      }
    });
  }

  void _printCurrentGraphJson() {
    List<Map<String, dynamic>> nodesList = [];
    var sortedKeys = _graph.keys.toList()..sort();
    for (var key in sortedKeys) {
      var node = _graph[key]!;
      double saveOffset = node.rotationOffset;
      if (node.id == _currentNodeId) {
        saveOffset = (saveOffset + _debugRotationOffset) % 360.0;
      }
      nodesList.add({
        "id": node.id,
        "panorama": node.panoramaFile,
        "rotation_offset": double.parse(
          saveOffset.toStringAsFixed(1),
        ), // Rounding
        "neighbors": node.edges
            .map(
              (e) => {
                "target": e.targetNodeId,
                "heading": double.parse(
                  e.heading.toStringAsFixed(1),
                ), // Rounding
              },
            )
            .toList(),
      });
    }

    var finalJson = {"nodes": nodesList};
    debugPrint("=== COPY JSON DI BAWAH INI ===");
    debugPrint(jsonEncode(finalJson));
    debugPrint("==============================");
  }

  Future<ui.Image> _decodeImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(
      data.buffer.asUint8List(),
      (img) => completer.complete(img),
    );
    return completer.future;
  }

  void _applyInertia() {
    if (_inertiaAnimation == null) return;
    setState(() {
      _yaw -= _inertiaAnimation!.value.dx * 0.0005 * _fov;
      _pitch -= _inertiaAnimation!.value.dy * 0.0005 * _fov;
      _pitch = _pitch.clamp(-1.5, 1.5);
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _inertiaController.stop();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _yaw -= details.focalPointDelta.dx * 0.0010 * _fov;
      _pitch -= details.focalPointDelta.dy * 0.0010 * _fov;
      _pitch = _pitch.clamp(-1.5, 1.5);

      // Zoom
      if (details.scale != 1.0) {
        double newFov = _fov / (details.scale * 0.1 + 0.9);
        _fov = newFov.clamp(0.4, 1.2);
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance > 50) {
      _inertiaAnimation =
          Tween<Offset>(begin: velocity * 0.016, end: Offset.zero).animate(
            CurvedAnimation(
              parent: _inertiaController,
              curve: Curves.decelerate,
            ),
          );
      _inertiaController.reset();
      _inertiaController.forward();
    }
  }

  Offset? _projectToScreen(double heading, Size size, bool isMobile) {
    double finalHeading =
        heading -
        (_graph[_currentNodeId]?.rotationOffset ?? 0.0) -
        _debugRotationOffset;
    double rad = finalHeading * (pi / 180.0);
    vec.Vector3 worldTarget = vec.Vector3(sin(rad), 0, -cos(rad));
    final matYaw = vec.Matrix4.rotationY(-_yaw);
    final matPitch = vec.Matrix4.rotationX(_pitch);
    final cameraModelMatrix = matYaw * matPitch;
    final viewMatrix = vec.Matrix4.copy(cameraModelMatrix)..invert();
    vec.Vector3 camSpace = viewMatrix.transform3(worldTarget);
    if (camSpace.z > -0.1) return null;
    double aspect = size.width / size.height;
    double ndcX = camSpace.x / (-camSpace.z * _fov * aspect);
    double ndcY = camSpace.y / (camSpace.z * _fov);
    if (ndcX < -1.5 || ndcX > 1.5 || ndcY < -1.5 || ndcY > 1.5) return null;
    double screenX = (ndcX + 1.0) * 0.5 * size.width;
    double screenY = (ndcY + 1.0) * 0.5 * size.height;
    if (isMobile) {
      screenY = size.height - screenY;
    }
    return Offset(screenX, screenY);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _currentTexture == null || _shaderProgram == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final currentNode = _graph[_currentNodeId];
        final bool isMobileApp = Platform.isAndroid || Platform.isIOS;
        List<Widget> hotspots = [];
        if (!_isTransitioning && currentNode != null) {
          for (var edge in currentNode.edges) {
            Offset? pos = _projectToScreen(edge.heading, size, isMobileApp);

            if (pos != null) {
              double distScale = _calculateScale(edge.targetNodeId);

              hotspots.add(
                Positioned(
                  left: pos.dx - 30, // Hitbox 60x60
                  top: pos.dy - 30,
                  child: _buildScalableHotspot(edge, distScale),
                ),
              );
            }
          }
        }

        final pixelRatio = MediaQuery.of(context).devicePixelRatio;

        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Stack(
            children: [
              // LAYER 1: GAMBAR LAMA (Hanya muncul saat transisi)
              if (_previousTexture != null)
                CustomPaint(
                  size: Size.infinite,
                  painter: _PanoramaPainter(
                    shader: _shaderProgram!.fragmentShader(),
                    texture: _previousTexture!,
                    yaw: _yawBeforeTransition,
                    pitch: _pitchBeforeTransition,
                    fov: _fov,
                    pixelRatio: pixelRatio,
                    isMobile: isMobileApp,
                  ),
                ),

              // LAYER 2: GAMBAR BARU (Fade In)
              AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _isTransitioning ? _opacityAnimation.value : 1.0,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PanoramaPainter(
                        shader: _shaderProgram!.fragmentShader(),
                        texture: _currentTexture!,
                        yaw: _yaw,
                        pitch: _pitch,
                        fov: _fov,
                        pixelRatio: pixelRatio,
                        isMobile: isMobileApp,
                      ),
                    ),
                  );
                },
              ),

              // LAYER 3: HOTSPOTS
              ...hotspots,

              // LAYER 4: DEBUG PANEL
              if (widget.debugMode && currentNode != null)
                _buildDebugOverlay(currentNode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScalableHotspot(GraphEdge edge, double scale) {
    return GestureDetector(
      onTap: () => _loadNode(edge.targetNodeId),
      // Hitbox Luar: 60x60 Transparan
      child: Container(
        width: 60,
        height: 60,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: scale, // Skala Visual saja
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_double_arrow_up,
                  color: Colors.blueAccent,
                  size: 28,
                ),
              ),
              if (widget.debugMode)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: Colors.black87,
                  child: Text(
                    "ID: ${edge.targetNodeId}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugOverlay(GraphNode node) {
    return Positioned(
      top: 50,
      right: 10,
      width: 260, // Lebar panel ditambah dikit
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.yellow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "NODE ${node.id}",
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _printCurrentGraphJson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 24),
                  ),
                  child: const Text(
                    "PRINT JSON",
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "North Calibration (Offset)",
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      min: 0.0,
                      max: 360.0,
                      value: _debugRotationOffset,
                      activeColor: Colors.yellow,
                      onChanged: (val) =>
                          setState(() => _debugRotationOffset = val),
                    ),
                  ),
                ),
                Text(
                  "${_debugRotationOffset.toStringAsFixed(0)}°",
                  style: const TextStyle(color: Colors.yellow, fontSize: 12),
                ),
              ],
            ),

            const Divider(color: Colors.grey),
            const Text(
              "Neighbors Tuning (Heading)",
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: node.edges.map((edge) {
                  return Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // Info Baris Atas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "To: ${edge.targetNodeId}",
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${edge.heading.toStringAsFixed(1)}°",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _tuneBtn(edge.targetNodeId, -10, "<<"),
                            _tuneBtn(edge.targetNodeId, -1, "<"),
                            const Icon(
                              Icons.commit,
                              color: Colors.grey,
                              size: 12,
                            ), // Separator
                            _tuneBtn(edge.targetNodeId, 1, ">"),
                            _tuneBtn(edge.targetNodeId, 10, ">>"),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuneBtn(int targetId, double delta, String label) {
    return InkWell(
      onTap: () => _adjustNeighborHeading(targetId, delta),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PAINTER (BRIDGE KE GPU)
// =============================================================================

class _PanoramaPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image texture;
  final double yaw;
  final double pitch;
  final double fov;
  final double pixelRatio;
  final bool isMobile;
  _PanoramaPainter({
    required this.shader,
    required this.texture,
    required this.yaw,
    required this.pitch,
    required this.fov,
    required this.pixelRatio,
    required this.isMobile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final matY = vec.Matrix4.rotationY(-yaw);
    final matX = vec.Matrix4.rotationX(pitch);
    final matrix = matY * matX;
    shader.setFloat(0, size.width * pixelRatio); // <--- FIX DISTORSI
    shader.setFloat(1, size.height * pixelRatio);
    shader.setImageSampler(0, texture);
    for (int i = 0; i < 16; i++) {
      shader.setFloat(2 + i, matrix.storage[i]);
    }
    shader.setFloat(18, fov);
    shader.setFloat(19, isMobile ? 1.0 : 0.0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _PanoramaPainter old) {
    return old.yaw != yaw ||
        old.pitch != pitch ||
        old.fov != fov ||
        old.texture != texture ||
        old.pixelRatio != pixelRatio ||
        old.isMobile != isMobile;
  }
}
