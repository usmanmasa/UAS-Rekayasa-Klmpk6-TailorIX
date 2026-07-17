import 'package:flutter/material.dart';
import '../../models/tailor_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../notifications/notification_list_screen.dart';
import '../order/order_tracking_screen.dart';
import '../chat/chat_list_screen.dart';
import 'tailor_profile_screen.dart';

/// Langkah 2-4 sequence diagram: Pelanggan mencari & memilih penjahit.
class SearchTailorScreen extends StatefulWidget {
  final AuthService authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final String? initialCategory;
  final String? initialQuery;
  const SearchTailorScreen({
    super.key,
    required this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  State<SearchTailorScreen> createState() => _SearchTailorScreenState();
}

class _SearchTailorScreenState extends State<SearchTailorScreen> {
  final _searchController = TextEditingController();
  List<Tailor> _tailors = [];
  List<Tailor> _nearestTailors = [];
  List<Tailor> _recommendations = [];
  bool _loading = true;
  bool _nearestLoading = true;
  bool _recommendationsLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // apply initial filters if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory;
    }
    _loadNearbyTailors();
    _loadRecommendations();
    if ((_searchController.text.isNotEmpty) || (_selectedCategory != null)) {
      // perform initial search
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  Future<void> _search() async {
    if (!mounted) {
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await widget.orderService.searchTailors(
        query: _searchController.text,
        category: _selectedCategory,
      );
      if (!mounted) {
        return;
      }
      _tailors = result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat penjahit: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadNearbyTailors() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _nearestLoading = true;
      _loading = true;
    });
    try {
      final result = await widget.orderService.getNearbyTailors();
      if (!mounted) {
        return;
      }
      _nearestTailors = result;
      _tailors = result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat penjahit terdekat: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _nearestLoading = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) {
      return;
    }
    setState(() => _recommendationsLoading = true);
    try {
      final result = await widget.orderService.recommendTailors();
      if (!mounted) {
        return;
      }
      _recommendations = result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat rekomendasi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _recommendationsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearchActive = _searchController.text.isNotEmpty || _selectedCategory != null;
    final nearestTailors = isSearchActive
        ? _tailors.take(4).toList()
        : _nearestTailors.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.chalk,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigoDeep.withAlpha(12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari penjahit atau jenis permak...',
                          
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      // Notifications button
                      Stack(
                        children: [
                          Material(
                            color: AppColors.white,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none),
                              color: AppColors.indigo,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationListScreen(
                                    notificationService: NotificationService(widget.apiClient),
                                    onOpenOrder: (orderId) => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderTrackingScreen(
                                          orderService: widget.orderService,
                                          apiClient: widget.apiClient,
                                          currentUserId: widget.currentUserId,
                                          orderId: orderId,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),

                      // Chat button (opens conversation list)
                      Material(
                        color: AppColors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: AppColors.indigo,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatListScreen(apiClient: widget.apiClient, orderService: widget.orderService, currentUserId: widget.currentUserId),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _search,
                      color: AppColors.gold,
                      backgroundColor: AppColors.white,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.indigo, AppColors.indigoLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(22),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Permak pakaian',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w700,
                                            )),
                                        const SizedBox(height: 8),
                                        Text('Temukan penjahit terpercaya di sekitar kamu',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: AppColors.white.withAlpha(230),
                                            )),
                                        const SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.white.withAlpha(41),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          child: Text('Cari penjahit terdekat',
                                              style: theme.textTheme.labelMedium?.copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.w700,
                                              )),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withAlpha(41),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(Icons.content_cut, size: 40, color: AppColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kategori permak', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 96,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _buildCategoryItem('Permak Celana Panjang', Icons.height, AppColors.sage, AppColors.sagePale),
                                      _buildCategoryItem('Ganti Resleting', Icons.settings, AppColors.indigoLight, AppColors.linen),
                                      _buildCategoryItem('Permak Baju / Kemeja', Icons.checkroom, AppColors.gold, AppColors.goldPale),
                                      _buildCategoryItem('Jahit Kebaya', Icons.brush, AppColors.purple, AppColors.linen),
                                      _buildCategoryItem('Vermak Jas', Icons.checkroom, AppColors.red, AppColors.redPale),
                                      _buildCategoryItem('Lainnya', Icons.grid_view, AppColors.indigo, AppColors.linen),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text('Penjahit terdekat', style: theme.textTheme.titleMedium),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_nearestLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                height: 96,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            )
                          else if (nearestTailors.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: EmptyState(
                                emoji: '🧵',
                                title: 'Belum ada penjahit ditemukan',
                                description: 'Coba kata kunci lain, atau cek lagi nanti — mitra penjahit baru terus bertambah.',
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: nearestTailors.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 196,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemBuilder: (ctx, i) {
                                  final tailor = nearestTailors[i];
                                  return Material(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TailorProfileScreen(
                                            orderService: widget.orderService,
                                            apiClient: widget.apiClient,
                                            currentUserId: widget.currentUserId,
                                            tailorId: tailor.id,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 88,
                                              decoration: BoxDecoration(
                                                color: AppColors.linen,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              clipBehavior: Clip.hardEdge,
                                              child: tailor.images != null && tailor.images!.isNotEmpty
                                                        ? Image.network(
                                                          ApiClient.storageProxyUrl(tailor.images!.first),
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const Center(
                                                          child: Icon(Icons.content_cut, size: 32, color: AppColors.indigo),
                                                        );
                                                      },
                                                    )
                                                  : const Center(
                                                      child: Icon(Icons.content_cut, size: 32, color: AppColors.indigo),
                                                    ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(tailor.shopName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.2)),
                                            const SizedBox(height: 4),
                                            if (tailor.address != null)
                                              Text(tailor.address!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text('${tailor.ratingAvg.toStringAsFixed(1)} ⭐',
                                                      style: const TextStyle(fontSize: 12, color: AppColors.charcoalSoft)),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.goldPale,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text('Buka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.indigo)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Rekomendasi untuk kamu', style: theme.textTheme.titleMedium),
                          ),
                          const SizedBox(height: 12),
                          if (_recommendationsLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                height: 96,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            )
                          else if (_recommendations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Rekomendasi akan muncul setelah kamu membuat pesanan atau menyukai penjahit.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.charcoalSoft),
                              ),
                            )
                          else
                            ..._recommendations.map((tailor) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Material(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TailorProfileScreen(
                                          orderService: widget.orderService,
                                          apiClient: widget.apiClient,
                                          currentUserId: widget.currentUserId,
                                          tailorId: tailor.id,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: AppColors.linen,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            clipBehavior: Clip.hardEdge,
                                            child: tailor.images != null && tailor.images!.isNotEmpty
                                                ? Image.network(
                                                    tailor.images!.first,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Center(
                                                        child: Icon(Icons.content_cut, size: 30, color: AppColors.indigo),
                                                      );
                                                    },
                                                  )
                                                : const Center(
                                                    child: Icon(Icons.content_cut, size: 30, color: AppColors.indigo),
                                                  ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(tailor.shopName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                                const SizedBox(height: 4),
                                                if (tailor.description != null)
                                                  Text(tailor.description!,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
                                                if (tailor.description == null && tailor.address != null)
                                                  Text(tailor.address!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Text('${tailor.ratingAvg.toStringAsFixed(1)} ⭐', style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
                                                    const SizedBox(width: 8),
                                                    Text('${tailor.ratingCount} ulasan', style: const TextStyle(fontSize: 11, color: AppColors.charcoalSoft)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color color, Color background) {
    final selected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              if (selected) {
                _selectedCategory = null;
              } else {
                _selectedCategory = label;
              }
            });
            _search();
          },
          child: Container(
            width: 92,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.goldPale : background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.gold : Colors.transparent, width: 1.6),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: selected ? AppColors.indigo : AppColors.charcoal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
