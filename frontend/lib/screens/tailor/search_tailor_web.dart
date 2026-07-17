import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../models/tailor_model.dart';
import '../../widgets/web_navbar.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_list_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/settings_screen.dart';
import 'customer_home_web.dart';
import 'customer_order_list_screen.dart';
import 'favorite_list_screen.dart';
import 'tailor_profile_screen.dart';

class SearchTailorWeb extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final String? initialCategory;
  final String? initialQuery;

  const SearchTailorWeb({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  State<SearchTailorWeb> createState() => _SearchTailorWebState();
}

class _SearchTailorWebState extends State<SearchTailorWeb> {
  final _searchController = TextEditingController();
  List<Tailor> _tailors = [];
  bool _searchLoading = false;
  String? _selectedCategory;
  String? _userInitial = 'A';
  String? _userPhoto;
  int _unreadNotifications = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory;
    }
    _loadProfileInitial();
    _loadNotificationCount();
    WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
  }

  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await NotificationService(widget.apiClient).list();
      if (!mounted) return;
      setState(() => _unreadNotifications = notifications.where((n) => !n.isRead).length);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadProfileInitial() async {
    try {
      final user = await widget.authService.getProfile();
      if (!mounted) return;
      setState(() {
        _userInitial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A';
        _userPhoto = user.photo;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _performSearch() async {
    setState(() => _searchLoading = true);
    try {
      final res = await widget.orderService.searchTailors(
        query: _searchController.text,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _tailors = res;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencari penjahit: $e')));
    } finally {
      if (mounted) setState(() => _searchLoading = false);
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
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1120
        ? 3
        : width >= 760
            ? 2
            : 1;
    final activeCategory = _selectedCategory ?? 'Semua kategori';

    return Scaffold(
      backgroundColor: AppColors.chalk,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WebNavbar(
                    activePage: WebNavPage.search,
                    onHome: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerHomeWeb(
                          authService: widget.authService,
                          orderService: widget.orderService,
                          apiClient: widget.apiClient,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ),
                    onSearch: () {},
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Center(child: Text('${_tailors.length} hasil', style: const TextStyle(fontSize: 14))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Cari penjahit atau jenis permak...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 118,
                        child: ElevatedButton.icon(
                          onPressed: _performSearch,
                          icon: const Icon(Icons.search),
                          label: const Text('Cari'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(
                        label: Text(activeCategory, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.indigo,
                      ),
                      Chip(
                        label: const Text('Urutkan: Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.indigoLight.withValues(alpha: 0.2)),
                        ),
                      ),
                      Chip(
                        label: const Text('Terdekat', style: TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.indigoLight.withValues(alpha: 0.2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_searchLoading) ...[
                    const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                  ] else if (_tailors.isEmpty) ...[
                    const SizedBox(height: 220, child: Center(child: Text('Tidak ada penjahit ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
                  ] else ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tailors.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, index) {
                        final tailor = _tailors[index];
                        final imageUrl = tailor.images != null && tailor.images!.isNotEmpty ? tailor.images!.first : null;
                        final isOpen = tailor.ratingCount % 2 == 0;
                        return Material(
                          color: AppColors.white,
                          elevation: 1,
                          shadowColor: AppColors.indigo.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.indigoLight.withValues(alpha: 0.15), width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TailorProfileScreen(
                                  authService: widget.authService,
                                  orderService: widget.orderService,
                                  apiClient: widget.apiClient,
                                  currentUserId: widget.currentUserId,
                                  tailorId: tailor.id,
                                ),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 160,
                                      width: double.infinity,
                                      color: AppColors.linen,
                                      child: imageUrl != null
                                            ? Image.network(
                                              ApiClient.storageProxyUrl(imageUrl),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                              },
                                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 32, color: AppColors.indigo)),
                                            )
                                          : const Center(child: Icon(Icons.person, size: 36, color: AppColors.indigo)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tailor.shopName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            tailor.address ?? 'Alamat tidak tersedia',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: AppColors.indigoDeep),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Text(
                                                '${tailor.ratingAvg.toStringAsFixed(1)} ⭐',
                                                style: const TextStyle(fontSize: 12, color: AppColors.charcoalSoft),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${tailor.ratingCount} ulasan',
                                                style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isOpen ? const Color(0xFFE6F4EA) : const Color(0xFFFFF1D6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isOpen ? 'Buka' : 'Tutup',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isOpen ? const Color(0xFF2F6A36) : const Color(0xFF8A5E18),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
