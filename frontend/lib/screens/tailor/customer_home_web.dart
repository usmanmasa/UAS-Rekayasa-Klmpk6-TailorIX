import 'package:flutter/material.dart';
import '../../models/tailor_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/web_navbar.dart';
import '../../widgets/safe_network_image.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_list_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/settings_screen.dart';
import 'customer_order_list_screen.dart';
import 'favorite_list_screen.dart';
import 'search_tailor.dart';
import 'tailor_profile_screen.dart';

class CustomerHomeWeb extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const CustomerHomeWeb({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<CustomerHomeWeb> createState() => _CustomerHomeWebState();
}

class _CustomerHomeWebState extends State<CustomerHomeWeb> {
  int? _hoveredCategoryIndex;
  List<Tailor> _nearby = [];
  List<Tailor> _recommendations = [];
  bool _loadingNearby = true;
  bool _loadingRecommendations = true;
  String? _userInitial = 'A';
  String? _userPhoto;
  int _unreadNotifications = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Permak Celana', 'icon': Icons.height, 'color': AppColors.sage},
    {'label': 'Ganti Resleting', 'icon': Icons.settings, 'color': AppColors.indigoLight},
    {'label': 'Permak Baju', 'icon': Icons.checkroom, 'color': AppColors.gold},
    {'label': 'Jahit Kebaya', 'icon': Icons.brush, 'color': AppColors.purple},
    {'label': 'Vermak Jas', 'icon': Icons.checkroom, 'color': AppColors.red},
    {'label': 'Lainnya', 'icon': Icons.grid_view, 'color': AppColors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _loadNearbyTailors();
    _loadRecommendations();
    _loadProfileInitial();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await NotificationService(widget.apiClient).list();
      if (!mounted) return;
      setState(() => _unreadNotifications = notifications.where((n) => !n.isRead).length);
    } catch (_) {
      // ignore load errors; badge stays hidden
    }
  }

  Future<void> _loadProfileInitial() async {
    try {
      final user = await widget.authService.getProfile();
      if (!mounted) return;
      setState(() {
        _userInitial = (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A');
        _userPhoto = user.photo;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadNearbyTailors() async {
    setState(() => _loadingNearby = true);
    try {
      final res = await widget.orderService.getNearbyTailors();
      if (!mounted) return;
      setState(() {
        _nearby = res;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat penjahit terdekat: $e')));
    } finally {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      final res = await widget.orderService.recommendTailors();
      if (!mounted) return;
      setState(() {
        _recommendations = res;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat rekomendasi: $e')));
    } finally {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.authService.logout();
    } catch (_) {
      // ignore errors during logout and continue to login screen
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authService: widget.authService,
          orderService: widget.orderService,
          apiClient: widget.apiClient,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFAF6EF);
    const navy = Color(0xFF1E3A5F);
    const orange = Color(0xFFE8862D);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          WebNavbar(
            activePage: WebNavPage.home,
            onHome: () {},
            onSearch: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SearchTailor(
                  authService: widget.authService,
                  orderService: widget.orderService,
                  apiClient: widget.apiClient,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),
            onOrders: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerOrderListScreen(
                  authService: widget.authService,
                  orderService: widget.orderService,
                  apiClient: widget.apiClient,
                  currentUserId: widget.currentUserId,
                  activeBottomTab: ValueNotifier<int>(0),
                ),
              ),
            ),
            onFavorites: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => FavoriteListScreen(
                  authService: widget.authService,
                  orderService: widget.orderService,
                  apiClient: widget.apiClient,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),
            unreadNotificationCount: _unreadNotifications,
            onNotifications: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationListScreen(
                    notificationService: NotificationService(widget.apiClient),
                  ),
                ),
              );
            },
            userInitial: _userInitial ?? 'A',
            userPhoto: _userPhoto,
            onProfileSelected: (action) {
              switch (action) {
                case ProfileMenuAction.profile:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        authService: widget.authService,
                        orderService: widget.orderService,
                        apiClient: widget.apiClient,
                      ),
                    ),
                  ).then((_) {
                    if (!mounted) return;
                    _loadProfileInitial();
                  });
                  break;
                case ProfileMenuAction.settings:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
                case ProfileMenuAction.logout:
                  _logout();
                  break;
              }
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE6E1D6)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: const [
                        Icon(Icons.search, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(child: Text('Cari penjahit atau jenis permak...', style: TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      // Hero
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Permak pakaian, mudah dan terpercaya', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('Temukan penjahit terbaik di sekitar kamu untuk permak, jahit, dan reparasi', style: TextStyle(color: Colors.white.withAlpha(210))),
                                  const SizedBox(height: 18),
                                  ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: orange), child: const Text('Cari penjahit terdekat')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 31), borderRadius: BorderRadius.circular(12)),
                              child: const Center(child: Icon(Icons.content_cut, color: Colors.white, size: 28)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Categories grid (6 columns)
                      const Text('Kategori permak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2A))),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 6,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(_categories.length, (index) {
                          final c = _categories[index];
                          final hovered = _hoveredCategoryIndex == index;
                          return MouseRegion(
                            onEnter: (_) => setState(() => _hoveredCategoryIndex = index),
                            onExit: (_) => setState(() => _hoveredCategoryIndex = null),
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: hovered ? const Color(0xFF185FA5) : const Color(0xFFE6E1D6)),
                                boxShadow: hovered ? [BoxShadow(color: Colors.black.withValues(alpha: 15), blurRadius: 8, offset: const Offset(0, 2))] : null,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchTailor(
                                      authService: widget.authService,
                                      orderService: widget.orderService,
                                      apiClient: widget.apiClient,
                                      currentUserId: widget.currentUserId,
                                      initialCategory: c['label'] as String,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(c['icon'] as IconData, color: c['color'] as Color),
                                    const SizedBox(height: 8),
                                    Text(c['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF2C2C2A))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      // Nearby tailors title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Penjahit terdekat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2A))),
                          TextButton(onPressed: () {}, child: const Text('Lihat semua', style: TextStyle(color: Color(0xFF185FA5)))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Nearby grid (4 columns)
                      _loadingNearby
                          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _nearby.length.clamp(0, 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 220,
                              ),
                              itemBuilder: (ctx, i) {
                                final t = _nearby[i];
                                final img = (t.images != null && t.images!.isNotEmpty) ? t.images!.first : null;
                                return InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TailorProfileScreen(authService: widget.authService, orderService: widget.orderService, apiClient: widget.apiClient, currentUserId: widget.currentUserId, tailorId: t.id)),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE6E1D6))),
                                    clipBehavior: Clip.hardEdge,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 110,
                                          width: double.infinity,
                                          color: AppColors.linen,
                                          child: img != null
                                              ? Image.network(ApiClient.storageProxyUrl(img), fit: BoxFit.cover, width: double.infinity, loadingBuilder: (ctx, child, prog) {
                                                  if (prog == null) return child;
                                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                                }, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.content_cut, size: 32, color: AppColors.indigo)))
                                              : const Center(child: Icon(Icons.content_cut, size: 32, color: AppColors.indigo)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(t.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.2)),
                                            const SizedBox(height: 4),
                                            if (t.address != null) Text(t.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6E7386))),
                                            const SizedBox(height: 8),
                                            Row(children: [Text('${t.ratingAvg.toStringAsFixed(1)} ⭐', style: const TextStyle(fontSize: 12, color: Color(0xFF6E7386))), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF3E6C4), borderRadius: BorderRadius.circular(12)), child: const Text('Buka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.indigo))),]),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      const SizedBox(height: 24),
                      const Text('Rekomendasi untuk kamu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2A))),
                      const SizedBox(height: 12),

                      // Recommendations (3 columns, horizontal cards)
                      _loadingRecommendations
                          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recommendations.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 84,
                              ),
                              itemBuilder: (ctx, i) {
                                final t = _recommendations[i];
                                final img = (t.images != null && t.images!.isNotEmpty) ? t.images!.first : null;
                                return InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => TailorProfileScreen(authService: widget.authService, orderService: widget.orderService, apiClient: widget.apiClient, currentUserId: widget.currentUserId, tailorId: t.id)),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE6E1D6))),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(children: [
                                      Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(8)), clipBehavior: Clip.hardEdge, child: img != null ? SafeNetworkImage(url: ApiClient.storageProxyUrl(img), fit: BoxFit.cover, width: 56, height: 56) : const Icon(Icons.content_cut, color: AppColors.indigo)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(t.shopName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(t.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6E7386)))])),
                                    ]),
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
