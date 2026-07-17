import '../models/tailor_model.dart';
import 'api_client.dart';

/// F-02: tambah/hapus penjahit favorit
class FavoriteService {
  final ApiClient api;
  FavoriteService(this.api);

  Future<List<Tailor>> list() async {
    final res = await api.get('/favorites');
    return (res as List)
        .map((e) => Tailor.fromJson(e['tailor']))
        .toList();
  }

  Future<Tailor> add(int tailorId) async {
    final res = await api.post('/favorites', {'tailor_id': tailorId});
    // API returns favorite with 'tailor' relation populated
    return Tailor.fromJson(res['tailor']);
  }

  Future<void> remove(int tailorId) async {
    await api.delete('/favorites/$tailorId');
  }
}
