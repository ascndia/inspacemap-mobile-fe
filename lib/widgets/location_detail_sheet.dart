import 'package:flutter/material.dart';
import '../models/place_data.dart';
import '../models/venue_manifest.dart';
import '../screens/place_detail_screen.dart';
import '../screens/gallery_screen.dart';

class LocationDetailSheet extends StatefulWidget {
  final PlaceData place;
  final VenueManifest venue;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  const LocationDetailSheet({
    super.key,
    required this.place,
    required this.venue,
    required this.onClose,
    this.scrollController,
  });

  @override
  State<LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<LocationDetailSheet> {
  List<dynamic> get _gallery {
    if (widget.place.id == widget.venue.venueId) {
      return widget.venue.gallery;
    } else {
      for (var floor in widget.venue.floors) {
        for (var area in floor.areas) {
          if (area.id == widget.place.id) {
            return area.gallery;
          }
        }
      }
    }
    return [];
  }

  String? get _floorName {
    if (widget.place.id == widget.venue.venueId) {
      return null; // Venue has no specific floor
    } else {
      for (var floor in widget.venue.floors) {
        for (var area in floor.areas) {
          if (area.id == widget.place.id) {
            return floor.name;
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24), // Space for close button
                      Text(
                        widget.place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.place.description.isNotEmpty
                            ? widget.place.description
                            : 'No description yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      if (_floorName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Floor: $_floorName",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaceDetailPage(
                                  venue: widget.venue,
                                  startNodeId: widget.place.startNodeId,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Check Detail",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGallerySection(),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGallerySection() {
    final displayGallery = _gallery.take(6).toList();
    final hasMore = _gallery.length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayGallery.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: displayGallery.length,
            itemBuilder: (context, index) {
              final item = displayGallery[index];
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, item.url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _showAllGallery(context),
                child: const Text('View All Gallery'),
              ),
            ),
          ],
        ] else ...[
          SizedBox(
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.grey[200],
                child: Image.network(widget.place.image, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  void _showAllGallery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GalleryScreen(gallery: _gallery)),
    );
  }
}
