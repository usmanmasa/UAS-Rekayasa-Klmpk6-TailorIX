import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/tailor_service.dart';
import '../profile/profile_screen.dart';
import 'tailor_dashboard_tab.dart';
import 'tailor_order_list_screen.dart';
import 'tailor_shop_profile_screen.dart';

/// Entry point sisi Penjahit setelah login dengan role `penjahit`.
/// Menyatukan tiga modul: dashboard ringkasan, pesanan masuk/berjalan/riwayat
/// (langkah 13-20 sequence diagram), dan kelola profil toko sendiri.
class TailorHomeScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final TailorService tailorService;
  final ApiClient apiClient;
  final int currentUserId;

  const TailorHomeScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.tailorService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<TailorHomeScreen> createState() => _TailorHomeScreenState();
}

class _TailorHomeScreenState extends State<TailorHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      TailorDashboardTab(
        tailorService: widget.tailorService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
        currentUserId: widget.currentUserId,
        onSeeIncomingOrders: () => setState(() => _index = 1),
      ),
      TailorOrderListScreen(
        tailorService: widget.tailorService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
        currentUserId: widget.currentUserId,
      ),
      TailorShopProfileScreen(tailorService: widget.tailorService),
      ProfileScreen(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Profil Toko'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Akun'),
        ],
      ),
    );
  }
}
