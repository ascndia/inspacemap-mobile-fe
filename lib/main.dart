import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2
import 'place_detail_page.dart';

// --- NEW DATA CLASS ---
/// A simple class to hold our static place data
class PlaceData {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final LatLng coords;
  final int startNodeId;

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

final LatLng _demoLocation = const LatLng(
  -6.176391495779535,
  106.82157730021244,
);

final List<PlaceData> staticPlaces = [
  PlaceData(
    id: '1',
    name: "Lobby",
    description: "Lobi Museum Nasional Indonesia",
    image:
        'https://i.pinimg.com/736x/7d/bb/91/7dbb91b2af489a4264520f4efaa2b0b0.jpg',
    rating: 4.0,
    coords: const LatLng(-6.176448427892793, 106.8222330532841),
    startNodeId: 42,
  ),
  PlaceData(
    id: '2',
    name: 'Rotunda Arca',
    description: "Ruang Pameran Patung yang Menampilkan Koleksi Arca",
    image:
        'https://i.pinimg.com/736x/7d/bb/91/7dbb91b2af489a4264520f4efaa2b0b0.jpg',
    rating: 4.5,
    coords: const LatLng(-6.176444427933564, 106.82211771830656),
    startNodeId: 4,
  ),
  PlaceData(
    id: '3',
    name: 'Taman Arca',
    description: "Taman Terbuka dengan Koleksi Patung Arca",
    image:
        'https://i.pinimg.com/736x/7d/bb/91/7dbb91b2af489a4264520f4efaa2b0b0.jpg',
    rating: 4.5,
    coords: const LatLng(-6.176420428177583, 106.82182468699736),
    startNodeId: 70,
  ),
  PlaceData(
    id: '4',
    name: 'Ruang Sejarah',
    description: "Ruang Pameran yang Menampilkan Sejarah Indonesia",
    image:
        'https://i.pinimg.com/736x/7d/bb/91/7dbb91b2af489a4264520f4efaa2b0b0.jpg',
    rating: 4.5,
    coords: const LatLng(-6.176607092917656, 106.82218477352605),
    startNodeId: 11,
  ),
  PlaceData(
    id: '5',
    name: 'Ruang Peta',
    description: "Ruangan Berisi Peta-Peta Historis Indonesia",
    image:
        'https://i.pinimg.com/736x/7d/bb/91/7dbb91b2af489a4264520f4efaa2b0b0.jpg',
    rating: 4.5,
    coords: const LatLng(-6.17628776284016, 106.82219483180897),
    startNodeId: 88,
  ),

  PlaceData(
    id: '6',
    name: 'Ruang PraSejarah',
    description: "Ruang Pameran Artefak Pra-Sejarah Indonesia",
    image:
        'https://i.pinimg.com/736x/7d/bb/91/7dbb91b2af489a4264520f4efaa2b0b0.jpg',
    rating: 4.5,
    coords: const LatLng(-6.176398428399881, 106.82145051883349),
    startNodeId: 45,
  ),
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InSpaceMap Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Start with a short splash screen, then show the main map screen.
      home: const SplashScreen(),
    );
  }
}

// --- SIMPLE SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait at least 1.5 seconds then navigate to MapScreen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MapScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Placeholder logo / icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'InSpaceMap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // --- NEW STATE VARIABLES ---
  final MapController _mapController =
      MapController(); // To control map movements
  PlaceData? _selectedPlace;

  // --- NEW FUNCTION TO HANDLE SELECTION ---
  void _onPlaceSelected(PlaceData place) {
    setState(() {
      _selectedPlace = place;
    });
    // Animate the map to the selected place with higher zoom for venue view
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
                  builder: (_) => ItemsListPage(items: staticPlaces),
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
          // --- LAYER 1: THE INTERACTIVE MAP ---
          _buildMap(), // Replaced the static image
          // --- LAYER 2: THE SEARCH BAR ---
          _buildTopSearchBar(),

          // --- LAYER 3: THE BOTTOM SHEET / CARD LIST ---
          Align(
            alignment: Alignment.bottomCenter,
            child: _selectedPlace == null
                ? _buildBottomCardList()
                : LocationDetailSheet(
                    place: _selectedPlace!,
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

  // --- NEW MAP WIDGET ---
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _demoLocation, // Center on our demo location
        initialZoom: 18.0, // <-- set higher for venue-level view
        minZoom: 15.0, // <-- optional lower bound
        maxZoom: 19.0, // <-- optional upper bound
        // bounds: LatLngBounds(...),  // <-- optional: constrain to an explicit bounds
      ),
      children: [
        // Layer 1: The map tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.yourcompany.inspacemap', // Change to your app's name
        ),

        // Layer 2: The markers
        MarkerLayer(
          markers: staticPlaces.map((place) {
            return Marker(
              point: place.coords,
              width: 40,
              height: 40,
              child: Tooltip(
                message: place.name,
                child: InkWell(
                  onTap: () {
                    // --- MODIFIED ---
                    // Select place when marker is tapped
                    _onPlaceSelected(place);
                  },
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
              onTap: () {
                controller.openView();
              },
            );
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            // The suggestionsBuilder must return a list of suggestion widgets.
            // Return simple ListTiles for each place so the SearchBar can show them.
            return staticPlaces.map((place) {
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
        itemCount: staticPlaces.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (ctx, index) {
          return _buildPlaceCard(staticPlaces[index]);
        },
      ),
    );
  }

  Widget _buildPlaceCard(PlaceData place) {
    return InkWell(
      onTap: () {
        // --- MODIFIED ---
        _onPlaceSelected(place); // Use new selection function
      },
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

// --- LOCATION DETAIL WIDGET (Unchanged logic, just uses PlaceData) ---
class LocationDetailSheet extends StatelessWidget {
  final PlaceData place;
  final VoidCallback onClose;

  const LocationDetailSheet({
    super.key,
    required this.place,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(
                  child: Text(
                    "Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  _buildImagePlaceholder(place.image),
                  const SizedBox(width: 12),
                  _buildImagePlaceholder(place.image),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "${place.rating} stars",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              place.description,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.black,
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     onPressed: onClose,
            //     child: const Text(
            //       "Check Detail",
            //       style: TextStyle(fontSize: 16),
            //     ),
            //   ),
            // ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Tetap hitam
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // onPressed: () => {},
                // 1. Ganti fungsi onPressed:
                onPressed: () {
                  // Ini adalah cara Flutter berpindah halaman
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Kita membangun halaman baru dan mengirim 'place'
                      builder: (context) => PlaceDetailPage(place: place),
                    ),
                  );
                },
                // 2. Ganti teks tombol:
                child: const Text(
                  "Check Detail", // Teks baru
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String? imageUrl) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.grey[200],
          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Center(
                  child: Icon(Icons.image, color: Colors.grey[400], size: 50),
                ),
        ),
      ),
    );
  }
}

// --- NEW: Items List Page ---
class ItemsListPage extends StatelessWidget {
  final List<PlaceData> items;

  const ItemsListPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Places List')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final place = items[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                place.image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            title: Text(place.name),
            subtitle: Text(
              place.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text('${place.rating}★'),
            onTap: () {
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
