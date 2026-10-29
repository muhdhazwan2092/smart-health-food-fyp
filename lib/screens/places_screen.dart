import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Green palette shared with the Scan screen.
class PlacesPalette {
  static const green =
      Color(0xFF2E7D32); // buttons / fills with white text (AA)
  static const appBar = Color(0xFF388E3C); // green[700], same as Scan app bar
  static const appBarDark = Color(0xFF1B3B2B);
  static const greenLight = Color(0xFF66BB6A); // accent on dark backgrounds
  static const darkBg = Color(0xFF0F0F0F);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkMuted = Color(0xFFBDBDBD); // grey[400]
  static const lightBg = Color(0xFFEAF7EA);
  static const lightMuted = Color(0xFF616161); // grey[700]
  static const greenTint = Color(0x1F2E7D32); // green @ 12%
}

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
  final String imageUrl;
  final List<String> foodImageUrls;
  final String halalStatus;

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
    this.imageUrl = '',
    this.foodImageUrls = const [],
    this.halalStatus = 'Unknown',
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
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
    foodImageUrls: [
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=700&q=80',
    ],
    halalStatus: 'Unknown',
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
    imageUrl:
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80',
    foodImageUrls: [
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=700&q=80',
    ],
    halalStatus: 'Unknown',
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
    imageUrl:
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
    foodImageUrls: [
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=700&q=80',
    ],
    halalStatus: 'Unknown',
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
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
    foodImageUrls: [
      'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=700&q=80',
    ],
    halalStatus: 'Unknown',
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
    imageUrl:
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800&q=80',
    foodImageUrls: [
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=700&q=80',
    ],
    halalStatus: 'Unknown',
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
    imageUrl:
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
    foodImageUrls: [
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=700&q=80',
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=700&q=80',
    ],
    halalStatus: 'Unknown',
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
  String get osrmProfile {
    switch (this) {
      case RouteMode.walking:
        return 'walking';
      case RouteMode.driving:
        return 'driving';
      case RouteMode.cycling:
        return 'cycling';
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
  RouteMode _routeMode = RouteMode.driving;

  @override
  void initState() {
    super.initState();
    // FIX: wait for map to render before calling move()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose(); // FIX: dispose MapController
    super.dispose();
  }

  // FIX: real distance from user location instead of mock strings
  String _calculateDistance(Restaurant r) {
    if (_userLocation == null) return '—';
    const distanceCalc = Distance();
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
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled.';
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied.';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission permanently denied. Please enable in settings.';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
    // The public OSRM demo server routes by car. Do not mislabel a driving
    // route as walking or cycling. Use a dedicated multimodal routing backend
    // before enabling those route requests.
    if (_routeMode != RouteMode.driving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          backgroundColor: PlacesPalette.green,
          content: Text(
            'Walking and cycling routes need a compatible routing service. Please choose Drive for now.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable location first to get directions.',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFFC2410C),
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
      // FIX: https:// instead of http:// — cleartext blocked on Android
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${_userLocation!.longitude},${_userLocation!.latitude};'
          '${destination.lng},${destination.lat}'
          '?overview=full&geometries=geojson';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // FIX: guard against empty routes array before indexing
        final routes = data['routes'] as List?;
        if (routes == null || routes.isEmpty) {
          setState(() {
            _loadingRoute = false;
            _routeInfo = 'No route found between these points.';
          });
          return;
        }

        final coords = routes[0]['geometry']['coordinates'] as List;
        // OSRM returns [lng, lat] — flip to [lat, lng] for flutter_map
        final points =
            coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();

        final distanceM = (routes[0]['distance'] as num).toDouble();
        final durationS = (routes[0]['duration'] as num).toDouble();
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

    if (const ['Halal', 'Non-Halal', 'Unknown'].contains(_activeFilter)) {
      return mockRestaurants
          .where((r) => r.halalStatus == _activeFilter)
          .toList();
    }

    return mockRestaurants
        .where((r) => r.tags
            .any((t) => t.toLowerCase().contains(_activeFilter.toLowerCase())))
        .toList();
  }

  void _selectRestaurant(Restaurant r) {
    final alreadySelected = _selectedId == r.id;
    setState(() => _selectedId = alreadySelected ? null : r.id);
    if (alreadySelected) {
      _clearRoute();
    } else {
      _mapController.move(LatLng(r.lat, r.lng), 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final accent = isDark ? PlacesPalette.greenLight : PlacesPalette.green;
    final warn = isDark ? Colors.orange : Colors.orange.shade900;

    return Scaffold(
      backgroundColor: isDark ? PlacesPalette.darkBg : PlacesPalette.lightBg,
      appBar: AppBar(
        title: Text(
          'Healthy Restaurants',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
        ),
        backgroundColor:
            isDark ? PlacesPalette.appBarDark : PlacesPalette.appBar,
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
                    color: Colors.white,
                  ),
                  tooltip: 'Go to my location',
                  onPressed: _getUserLocation,
                ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: widget.onToggleDarkMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
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
                  color: isDark
                      ? PlacesPalette.darkMuted
                      : PlacesPalette.lightMuted),
            ),
            const SizedBox(height: 12),
            if (_locationError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  // FIX: withOpacity -> withValues
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: warn),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: warn, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_locationError!,
                          style: TextStyle(color: warn, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: _getUserLocation,
                      child: Text('Retry', style: TextStyle(color: warn)),
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
                  color: PlacesPalette.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent),
                ),
                child: Row(
                  children: [
                    Icon(_routeMode.icon, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _routeInfo!,
                        style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: accent, size: 18),
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
              selectedColor: PlacesPalette.green,
              backgroundColor:
                  isDark ? PlacesPalette.darkSurface : Colors.white,
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
                        // FIX: withOpacity -> withValues
                        color: PlacesPalette.green,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
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
                              : PlacesPalette.green,
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
                                color: PlacesPalette.greenLight,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    // FIX: withOpacity -> withValues
                                    color: PlacesPalette.greenLight
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: PlacesPalette.green,
                                ),
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
                // FIX: withOpacity -> withValues
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
                backgroundColor:
                    isDark ? PlacesPalette.darkSurface : Colors.white,
                onPressed: () {
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 14);
                  } else {
                    _getUserLocation();
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color:
                      isDark ? PlacesPalette.greenLight : PlacesPalette.green,
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
    final cardColor = isDark ? PlacesPalette.darkSurface : Colors.white;
    final borderColor = isSelected
        ? (isDark ? PlacesPalette.greenLight : PlacesPalette.green)
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
              // FIX: withOpacity -> withValues
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 104,
                height: 92,
                child: Image.network(
                  r.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: PlacesPalette.green.withValues(alpha: 0.15),
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant,
                        color: PlacesPalette.green, size: 30),
                  ),
                ),
              ),
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
                          color: isDark
                              ? PlacesPalette.darkMuted
                              : PlacesPalette.lightMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.cuisine,
                    style: TextStyle(
                      color: isDark
                          ? PlacesPalette.darkMuted
                          : PlacesPalette.lightMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: r.halalStatus == 'Halal'
                          ? Colors.green.withValues(alpha: 0.14)
                          : r.halalStatus == 'Non-Halal'
                              ? Colors.red.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.halalStatus == 'Unknown'
                          ? 'Halal status unverified'
                          : r.halalStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: r.halalStatus == 'Halal'
                            ? (isDark
                                ? Colors.green.shade300
                                : Colors.green.shade800)
                            : r.halalStatus == 'Non-Halal'
                                ? (isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade800)
                                : (isDark
                                    ? PlacesPalette.darkMuted
                                    : PlacesPalette.lightMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      _infoChip(Icons.star, '${r.rating}', Colors.amber),
                      // FIX: real distance calculated from user location
                      _infoChip(Icons.place, _calculateDistance(r),
                          Colors.grey.shade600),
                      _infoChip(
                          Icons.access_time, r.hours, Colors.grey.shade600),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 10),
                    Text(
                      r.description,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? PlacesPalette.darkMuted : Colors.black87,
                      ),
                    ),
                    if (r.foodImageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Food photos',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: r.foodImageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              r.foodImageUrls[index],
                              width: 145,
                              height: 112,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 145,
                                height: 112,
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                child: const Icon(Icons.fastfood, size: 30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      r.address,
                      style: TextStyle(
                        color: isDark
                            ? PlacesPalette.darkMuted
                            : PlacesPalette.lightMuted,
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
                                          ? PlacesPalette.greenLight
                                          : PlacesPalette.green,
                                    )),
                                backgroundColor: PlacesPalette.greenTint,
                                side: BorderSide.none,
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
                            onTap: () {
                              if (_routeMode == mode) return;
                              setState(() {
                                _routeMode = mode;
                                _routePoints = [];
                                _routeInfo = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.only(right: 6, bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? PlacesPalette.green
                                    : PlacesPalette.greenTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(mode.icon,
                                      size: 16,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark
                                              ? PlacesPalette.darkMuted
                                              : PlacesPalette.lightMuted)),
                                  Text(
                                    mode.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark
                                              ? PlacesPalette.darkMuted
                                              : PlacesPalette.lightMuted),
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
                        label: Text(_loadingRoute
                            ? 'Getting route...'
                            : _routeMode == RouteMode.walking
                                ? 'Get Walking Directions'
                                : _routeMode == RouteMode.driving
                                    ? 'Get Driving Directions'
                                    : 'Get Cycling Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PlacesPalette.green,
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
