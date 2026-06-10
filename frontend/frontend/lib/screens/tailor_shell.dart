import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'profile_screen.dart';
import 'tailor_dashboard_screen.dart';

class TailorShell extends StatefulWidget {
  const TailorShell({super.key});

  @override
  State<TailorShell> createState() => _TailorShellState();
}

class _TailorShellState extends State<TailorShell> {
  int _selectedIndex = 0;
  late Future<int> _pendingCountFuture;

  @override
  void initState() {
    super.initState();
    _updatePendingCount();
  }

  void _updatePendingCount() {
    _pendingCountFuture = _fetchPendingOrderCount();
  }

  Future<int> _fetchPendingOrderCount() async {
    try {
      final orders = await ApiService.fetchOrders(status: 'waiting_confirmation');
      return orders.length;
    } catch (e) {
      return 0;
    }
  }

  static const List<Widget> _pages = <Widget>[
    TailorDashboardScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: FutureBuilder<int>(
        future: _pendingCountFuture,
        builder: (context, snapshot) {
          final pendingCount = snapshot.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1D9E75),
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true,
            elevation: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            selectedIconTheme: const IconThemeData(size: 24),
            unselectedIconTheme: const IconThemeData(size: 20),
            items: [
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.dashboard),
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              pendingCount > 99 ? '99+' : '$pendingCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            ],
          );
        },
      ),
    );
  }
}
