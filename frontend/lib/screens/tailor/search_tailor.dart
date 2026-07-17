import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../services/view_override.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import 'search_tailor_screen.dart';
import 'search_tailor_web.dart';

/// Wrapper that chooses web or mobile Search layout using kIsWeb.
class SearchTailor extends StatelessWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final String? initialCategory;
  final String? initialQuery;

  const SearchTailor({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize override flag from URL query param (only relevant on web).
    ViewOverride.initFromUri();

    // Responsive selection: native mobile always mobile; on web use width or
    // force web view when `?view=web` is present in the URL.
    final width = MediaQuery.of(context).size.width;
    final useWebLayout = kIsWeb && (ViewOverride.forceWeb || width >= 900);

    if (useWebLayout) {
      return SearchTailorWeb(
        authService: authService,
        orderService: orderService,
        apiClient: apiClient,
        currentUserId: currentUserId,
        initialCategory: initialCategory,
        initialQuery: initialQuery,
      );
    }

    return SearchTailorScreen(
      authService: authService,
      orderService: orderService,
      apiClient: apiClient,
      currentUserId: currentUserId,
      initialCategory: initialCategory,
      initialQuery: initialQuery,
    );
  }
}
