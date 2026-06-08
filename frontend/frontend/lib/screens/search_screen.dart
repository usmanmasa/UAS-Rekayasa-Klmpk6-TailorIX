import 'package:flutter/material.dart';

import '../models/tailor.dart';
import '../services/api_service.dart';
import '../widgets/tailor_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  double _minRating = 0;
  Future<List<Tailor>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = ApiService.fetchTailors();
  }

  void _search() {
    setState(() {
      _searchFuture = ApiService.fetchTailors(
        query: _searchController.text,
        category: _selectedCategory,
        minRating: _minRating > 0 ? _minRating : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Penjahit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari berdasarkan nama, layanan, lokasi',
                suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () {
                  _searchController.clear();
                  _search();
                }),
              ),
              onChanged: (_) => _search(),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Filter Kategori'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua kategori')),
                      DropdownMenuItem(value: 'Ubah Ukuran', child: Text('Ubah Ukuran')),
                      DropdownMenuItem(value: 'Ganti Ritsleting', child: Text('Ganti Ritsleting')),
                      DropdownMenuItem(value: 'Tambal', child: Text('Tambal')),
                      DropdownMenuItem(value: 'Sulam', child: Text('Sulam')),
                      DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                      _search();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<double?>(
                    initialValue: _minRating > 0 ? _minRating : null,
                    decoration: const InputDecoration(labelText: 'Rating minimal'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua')),
                      DropdownMenuItem(value: 3.0, child: Text('>= 3.0')),
                      DropdownMenuItem(value: 4.0, child: Text('>= 4.0')),
                      DropdownMenuItem(value: 4.5, child: Text('>= 4.5')),
                    ],
                    onChanged: (value) {
                      setState(() => _minRating = value ?? 0);
                      _search();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Tailor>>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Gagal mencari penjahit: ${snapshot.error}'));
                  }
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return const Center(child: Text('Tidak ada penjahit yang cocok.'));
                  }
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final tailor = results[index];
                      return TailorCard(
                        tailor: tailor,
                        onTap: () => Navigator.pushNamed(context, '/tailor-detail', arguments: tailor),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
