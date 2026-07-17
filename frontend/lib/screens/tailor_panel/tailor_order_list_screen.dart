import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/tailor_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'tailor_order_detail_screen.dart';

/// Daftar pesanan yang masuk ke toko penjahit, dikelompokkan per status
/// sesuai tahapan pada sequence diagram pemesanan.
class TailorOrderListScreen extends StatefulWidget {
  final TailorService tailorService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const TailorOrderListScreen({
    super.key,
    required this.tailorService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<TailorOrderListScreen> createState() => _TailorOrderListScreenState();
}

class _TailorOrderListScreenState extends State<TailorOrderListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Setiap tab merepresentasikan kelompok status pada alur pemesanan.
  static const _tabs = <String, List<String>>{
    'Masuk': ['menunggu_konfirmasi'],
    'Berjalan': ['menunggu_pembayaran', 'diproses'],
    'Selesai': ['selesai'],
    'Lainnya': ['ditolak', 'dibatalkan'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Pesanan', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.gold,
          tabs: _tabs.keys.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.values
            .map((statuses) => _OrderStatusList(
                  statuses: statuses,
                  tailorService: widget.tailorService,
                  orderService: widget.orderService,
                  apiClient: widget.apiClient,
                  currentUserId: widget.currentUserId,
                ))
            .toList(),
      ),
    );
  }
}

class _OrderStatusList extends StatefulWidget {
  final List<String> statuses;
  final TailorService tailorService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const _OrderStatusList({
    required this.statuses,
    required this.tailorService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<_OrderStatusList> createState() => _OrderStatusListState();
}

class _OrderStatusListState extends State<_OrderStatusList>
    with AutomaticKeepAliveClientMixin {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await widget.orderService.listOrders(statuses: widget.statuses);
      setState(() => _orders = orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 40),
            EmptyState(
              emoji: '📋',
              title: 'Belum ada pesanan',
              description: 'Pesanan pada kategori ini akan muncul di sini.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        itemCount: _orders.length,
        itemBuilder: (ctx, i) {
          final order = _orders[i];
          final name = order.pelangganName ?? 'Pelanggan';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TailorOrderDetailScreen(
                        tailorService: widget.tailorService,
                        orderService: widget.orderService,
                        apiClient: widget.apiClient,
                        orderId: order.id,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                  _load();
                },
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.8)),
                          Text(order.orderCode,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.charcoalSoft, fontFamily: 'monospace')),
                        ]),
                      ),
                      StatusBadge(status: order.status),
                    ]),
                    const SizedBox(height: 10),
                    Text(order.categoryName ?? 'Permak',
                        style: const TextStyle(fontSize: 12, color: AppColors.charcoalSoft)),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
