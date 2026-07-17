import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../theme/app_colors.dart';

class AddAddressMapScreen extends StatefulWidget {
  const AddAddressMapScreen({super.key});

  @override
  State<AddAddressMapScreen> createState() => _AddAddressMapScreenState();
}

class _AddAddressMapScreenState extends State<AddAddressMapScreen> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(-6.200000, 106.8166667);
  LatLng _currentLatLng = const LatLng(-6.200000, 106.8166667);
  bool _loadingAddress = false;
  StreamSubscription<MapEvent>? _mapSub;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      if (pos != null) {
        final p = LatLng(pos.latitude, pos.longitude);
        _moveCamera(p, animate: false);
        _setLatLngFields(p);
        _reverseGeocode(p);
      }
    });

    // Listen to map events to update center when user pans/zooms
    _mapSub = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        final center = event.camera.center;
        _onMapMoved(center);
      }
    });
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    } catch (_) {
      return null;
    }
  }

  Future<void> _moveCamera(LatLng target, {bool animate = true}) async {
    try {
      _mapController.move(target, 17);
    } catch (_) {
      // ignore
    }
    setState(() {
      _currentLatLng = target;
    });
  }

  void _setLatLngFields(LatLng p) {
    _latController.text = p.latitude.toStringAsFixed(7);
    _lngController.text = p.longitude.toStringAsFixed(7);
  }

  Future<void> _reverseGeocode(LatLng p) async {
    setState(() => _loadingAddress = true);
    try {
      final places = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (places.isNotEmpty) {
        final pl = places.first;
        final formatted = [
          pl.street,
          pl.subLocality,
          pl.subAdministrativeArea,
          pl.locality
        ].where((s) => s != null && s.trim().isNotEmpty).join(', ');
        _addressController.text = formatted;
      }
    } catch (e) {
      // ignore errors; keep existing address
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapSub?.cancel();
    super.dispose();
  }

  void _onMapMoved(LatLng pos) {
    _currentLatLng = pos;
    _setLatLngFields(_currentLatLng);
    _reverseGeocode(_currentLatLng);
  }

  void _onMapTap(LatLng p) async {
    await _moveCamera(p);
    _setLatLngFields(p);
    await _reverseGeocode(p);
  }

  Future<void> _useCurrentLocation() async {
    final pos = await _determinePosition();
    if (pos == null) return;
    final p = LatLng(pos.latitude, pos.longitude);
    await _moveCamera(p);
    _setLatLngFields(p);
    await _reverseGeocode(p);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final out = {
      'label': _labelController.text.trim(),
      'alamat_lengkap': _addressController.text.trim(),
      'latitude': double.tryParse(_latController.text) ?? _currentLatLng.latitude,
      'longitude': double.tryParse(_lngController.text) ?? _currentLatLng.longitude,
    };
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration.collapsed(hintText: 'Cari lokasi'),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.location_on_outlined)),
        ]),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sagePale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.notifications, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text('Mohon periksa pin lokasimu, kami akan mengirimkan pesananmu sesuai pin lokasi')),
              ]),
            ),
          ),
          SizedBox(
            height: 220,
            child: Stack(children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  // Use initialCenter/initialZoom per flutter_map API
                  initialCenter: _initialCenter,
                  initialZoom: 16,
                  onTap: (tapPos, latlng) {
                    // latlng is non-null by API, call handler directly
                    _onMapTap(latlng);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tailorlx.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLatLng,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.place, size: 48, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
              const Center(child: IgnorePointer(child: Icon(Icons.place, size: 48, color: Colors.red))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, color: AppColors.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Antar Ke: ${_addressController.text.split(',').first}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: Text(_addressController.text, style: const TextStyle(color: AppColors.charcoalSoft))),
                    if (_loadingAddress) const SizedBox(width: 8),
                    if (_loadingAddress) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ]),
                ]),
              ),
              TextButton.icon(onPressed: _useCurrentLocation, icon: const Icon(Icons.my_location), label: const Text('Lokasi Saat Ini')),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: ListView(children: [
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(labelText: 'Label (Rumah/Kantor)'),
                    validator: (v) => v == null || v.isEmpty ? 'Label wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Alamat lengkap'),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Alamat lengkap wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Simpan Alamat', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
