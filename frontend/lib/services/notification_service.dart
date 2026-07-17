import '../models/notification_model.dart';
import 'api_client.dart';

/// F-06: Notifikasi Otomatis - daftar & tandai sudah dibaca
class NotificationService {
  final ApiClient api;
  NotificationService(this.api);

  Future<List<AppNotification>> list() async {
    final res = await api.get('/notifications');
    return (res['data'] as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markRead(int id) async {
    await api.post('/notifications/$id/read', {});
  }
}
