import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final String address;
  final String hours;
  final List<String> tags;
  final String description;
  final String priceRange;
  final double lat;
  final double lng;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.address,
    required this.hours,
    required this.tags,
    required this.description,
    required this.priceRange,
    required this.lat,
    required this.lng,
  });
}

// ─────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────

const List<Restaurant> mockRestaurants = [
  Restaurant(
    id: '1',
    name: 'Hijau Segar Cafe',
    cuisine: 'Organic & Vegetarian',
    rating: 4.8,
    address: 'Jalan Besar, 35900 Tanjung Malim, Perak',
    hours: '8:00 AM - 9:00 PM',
    tags: ['Vegan', 'Organic', 'Gluten-Free'],
    description:
        'Farm-to-table organic dishes with locally sourced ingredients from Perak farms.',
    priceRange: 'RM',
    lat: 3.6847,
    lng: 101.5185,
  ),
  Restaurant(
    id: '2',
    name: 'UPSI Healthy Bowl Bar',
    cuisine: 'Health Bowls',
    rating: 4.6,
    address: 'Jalan Sultan Idris, Tanjung Malim, Perak',
    hours: '7:00 AM - 8:00 PM',
    tags: ['Bowls', 'Smoothies', 'High-Protein'],
    description:
        'Customizable nutrient-packed bowls and fresh tropical smoothies near UPSI campus.',
    priceRange: 'RM',
    lat: 3.6863,
    lng: 101.5240,
  ),
  Restaurant(
    id: '3',
    name: 'Rumah Makan Sihat',
    cuisine: 'Malay Healthy',
    rating: 4.7,
    address: 'Jalan Slim, 35900 Tanjung Malim, Perak',
    hours: '11:00 AM - 10:00 PM',
    tags: ['Malay', 'Low-Carb', 'Grilled Fish'],
    description:
        'Traditional Malay dishes prepared with less oil and fresh ikan bakar.',
    priceRange: 'RM RM',
    lat: 3.6890,
    lng: 101.5160,
  ),
  Restaurant(
    id: '4',
    name: 'Sakura Zen Sushi',
    cuisine: 'Japanese Fusion',
    rating: 4.5,
    address: 'Bandar Behrang 2020, Tanjung Malim, Perak',
    hours: '11:30 AM - 9:30 PM',
    tags: ['Japanese', 'Low-Cal', 'Omega-3'],
    description:
        'Fresh sushi rolls and creative salads with light Asian dressings.',
    priceRange: 'RM RM',
    lat: 3.6810,
    lng: 101.5290,
  ),
  Restaurant(
    id: '5',
    name: 'Protein Power Hub',
    cuisine: 'Fitness Food',
    rating: 4.4,
    address: 'Proton City, Tanjung Malim, Perak',
    hours: '6:00 AM - 8:00 PM',
    tags: ['High-Protein', 'Meal Prep', 'Keto'],
    description:
        'Macro-friendly meals designed for athletes and UPSI students.',
    priceRange: 'RM',
    lat: 3.7010,
    lng: 101.5320,
  ),
  Restaurant(
    id: '6',
    name: 'Kebun Hijau Plant-Based',
    cuisine: 'Plant-Based',
    rating: 4.9,
    address: 'Jalan Ustaz Yusuf, Tanjung Malim, Perak',
    hours: '9:00 AM - 9:00 PM',
    tags: ['Plant-Based', 'Raw', 'Sustainable'],
    description:
        '100% plant-based menu featuring local Malaysian produce and zero-waste philosophy.',
    priceRange: 'RM RM',
    lat: 3.6855,
    lng: 101.5210,
  ),
];

const List<String> tagFilters = [
  'All',
  'Vegan',
  'High-Protein',
  'Low-Carb',
  'Organic',
  'Plant-Based',
];

// ─────────────────────────────────────────
// ROUTE MODE
// ─────────────────────────────────────────

enum RouteMode { walking, driving, cycling }

extension RouteModeExt on RouteMode {
  // Each OpenStreetMap Germany server only serves ONE kind of route, so the
  // path always ends in "driving" — the server decides walk / bike / car.
  String get osrmBaseUrl {
    switch (this) {
      case RouteMode.walking:
        return 'https://routing.openstreetmap.de/routed-foot/route/v1/driving';
      case RouteMode.cycling:
        return 'https://routing.openstreetmap.de/routed-bike/route/v1/driving';
      case RouteMode.driving:
        return 'https://routing.openstreetmap.de/routed-car/route/v1/driving';
    }
  }

