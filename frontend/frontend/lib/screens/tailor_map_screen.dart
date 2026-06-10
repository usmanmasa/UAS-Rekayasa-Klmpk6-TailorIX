import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TailorMapScreen extends StatelessWidget {
  const TailorMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final title = args?['title'] as String? ?? 'Lokasi Penjahit';
    final lat = args?['lat'] as double? ?? 0.0;
    final lng = args?['lng'] as double? ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: lat == 0.0 && lng == 0.0
          ? const Center(
              child: Text('Lokasi penjahit tidak tersedia.'),
            )
          : FlutterMap(
              options: MapOptions(
                center: LatLng(lat, lng),
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tailorix',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: LatLng(lat, lng),
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
