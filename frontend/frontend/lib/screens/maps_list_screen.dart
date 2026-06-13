import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';

const Color kPrimaryBlue = Color(0xFF141E34);
const Color kPrimaryGreen = Color(0xFF1A1A2E);
const Color kAccentGold = Color(0xFFF0B63B);
const Color kBackgroundLight = Color(0xFFF6F7FB);
const Color kCardBg = Color(0xFFFFFFFF);

class MapsListScreen extends StatefulWidget {
  const MapsListScreen({super.key});

  @override
  State<MapsListScreen> createState() => _MapsListScreenState();
}

class _MapsListScreenState extends State<MapsListScreen> {
  late Future<List<Tailor>> _tailorsFuture;
  final MapController _mapController = MapController();
  List<Tailor> _tailors = [];
  Tailor? _selectedTailor;
  LatLng? _userLocation;
  int _selectedViewIndex = 1;
  String _selectedFilter = 'Semua';

  static const List<String> _viewLabels = ['Daftar', 'Peta'];
  static const List<String> _filters = ['Semua', 'Terdekat', 'Rating Tinggi', 'Harga Rendah'];

  @override
  void initState() {
    super.initState();
    _tailorsFuture = ApiService.fetchTailors();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      setState(() {
        _userLocation = const LatLng(-6.9175, 107.6191);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _userLocation = const LatLng(-6.9175, 107.6191);
      });
    }
  }

  void _centerOnTailor(Tailor tailor) {
    setState(() => _selectedTailor = tailor);
    _mapController.move(
      LatLng(tailor.locationLat, tailor.locationLng),
      15,
    );
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15);
    }
  }

  List<Tailor> get _filteredTailors {
    final list = [..._tailors];
    if (_selectedFilter == 'Terdekat') {
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_selectedFilter == 'Rating Tinggi') {
      list.sort((b, a) => a.rating.compareTo(b.rating));
    } else if (_selectedFilter == 'Harga Rendah') {
      list.sort((a, b) => a.estimatedPrice.compareTo(b.estimatedPrice));
    }
    return list;
  }

  void _openTailorDetail(Tailor tailor) {
    Navigator.pushNamed(context, '/tailor-detail', arguments: tailor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Penjahit'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: FutureBuilder<List<Tailor>>(
        future: _tailorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryGreen),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat penjahit: ${snapshot.error}'),
            );
          }
          _tailors = snapshot.data ?? [];
          if (_tailors.isEmpty) {
            return const Center(child: Text('Tidak ada penjahit tersedia'));
          }

          final defaultCenter = const LatLng(-6.9175, 107.6191);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: defaultCenter,
                  zoom: 13.5,
                  maxZoom: 18,
                  minZoom: 10,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tailorix',
                  ),
                  MarkerLayer(
                    markers: [
                      if (_userLocation != null)
                        Marker(
                          width: 50,
                          height: 50,
                          point: _userLocation!,
                          builder: (context) => Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.blue,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ..._tailors.map(
                        (tailor) => Marker(
                          width: 60,
                          height: 70,
                          point: LatLng(tailor.locationLat, tailor.locationLng),
                          builder: (context) => GestureDetector(
                            onTap: () => _centerOnTailor(tailor),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: tailor == _selectedTailor
                                            ? kPrimaryGreen.withValues(alpha: 0.6)
                                            : Colors.black.withValues(alpha: 0.2),
                                        blurRadius: tailor == _selectedTailor ? 12 : 6,
                                        spreadRadius: tailor == _selectedTailor ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: tailor == _selectedTailor
                                        ? kPrimaryGreen
                                        : kPrimaryGreen.withValues(alpha: 0.8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          tailor.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        if (tailor == _selectedTailor)
                                          const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (tailor == _selectedTailor)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kPrimaryGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      tailor.shopName.split(' ').first,
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
                      ),
                    ],
                  ),
                ],
              ),

              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryGreen,
                  elevation: 4,
                  onPressed: _centerOnUserLocation,
                  tooltip: 'Lokasi Saya',
                  child: const Icon(Icons.my_location),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _selectedTailor == null
                    ? _buildTailorListSheet()
                    : _buildTailorDetailSheet(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTailorListSheet() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Daftar Penjahit Terdekat',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _tailors.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final tailor = _tailors[index];
                return GestureDetector(
                  onTap: () => _centerOnTailor(tailor),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tailor.shopName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${tailor.rating}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${tailor.reviewsCount})',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tailor.isAvailable
                                ? kPrimaryGreen.withValues(alpha: 0.2)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tailor.isAvailable ? 'Buka' : 'Tutup',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tailor.isAvailable ? kPrimaryGreen : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTailorDetailSheet() {
    final tailor = _selectedTailor!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimaryGreen,
                    child: Text(
                      tailor.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tailor.shopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('${tailor.rating} (${tailor.reviewsCount} review)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedTailor = null),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tailor.city,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.directions, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${tailor.distanceKm.toStringAsFixed(1)} km dari lokasi Anda',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        tailor.isAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 16,
                        color: tailor.isAvailable
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tailor.isAvailable ? 'Sedang Buka' : 'Sedang Tutup',
                        style: TextStyle(
                          color: tailor.isAvailable
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tailor.description,
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tailor.specializations
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryGreen.withValues(alpha: 0.15),
                              border: Border.all(
                                color: kPrimaryGreen.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kPrimaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _openTailorDetail(tailor),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Lihat Detail Lengkap'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}