import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

/// F-06: Notifikasi Otomatis - daftar notifikasi milik user yang login.
/// Dipakai bersama oleh sisi pelanggan & penjahit; tap pada notifikasi yang
/// terkait pesanan akan menandainya terbaca, lalu (opsional) membuka detail
/// pesanan lewat [onOpenOrder].
class NotificationListScreen extends StatefulWidget {
  final NotificationService notificationService;
  final void Function(int orderId)? onOpenOrder;

  const NotificationListScreen({
    super.key,
    required this.notificationService,
    this.onOpenOrder,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await widget.notificationService.list();
      setState(() => _notifications = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat notifikasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onTap(AppNotification notif) async {
    if (!notif.isRead) {
      setState(() {
        final i = _notifications.indexWhere((n) => n.id == notif.id);
        if (i != -1) {
          _notifications[i] = AppNotification(
            id: notif.id,
            orderId: notif.orderId,
            title: notif.title,
            body: notif.body,
            isRead: true,
            createdAt: notif.createdAt,
          );
        }
      });
      try {
        await widget.notificationService.markRead(notif.id);
      } catch (_) {
        // gagal sinkron status terbaca, abaikan agar tidak mengganggu navigasi
      }
    }

    if (notif.orderId != null && widget.onOpenOrder != null) {
      widget.onOpenOrder!(notif.orderId!);
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: const [
                      SizedBox(height: 60),
                      EmptyState(
                        emoji: '🔔',
                        title: 'Belum ada notifikasi',
                        description: 'Kabar tentang pesanan, pesan, dan pembayaranmu akan muncul di sini.',
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) {
                      final notif = _notifications[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Material(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _onTap(notif),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: notif.isRead ? Colors.transparent : AppColors.gold, width: 1.3),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: notif.isRead ? AppColors.linen : AppColors.goldPale,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                                    size: 18,
                                    color: notif.isRead ? AppColors.charcoalSoft : AppColors.goldDeep,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(notif.title,
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.6)),
                                      ),
                                      if (!notif.isRead)
                                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text(notif.body,
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.charcoalSoft, height: 1.5)),
                                    const SizedBox(height: 5),
                                    Text(_timeAgo(notif.createdAt),
                                        style: const TextStyle(fontSize: 10, color: AppColors.charcoalSoft)),
                                  ]),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
