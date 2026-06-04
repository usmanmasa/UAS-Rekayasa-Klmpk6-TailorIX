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
  Future<List<Tailor>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = ApiService.fetchTailors();
  }

  void _search() {
    setState(() {
      _searchFuture = ApiService.fetchTailors(query: _searchController.text);
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
