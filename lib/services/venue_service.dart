import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/venue_manifest.dart';

class VenueService {
  static const String baseUrl =
      'http://localhost:8081'; // Replace with actual base URL

  Future<VenueManifest> fetchVenueManifest(
    String orgSlug,
    String venueSlug,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/v1/venues/$orgSlug/$venueSlug/manifest',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return VenueManifest.fromJson(json);
    } else {
      throw Exception('Failed to load venue manifest: ${response.statusCode}');
    }
  }
}
