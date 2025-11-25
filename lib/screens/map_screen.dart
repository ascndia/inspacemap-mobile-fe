import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_data.dart';
import '../models/venue_manifest.dart';
import '../services/venue_service.dart';
import '../widgets/location_detail_sheet.dart';
import '../widgets/items_list_page.dart';

final LatLng _demoLocation = const LatLng(
  -6.176391495779535,
  106.82157730021244,
);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  PlaceData? _selectedPlace;
  VenueManifest? _venue;
  List<PlaceData> _places = [];

  @override
  void initState() {
    super.initState();
    _fetchVenue();
  }

  Future<void> _fetchVenue() async {
    try {
      final venue = await VenueService().fetchVenueManifest(
        'demo-org',
        'demo-venue',
      );
      setState(() {
        _venue = venue;
        _places = venue.floors
            .expand(
              (floor) => floor.nodes
                  .where((node) => node.id == venue.startNodeId)
                  .map(
                    (node) => PlaceData(
                      id: node.id,
                      name: node.label ?? 'Node ${node.id}',
                      description: 'Floor: ${floor.name}',
                      image: venue.coverImageUrl ?? '',
                      rating: 4.0,
                      coords: venue.coordinates != null
                          ? LatLng(
                              venue.coordinates!.latitude,
                              venue.coordinates!.longitude,
                            )
                          : _demoLocation,
                      startNodeId: node.id,
                    ),
                  ),
            )
            .toList();
      });
    } catch (e) {
      print('Error fetching venue: $e');
    }
  }

  void _onPlaceSelected(PlaceData place) {
    setState(() {
      _selectedPlace = place;
    });
    _mapController.move(place.coords, 18.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('InSpaceMap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ItemsListPage(items: _places),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(radius: 18, child: const Icon(Icons.person)),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildTopSearchBar(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _selectedPlace == null
                ? _buildBottomCardList()
                : LocationDetailSheet(
                    place: _selectedPlace!,
                    venue: _venue!,
                    onClose: () {
                      setState(() {
                        _selectedPlace = null;
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _demoLocation,
        initialZoom: 18.0,
        minZoom: 15.0,
        maxZoom: 19.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.inspacemap',
        ),
        MarkerLayer(
          markers: _places.map((place) {
            return Marker(
              point: place.coords,
              width: 40,
              height: 40,
              child: Tooltip(
                message: place.name,
                child: InkWell(
                  onTap: () => _onPlaceSelected(place),
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopSearchBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SearchAnchor(
          builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              controller: controller,
              hintText: "Search",
              leading: const Icon(Icons.search),
              onTap: () => controller.openView(),
            );
          },
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
                return _places.map((place) {
                  return ListTile(
                    title: Text(place.name),
                    subtitle: Text(
                      place.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      controller.closeView(place.name);
                      _onPlaceSelected(place);
                    },
                  );
                }).toList();
              },
        ),
      ),
    );
  }

  Widget _buildBottomCardList() {
    return Container(
      height: 180.0,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _places.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (ctx, index) => _buildPlaceCard(_places[index]),
      ),
    );
  }

  Widget _buildPlaceCard(PlaceData place) {
    return InkWell(
      onTap: () => _onPlaceSelected(place),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Row(
            children: [
              Image.network(
                place.image,
                height: 140,
                width: 120,
                fit: BoxFit.cover,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text("${place.rating} stars"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
