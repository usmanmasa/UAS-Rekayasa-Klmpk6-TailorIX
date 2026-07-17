import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import 'favorite_list_screen.dart';
import 'customer_order_list_screen.dart';
import 'search_tailor.dart';
import '../profile/profile_screen.dart';

/// Layar home untuk pengguna dengan role `pelanggan`.
///
/// Menyatukan pencarian penjahit, daftar favorit, dan akun pengguna.
class CustomerHomeScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const CustomerHomeScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<int> _activeBottomTab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _activeBottomTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      SearchTailor(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
        currentUserId: widget.currentUserId,
      ),
      CustomerOrderListScreen(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
        currentUserId: widget.currentUserId,
        activeBottomTab: _activeBottomTab,
      ),
      FavoriteListScreen(
        orderService: widget.orderService,
        apiClient: widget.apiClient,
        currentUserId: widget.currentUserId,
      ),
      ProfileScreen(
        authService: widget.authService,
        orderService: widget.orderService,
        apiClient: widget.apiClient,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _activeBottomTab.value = index;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favorit'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Akun'),
        ],
      ),
    );
  }
}
