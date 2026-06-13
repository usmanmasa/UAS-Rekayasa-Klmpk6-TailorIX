import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/api_service.dart';

final ordersProvider = AsyncNotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    return [];
  }

  Future<void> fetchOrders({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final orders = await ApiService.fetchOrders(status: status);
      print('=== ORDERS: ${orders.length} pesanan ===');
      for (final o in orders) {
        print('  - id: ${o.id} | status: ${o.status}');
      }
      state = AsyncValue.data(orders);
    } catch (e, st) {
      print('=== ORDERS ERROR: $e ===');
      state = AsyncValue.error(e, st);
    }
  }

  void addOrder(Order order) {
    state = state.when(
      data: (orders) => AsyncValue.data([order, ...orders]),
      loading: () => AsyncValue.data([order]),
      error: (error, stack) => AsyncValue.data([order]),
    );
  }
}