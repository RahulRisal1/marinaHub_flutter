import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/screens/explore/detailMarinas.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class BoatMapScreen extends StatefulWidget {
  const BoatMapScreen({super.key});

  @override
  State<BoatMapScreen> createState() => _BoatMapScreenState();
}

class _BoatMapScreenState extends State<BoatMapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  geo.Position? userPosition;
  List marinas = [];
  bool loading = true;
  Map? selectedMarina;

  @override
  void initState() {
    super.initState();
    initLocationAndMarinas();
  }

  Future<void> initLocationAndMarinas() async {
    await requestLocation();
    await loadMarinas();
  }

  Future<void> requestLocation() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return;
    }
    if (permission == geo.LocationPermission.deniedForever) return;

    final pos = await geo.Geolocator.getCurrentPosition();
    setState(() => userPosition = pos);
    _flyToUser(pos);
  }

  void _flyToUser(geo.Position pos) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(pos.longitude, pos.latitude)),
        zoom: 11,
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> loadMarinas() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      List fetched = res.data['marinas'];

      if (userPosition != null) {
        fetched.sort((a, b) {
          final distA = geo.Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            (a['latitude'] ?? 0).toDouble(),
            (a['longitude'] ?? 0).toDouble(),
          );
          final distB = geo.Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            (b['latitude'] ?? 0).toDouble(),
            (b['longitude'] ?? 0).toDouble(),
          );
          return distA.compareTo(distB);
        });
      }

      setState(() => marinas = fetched);
      _addMarinaMarkers();
    } catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _addMarinaMarkers() async {
    if (_annotationManager == null) return;

    await _annotationManager!.deleteAll();

    for (final marina in marinas) {
      final lat = marina['latitude'];
      final lng = marina['longitude'];
      if (lat == null || lng == null) continue;

      await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              (lng as num).toDouble(),
              (lat as num).toDouble(),
            ),
          ),
          textField: marina['name'] ?? '',
          textSize: 13,
          textColor: 0xFFC9A84C,
          textHaloColor: 0xFF0D1B2A,
          textHaloWidth: 1.5,
          textOffset: [0, 1.8],
          iconSize: 1.2,
        ),
      );
    }
  }

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;

    _annotationManager = await map.annotations.createPointAnnotationManager();

    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: 0xFFC9A84C,
      ),
    );

    if (userPosition != null) {
      _flyToUser(userPosition!);
    }

    if (marinas.isNotEmpty) {
      _addMarinaMarkers();
    }
  }

  Future<void> _openInMaps(Map marina) async {
    final lat = (marina['latitude'] as num?)?.toDouble();
    final lng = (marina['longitude'] as num?)?.toDouble();
    final name = Uri.encodeComponent(marina['name'] ?? 'Marina');

    if (lat == null || lng == null) return;

    final Uri url;
    if (Platform.isIOS) {
      url = Uri.parse('maps://?daddr=$lat,$lng&q=$name');
    } else {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving',
      );
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: open Google Maps in browser on both platforms
      final fallback = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  String getDistance(Map marina) {
    if (userPosition == null) return marina['location'] ?? '';
    final meters = geo.Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      (marina['latitude'] ?? 0).toDouble(),
      (marina['longitude'] ?? 0).toDouble(),
    );
    final distStr = meters < 1000
        ? '${meters.toStringAsFixed(0)} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
    return '$distStr away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // MAP
          MapWidget(
            key: const ValueKey('mapbox_map'),
            styleUri: MapboxStyles.DARK,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  userPosition?.longitude ?? 10.7522,
                  userPosition?.latitude ?? 59.9139,
                ),
              ),
              zoom: 10,
            ),
            onMapCreated: _onMapCreated,
            onTapListener: (coord) {
              setState(() => selectedMarina = null);
            },
          ),

          // TOP SEARCH BAR
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131C2B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF243044)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFC9A84C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search marinas...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Color(0xFFC9A84C),
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // MARINA COUNT BADGE
          if (!loading && marinas.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 72,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${marinas.length} marinas nearby',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // SELECTED MARINA CARD
          if (selectedMarina != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailMarinas(marina: selectedMarina!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2232),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF243044)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/portImages/port.jpg',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedMarina!['name'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white38,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  getDistance(selectedMarina!),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.anchor,
                                  color: Colors.white38,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${selectedMarina!['totalBerths'] ?? 0} berths',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  '750 NOK/night',
                                  style: TextStyle(
                                    color: Color(0xFFC9A84C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openInMaps(selectedMarina!),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A84C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white38,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // BOTTOM HORIZONTAL MARINA LIST
          if (selectedMarina == null && !loading && marinas.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: marinas.length,
                  itemBuilder: (context, index) {
                    final marina = marinas[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedMarina = marina);
                        final lat = marina['latitude'];
                        final lng = marina['longitude'];
                        if (lat != null && lng != null) {
                          _mapboxMap?.flyTo(
                            CameraOptions(
                              center: Point(
                                coordinates: Position(
                                  (lng as num).toDouble(),
                                  (lat as num).toDouble(),
                                ),
                              ),
                              zoom: 13,
                            ),
                            MapAnimationOptions(duration: 800),
                          );
                        }
                      },
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2232),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF243044)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                index % 2 == 0
                                    ? 'assets/images/portImages/port.jpg'
                                    : 'assets/images/portImages/port2.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    marina['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    getDistance(marina),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // MY LOCATION BUTTON
          Positioned(
            bottom: loading ? 32 : 120,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: const Color(0xFF1A2232),
              elevation: 4,
              onPressed: () async {
                await requestLocation();
                if (userPosition != null) {
                  _flyToUser(userPosition!);
                }
              },
              child: const Icon(
                Icons.my_location,
                color: Color(0xFFC9A84C),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
