import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'add_address_map_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<dynamic> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/customer/addresses');
      setState(() => _addresses = res as List<dynamic>);
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat alamat')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setDefault(int id) async {
    try {
      await ApiClient().post('/customer/addresses/$id/set-default', {});
      await _load();
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengatur alamat utama')));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await ApiClient().delete('/customer/addresses/$id');
      await _load();
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus alamat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alamat Tersimpan')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final data = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddAddressMapScreen(),
            ),
          );
          if (data != null) {
            await _saveAddress(data);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _addresses.length,
              itemBuilder: (context, i) {
                final a = _addresses[i] as Map<String, dynamic>;
                return ListTile(
                  title: Text(a['label'] ?? 'Alamat ${a['id']}'),
                  subtitle: Text(a['alamat_lengkap'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a['is_default'] == true)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Chip(label: Text('Utama')),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.check),
                          tooltip: 'Jadikan Utama',
                          onPressed: () => _setDefault(a['id'] as int),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(a['id'] as int),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Edit or use - future: open edit sheet
                  },
                );
              },
            ),
    );
  }

  Future<void> _saveAddress(Map<String, dynamic> data) async {
    try {
      await ApiClient().post('/customer/addresses', data);
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Exception ? e.toString() : 'Gagal menyimpan alamat';
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
