import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';

const Color kPrimaryBlue = Color(0xFF141E34);
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
  static const List<String> _filters = ['Semua', 'Terdekat', 'Rating Tinggi'];

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
    }
    return list;
  }

  void _openTailorDetail(Tailor tailor) {
    Navigator.pushNamed(context, '/tailor-detail', arguments: tailor);
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_viewLabels.length, (index) {
          final isSelected = _selectedViewIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedViewIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _viewLabels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kAccentGold : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? kAccentGold : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(List<Tailor> tailors) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _userLocation ?? const LatLng(-6.9175, 107.6191),
            zoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tailorix.app',
            ),
            MarkerLayer(
              markers: [
                if (_userLocation != null)
                  Marker(
                    width: 40,
                    height: 40,
                    point: _userLocation!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                    ),
                  ),
                ...tailors.map(
                  (tailor) => Marker(
                    width: 40,
                    height: 40,
                    point: LatLng(tailor.locationLat, tailor.locationLng),
                    child: GestureDetector(
                      onTap: () => _centerOnTailor(tailor),
                      child: Container(
                        decoration: BoxDecoration(
                          color: kAccentGold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentGold.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _centerOnUserLocation,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: kPrimaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<Tailor> tailors) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tailors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tailor = tailors[index];
        return GestureDetector(
          onTap: () => _openTailorDetail(tailor),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kAccentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: kAccentGold, size: 30),
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
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: kAccentGold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            tailor.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${tailor.distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tailor.specializations.isNotEmpty
                            ? tailor.specializations.join(', ')
                            : 'Tailor',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTailorCardBottom(Tailor tailor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kAccentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: kAccentGold, size: 24),
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
                        color: kPrimaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: kAccentGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          tailor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${tailor.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedTailor = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openTailorDetail(tailor),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Detail', style: TextStyle(color: kPrimaryBlue)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Pesan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundLight,
      appBar: AppBar(
        title: const Text('Peta Penjahit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryBlue,
        elevation: 0,
      ),
      body: FutureBuilder<List<Tailor>>(
        future: _tailorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat penjahit: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada penjahit tersedia'));
          }

          _tailors = snapshot.data!;
          final filteredTailors = _filteredTailors;

          return Column(
            children: [
              _buildViewToggle(),
              _buildFilterChips(),
              Expanded(
                child: _selectedViewIndex == 1
                    ? Stack(
                        children: [
                          _buildMapView(filteredTailors),
                          if (_selectedTailor != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildTailorCardBottom(_selectedTailor!),
                            ),
                        ],
                      )
                    : _buildListView(filteredTailors),
              ),
            ],
          );
        },
      ),
    );
  }
}