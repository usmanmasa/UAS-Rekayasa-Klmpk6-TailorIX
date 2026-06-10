import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ApiService.fetchAdminUsers(query: query);
      if (!mounted) return;
      setState(() {
        _users = users;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disableUser(String userId) async {
    try {
      await ApiService.disableAdminUser(userId: userId);
      await _loadUsers(_searchController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengguna berhasil dinonaktifkan.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama, email, atau shop name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                ),
              ),
              onSubmitted: (value) => _loadUsers(value.trim()),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text('Error: $_error')))
            else if (_users.isEmpty)
              const Expanded(child: Center(child: Text('Belum ada pengguna.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final role = user['role'] ?? 'customer';
                    final isActive = user['is_verified'] == true;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    user['name']?.toString() ?? 'Pengguna',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Chip(
                                  label: Text(role.toString().toUpperCase()),
                                  backgroundColor: role == 'admin' ? Colors.indigo.shade50 : role == 'tailor' ? Colors.green.shade50 : Colors.grey.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(user['email']?.toString() ?? '-', style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text(user['phone']?.toString() ?? '-', style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                Text('Status: ${isActive ? 'Aktif' : 'Nonaktif'}'),
                                if (user['shop_name'] != null && user['shop_name'].toString().isNotEmpty)
                                  Text('Toko: ${user['shop_name']}'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isActive ? () => _disableUser(user['id'].toString()) : null,
                                    child: const Text('Nonaktifkan'),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
