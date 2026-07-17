import '../models/category_model.dart';
import 'api_client.dart';

/// Mengambil daftar kategori permak dari `GET /categories`, dikelola oleh
/// admin di backend. Dipakai oleh `OrderFormScreen` supaya dropdown kategori
/// selalu sinkron dengan data admin, bukan daftar statis di kode Flutter.
class CategoryService {
  final ApiClient api;
  CategoryService(this.api);

  Future<List<PermakCategory>> list() async {
    final res = await api.get('/categories');
    final data = res as List;
    return data.map((e) => PermakCategory.fromJson(e as Map<String, dynamic>)).toList();
  }
}
