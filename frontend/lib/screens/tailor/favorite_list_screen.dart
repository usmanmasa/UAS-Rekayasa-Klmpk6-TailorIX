import 'package:flutter/material.dart';
import '../../models/tailor_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/rating_stars.dart';
import 'customer_home.dart';
import 'tailor_profile_screen.dart';

/// F-02: Daftar penjahit yang ditandai favorit oleh pelanggan.
class FavoriteListScreen extends StatefulWidget {
  final AuthService? authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;

  const FavoriteListScreen({
    super.key,
    this.authService,
    required this.orderService,
    required this.apiClient,
    required this.currentUserId,
  });

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  late final FavoriteService _favoriteService;
  List<Tailor> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _favoriteService = FavoriteService(widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final favorites = await _favoriteService.list();
      setState(() => _favorites = favorites);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat favorit: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Tailor tailor) async {
    try {
      await _favoriteService.remove(tailor.id);
      setState(() => _favorites.removeWhere((t) => t.id == tailor.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus favorit: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else if (widget.authService != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerHome(
                    authService: widget.authService!,
                    orderService: widget.orderService,
                    apiClient: widget.apiClient,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            }
          },
        ),
        title: const Text('Penjahit Favorit'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_favorites.length} toko tersimpan',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.charcoalSoft, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const EmptyState(
                  emoji: '❤️',
                  title: 'Belum ada penjahit favorit',
                  description: 'Ketuk ikon hati di profil penjahit untuk menyimpannya di sini.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: _favorites.length,
                    itemBuilder: (ctx, i) {
                      final tailor = _favorites[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await Navigator.push(
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
                              );
                              _load();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(14)),
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
                                              child: Icon(Icons.content_cut, color: AppColors.indigo),
                                            );
                                          },
                                        )
                                      : const Center(
                                          child: Icon(Icons.content_cut, color: AppColors.indigo),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(tailor.shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    RatingStars(rating: tailor.ratingAvg, count: tailor.ratingCount),
                                  ]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: AppColors.red),
                                  onPressed: () => _remove(tailor),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
