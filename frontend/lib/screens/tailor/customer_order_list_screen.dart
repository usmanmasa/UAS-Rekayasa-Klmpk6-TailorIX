import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../order/order_tracking_screen.dart';
import 'customer_home.dart';

/// Layar "Pesanan" untuk pelanggan — daftar riwayat pesanan dengan
/// tiga tab: Diajukan, Dikerjakan, Selesai.
class CustomerOrderListScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final ValueNotifier<int> activeBottomTab;

  const CustomerOrderListScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    required this.activeBottomTab,
  });

  @override
  State<CustomerOrderListScreen> createState() => _CustomerOrderListScreenState();
}

class _CustomerOrderListScreenState extends State<CustomerOrderListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _tabs = <String, List<String>>{
    'Diajukan': ['menunggu_konfirmasi'],
    'Dikerjakan': ['menunggu_pembayaran', 'diproses', 'selesai'],
    'Dibatalkan': ['dibatalkan'],
    'Selesai': ['selesai'],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerHome(
                    authService: widget.authService,
                    orderService: widget.orderService,
                    apiClient: widget.apiClient,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            }
          },
        ),
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          // Use theme / AppColors here so labels are readable on the light AppBar.
          labelColor: AppColors.indigo,
          unselectedLabelColor: AppColors.charcoalSoft,
          indicatorColor: AppColors.gold,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.keys.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.values
            .toList()
            .asMap()
            .entries
            .map((entry) => _OrderStatusList(
                  tabIndex: entry.key,
                  statuses: entry.value,
                  orderService: widget.orderService,
                  apiClient: widget.apiClient,
                  currentUserId: widget.currentUserId,
                  activeBottomTab: widget.activeBottomTab,
                ))
            .toList(),
      ),
    );
  }
}

class _OrderStatusList extends StatefulWidget {
  final int tabIndex;
  final List<String> statuses;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final ValueNotifier<int> activeBottomTab;

  const _OrderStatusList({
    required this.tabIndex,
    required this.statuses,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    required this.activeBottomTab,
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
    widget.activeBottomTab.addListener(_onActiveBottomTabChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant _OrderStatusList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeBottomTab != widget.activeBottomTab) {
      oldWidget.activeBottomTab.removeListener(_onActiveBottomTabChanged);
      widget.activeBottomTab.addListener(_onActiveBottomTabChanged);
    }
  }

  @override
  void dispose() {
    widget.activeBottomTab.removeListener(_onActiveBottomTabChanged);
    super.dispose();
  }

  void _onActiveBottomTabChanged() {
    if (widget.activeBottomTab.value == 1 && mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await widget.orderService.listOrders(statuses: widget.statuses);
      final filteredOrders = orders.where((order) {
        if (widget.tabIndex == 1) {
          return !(order.status == 'selesai' && order.hasReview);
        }
        if (widget.tabIndex == 3) {
          return order.status != 'selesai' || order.hasReview;
        }
        return true;
      }).toList();
      setState(() => _orders = filteredOrders);
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

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: const [
          SizedBox(height: 40),
          EmptyState(
            emoji: '📦',
            title: 'Belum ada pesanan',
            description: 'Riwayat pesanan akan muncul di sini.',
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        itemCount: _orders.length,
        itemBuilder: (ctx, i) {
          final order = _orders[i];
          final shop = order.tailorName ?? 'Toko';
          final service = order.categoryName ?? 'Permak';
          final date = order.createdAt != null
              ? order.createdAt!.toLocal().toIso8601String().split('T').first
              : order.deadline.toLocal().toIso8601String().split('T').first;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(
                        orderService: widget.orderService,
                        apiClient: widget.apiClient,
                        orderId: order.id,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(shop.isNotEmpty ? shop[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(shop, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.8)),
                          Text(service, style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
                        ]),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge(status: order.status),
                          if (order.isCancellationPending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.goldPale,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Menunggu persetujuan',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.goldDeep),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text('Tanggal: $date', style: const TextStyle(fontSize: 12, color: AppColors.charcoalSoft)),
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