  // Average speeds used to estimate the time for walking and cycling.
  double get speedKmh {
    switch (this) {
      case RouteMode.walking:
        return 5;
      case RouteMode.cycling:
        return 15;
      case RouteMode.driving:
        return 40;
    }
  }

  IconData get icon {
    switch (this) {
      case RouteMode.walking:
        return Icons.directions_walk;
      case RouteMode.driving:
        return Icons.directions_car;
      case RouteMode.cycling:
        return Icons.directions_bike;
    }
  }

  String get label {
    switch (this) {
      case RouteMode.walking:
        return 'Walk';
      case RouteMode.driving:
        return 'Drive';
      case RouteMode.cycling:
        return 'Cycle';
    }
  }

  // Used in the button text: "Get Walking Directions".
  String get verb {
    switch (this) {
      case RouteMode.walking:
        return 'Walking';
      case RouteMode.driving:
        return 'Driving';
      case RouteMode.cycling:
        return 'Cycling';
    }
  }
}

// ─────────────────────────────────────────
// MAIN PAGE WIDGET
// ─────────────────────────────────────────

class PlacesScreenPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const PlacesScreenPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<PlacesScreenPage> createState() => _PlacesScreenPageState();
}

class _PlacesScreenPageState extends State<PlacesScreenPage> {
  String _activeFilter = 'All';
  String? _selectedId;

  final MapController _mapController = MapController();

  LatLng? _userLocation;
  bool _loadingLocation = false;
  String? _locationError;

  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  String? _routeInfo;
  RouteMode _routeMode = RouteMode.walking;

