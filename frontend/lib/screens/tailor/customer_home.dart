import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/view_override.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import 'customer_home_screen.dart';
import 'customer_home_web.dart';

/// Wrapper widget that selects mobile or web/desktop layout
/// based on `kIsWeb`. Keeps existing mobile widget unchanged.
class CustomerHome extends StatelessWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const CustomerHome({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize override flag from URL query param (only relevant on web).
    ViewOverride.initFromUri();

    // Choose layout based on screen width or forced web view when running on web.
    final width = MediaQuery.of(context).size.width;
    // Use web layout when running on web AND either forced via URL (?view=web)
    // or the width meets the desktop breakpoint (>= 900).
    final useWebLayout = kIsWeb && (ViewOverride.forceWeb || width >= 900);

    if (useWebLayout) {
      return CustomerHomeWeb(
        authService: authService,
        orderService: orderService,
        apiClient: apiClient,
        currentUserId: currentUserId,
      );
    }

    return CustomerHomeScreen(
      authService: authService,
      orderService: orderService,
      apiClient: apiClient,
      currentUserId: currentUserId,
    );
  }
}
