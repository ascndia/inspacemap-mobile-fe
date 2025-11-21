import 'package:flutter/material.dart';
import 'main.dart'; // Pastikan PlaceData ada di sini
import 'panorama_viewer.dart';

class PlaceDetailPage extends StatefulWidget {
  final PlaceData place;

  const PlaceDetailPage({super.key, required this.place});

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  // Kita asumsikan node awal adalah ID 1 (atau sesuaikan dengan logic kamu)
  late int _initialNodeId;

  @override
  void initState() {
    super.initState();
    _initialNodeId = widget.place.startNodeId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background hitam agar immersif
      body: Stack(
        children: [
          // ---- LAYER 1: ENGINE PANORAMA ----
          Positioned.fill(
            child: PanoramaViewer(
              initialNodeId: _initialNodeId,
              debugMode: false,
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
