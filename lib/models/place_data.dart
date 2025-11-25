import 'package:latlong2/latlong.dart';

class PlaceData {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final LatLng coords;
  final String startNodeId; // Changed to String

  const PlaceData({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.coords,
    required this.startNodeId,
  });
}