  @override
  void initState() {
    super.initState();
    // wait for map to render before calling move()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Real distance from user location
  String _calculateDistance(Restaurant r) {
    if (_userLocation == null) return '—';
    final distanceCalc = const Distance();
    final meters = distanceCalc(_userLocation!, LatLng(r.lat, r.lng));
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Location services are disabled.';
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationError = 'Location permission denied.';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Location permission permanently denied. Please enable in settings.';
          _loadingLocation = false;
        });
        return;
      }

      // timeLimit stops the spinner from hanging forever indoors / on emulators.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;
      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = userLatLng;
        _loadingLocation = false;
      });
      _mapController.move(userLatLng, 14);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not get location. Try again.';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _getRoute(Restaurant destination) async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enable location first to get directions.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routePoints = [];
      _routeInfo = null;
    });

    try {
      final url = '${_routeMode.osrmBaseUrl}/'
          '${_userLocation!.longitude},${_userLocation!.latitude};'
          '${destination.lng},${destination.lat}'
          '?overview=full&geometries=geojson';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // guard against empty routes array before indexing
        final routes = data['routes'] as List?;
        if (routes == null || routes.isEmpty) {
          setState(() {
            _loadingRoute = false;
            _routeInfo = 'No route found between these points.';
          });
          return;
        }

        final coords = routes[0]['geometry']['coordinates'] as List;
        // OSRM returns [lng, lat] — flip to [lat, lng] for flutter_map.
        // "as num" is safe whether the server sends 101 or 101.5.
        final points = coords
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        final distanceM = (routes[0]['distance'] as num).toDouble();
        final serverDurationS = (routes[0]['duration'] as num).toDouble();

        // Walking and cycling: estimate the time from the distance, so it is
        // realistic. Driving keeps the server's own time.
        final durationS = _routeMode == RouteMode.driving
            ? serverDurationS
            : distanceM / (_routeMode.speedKmh * 1000 / 3600);

        final distanceKm = (distanceM / 1000).toStringAsFixed(1);
        final durationMin = (durationS / 60).ceil();

        final modeLabel = _routeMode == RouteMode.walking
            ? 'walking'
            : _routeMode == RouteMode.cycling
                ? 'cycling'
                : 'by car';

        setState(() {
          _routePoints = points;
          _routeInfo = '$distanceKm km · $durationMin min $modeLabel';
          _loadingRoute = false;
        });

        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
        );
      } else {
        setState(() {
          _loadingRoute = false;
          _routeInfo = 'Could not fetch route (${response.statusCode}).';
        });
      }
    } catch (e) {
      debugPrint('Route error: $e');
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeInfo = 'Route error. Check internet connection.';
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _routeInfo = null;
    });
  }

  List<Restaurant> get _filtered {
    if (_activeFilter == 'All') return mockRestaurants;
    return mockRestaurants
        .where((r) => r.tags
            .any((t) => t.toLowerCase().contains(_activeFilter.toLowerCase())))
        .toList();
  }

  void _selectRestaurant(Restaurant r) {
    final alreadySelected = _selectedId == r.id;
    setState(() => _selectedId = alreadySelected ? null : r.id);
    // Always clear the old route, so it never points at the wrong place.
    _clearRoute();
    if (!alreadySelected) {
      _mapController.move(LatLng(r.lat, r.lng), 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A1F16) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Healthy Restaurants',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
        backgroundColor: isDark ? const Color(0xFF1B3B2B) : Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          _loadingLocation
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _userLocation != null
                        ? Icons.my_location
                        : Icons.location_searching,
                    color: _userLocation != null
                        ? Colors.lightGreenAccent
                        : Colors.white,
                  ),
                  tooltip: 'Go to my location',
                  onPressed: _getUserLocation,
                ),
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Extra bottom space so the last card is not hidden by the nav dock.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healthy Restaurants in Tanjung Malim',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover healthy dining options around Tanjung Malim, Perak.',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            if (_locationError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_locationError!,
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: _getUserLocation,
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
              ),
            if (_routeInfo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    Icon(_routeMode.icon, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _routeInfo!,
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.blue, size: 18),
                      onPressed: _clearRoute,
                      tooltip: 'Clear route',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            _buildFilterChips(isDark),
            const SizedBox(height: 16),
            _buildMap(isDark),
            const SizedBox(height: 16),
            ..._filtered.map((r) => _buildRestaurantCard(r, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tagFilters.map((tag) {
          final isActive = _activeFilter == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag),
              selected: isActive,
              onSelected: (_) => setState(() => _activeFilter = tag),
              selectedColor:
                  isDark ? const Color(0xFF2E7D32) : Colors.green[600],
              backgroundColor: isDark ? const Color(0xFF1B3B2B) : Colors.white,
              labelStyle: TextStyle(
                color: isActive
                    ? Colors.white
                    : isDark
                        ? Colors.grey[300]
                        : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(3.6847, 101.5185),
                initialZoom: 14,
              ),
              children: [
                // Standard OpenStreetMap tiles: no API key needed.
                // userAgentPackageName should match your app's applicationId
                // (android/app/build.gradle).
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smarthealthfood',
                  maxZoom: 19,
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: Colors.blue.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: _filtered.map((r) {
                    return Marker(
                      point: LatLng(r.lat, r.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _selectRestaurant(r),
                        child: Icon(
                          Icons.location_pin,
                          color: _selectedId == r.id
                              ? Colors.red
                              : Colors.green[700],
                          size: 36,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 60,
                        height: 60,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (_loadingRoute)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 8),
                      Text('Getting route...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'locate',
                tooltip: 'Go to my location',
                backgroundColor:
                    isDark ? const Color(0xFF1B3B2B) : Colors.white,
                onPressed: () {
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 14);
                  } else {
                    _getUserLocation();
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color: isDark ? Colors.lightGreenAccent : Colors.green[700],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant r, bool isDark) {
    final isSelected = _selectedId == r.id;
    final cardColor = isDark ? const Color(0xFF1B3B2B) : Colors.white;
    final borderColor = isSelected
        ? (isDark ? const Color(0xFF81C784) : Colors.green)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200);

    return GestureDetector(
      onTap: () => _selectRestaurant(r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E7D32) : Colors.green[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        r.priceRange,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.cuisine,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      _infoChip(Icons.star, '${r.rating}', Colors.amber),
                      _infoChip(
                          Icons.place, _calculateDistance(r), Colors.grey),
                      _infoChip(Icons.access_time, r.hours, Colors.grey),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 10),
                    Text(
                      r.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.address,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: r.tags
                          .map((tag) => Chip(
                                label: Text(tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFF81C784)
                                          : Colors.green[800],
                                    )),
                                backgroundColor: isDark
                                    ? const Color(0xFF0A1F16)
                                    : Colors.green[50],
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),

                    // Route mode toggle (Walk / Drive / Cycle)
                    Row(
                      children: RouteMode.values.map((mode) {
                        final isActive = _routeMode == mode;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _routeMode = mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.only(right: 6, bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green[700]
                                    : isDark
                                        ? const Color(0xFF0A1F16)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(mode.icon,
                                      size: 16,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.grey),
                                  Text(
                                    mode.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isActive ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loadingRoute ? null : () => _getRoute(r),
                        icon: _loadingRoute
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_routeMode.icon, size: 18),
                        label: Text(
                          _loadingRoute
                              ? 'Getting route...'
                              : 'Get ${_routeMode.verb} Directions',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
