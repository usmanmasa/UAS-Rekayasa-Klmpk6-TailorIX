import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderTile({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(order.tailor.shopName),
        subtitle: Text(order.category),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Rp ${order.finalPrice > 0 ? order.finalPrice.toStringAsFixed(0) : order.estimatedPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            Text(order.status, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
