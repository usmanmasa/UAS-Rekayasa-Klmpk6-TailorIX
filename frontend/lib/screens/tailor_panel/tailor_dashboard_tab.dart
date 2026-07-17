import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../services/tailor_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_stars.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notification_list_screen.dart';
import 'tailor_order_detail_screen.dart';

/// Ringkasan beranda penjahit: rating toko & jumlah pesanan per status,
/// supaya penjahit langsung tahu ada berapa pesanan yang perlu direspons.
class TailorDashboardTab extends StatefulWidget {
  final TailorService tailorService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final VoidCallback onSeeIncomingOrders;

  const TailorDashboardTab({
    super.key,
    required this.tailorService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    required this.onSeeIncomingOrders,
  });

  @override
  State<TailorDashboardTab> createState() => _TailorDashboardTabState();
}

class _TailorDashboardTabState extends State<TailorDashboardTab> {
  TailorDashboard? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dashboard = await widget.tailorService.getDashboard();
      setState(() => _dashboard = dashboard);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat dashboard: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(dashboard != null ? 'Toko ${dashboard.shopName}' : 'Beranda Penjahit',
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatListScreen(
                  apiClient: widget.apiClient,
                  orderService: widget.orderService,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationListScreen(
                  notificationService: NotificationService(widget.apiClient),
                  onOpenOrder: (orderId) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TailorOrderDetailScreen(
                        tailorService: widget.tailorService,
                        orderService: widget.orderService,
                        apiClient: widget.apiClient,
                        orderId: orderId,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading || dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('RATING TOKO',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.gold)),
                          const SizedBox(height: 4),
                          RatingStars(rating: dashboard.ratingAvg, count: dashboard.ratingCount, size: 15),
                        ]),
                      ),
                      const Text('⭐', style: TextStyle(fontSize: 30)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Text('Ringkasan Pesanan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: GoogleFonts.fraunces().fontFamily)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        label: 'Masuk Baru',
                        value: dashboard.menungguKonfirmasi,
                        color: AppColors.goldDeep,
                        bg: AppColors.goldPale,
                        onTap: widget.onSeeIncomingOrders,
                      ),
                      _StatCard(label: 'Sedang Dikerjakan', value: dashboard.diproses, color: AppColors.sage, bg: AppColors.sagePale),
                      _StatCard(label: 'Selesai', value: dashboard.selesai, color: AppColors.goldDeep, bg: AppColors.goldPale),
                      _StatCard(label: 'Total Pesanan', value: dashboard.total, color: AppColors.indigo, bg: AppColors.mist),
                    ],
                  ),
                  if (dashboard.menungguKonfirmasi > 0) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.indigoDeep),
                      onPressed: widget.onSeeIncomingOrders,
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: Text('${dashboard.menungguKonfirmasi} pesanan menunggu respons'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.color, required this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value',
                  style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
                child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
