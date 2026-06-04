import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5;
  final _commentController = TextEditingController();
  String? _message;
  bool _isSubmitting = false;

  Future<void> _submitReview(Order order) async {
    if (_commentController.text.trim().isEmpty) {
      setState(() => _message = 'Mohon tambahkan komentar ulasan.');
      return;
    }
    setState(() {
      _message = null;
      _isSubmitting = true;
    });

    String? errorMessage;
    try {
      await ApiService.submitReview(
        orderId: order.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (errorMessage != null) {
      setState(() => _message = errorMessage);
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil dikirim.')));
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    return Scaffold(
      appBar: AppBar(title: const Text('Berikan Ulasan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penjahit: ${order.tailor.shopName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Rating (1-5)'),
            Slider(value: _rating, min: 1, max: 5, divisions: 4, label: _rating.toString(), onChanged: (value) => setState(() => _rating = value)),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Komentar ulasan', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            if (_message != null) Text(_message!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitReview(order),
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Ulasan'),
            ),
          ],
        ),
      ),
    );
  }
}
