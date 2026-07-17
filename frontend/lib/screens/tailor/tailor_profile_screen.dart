import 'package:flutter/material.dart';
import '../../models/tailor_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/stitch_divider.dart';
import '../order/order_form_screen.dart';
import 'customer_home.dart';

/// Tailor detail screen redesigned to resemble an e-commerce product detail.
class TailorProfileScreen extends StatefulWidget {
  final AuthService? authService;
  final OrderService orderService;
  final ApiClient apiClient;
  final int currentUserId;
  final int tailorId;

  const TailorProfileScreen(
      {super.key,
      this.authService,
      required this.orderService,
      required this.apiClient,
      required this.currentUserId,
      required this.tailorId});

  @override
  State<TailorProfileScreen> createState() => _TailorProfileScreenState();
}

class _TailorProfileScreenState extends State<TailorProfileScreen> {
  late final FavoriteService _favoriteService;
  Tailor? _tailor;
  bool _loading = true;
  bool _isFavorite = false;
  bool _favoriteBusy = false;
  final PageController _pageController = PageController();
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _favoriteService = FavoriteService(widget.apiClient);
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.orderService.getTailorProfile(widget.tailorId),
      _favoriteService.list(),
    ]);
    final tailor = results[0] as Tailor;
    final favorites = results[1] as List<Tailor>;
    setState(() {
      _tailor = tailor;
      _isFavorite = favorites.any((t) => t.id == widget.tailorId);
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() => _favoriteBusy = true);
    try {
      if (_isFavorite) {
        await _favoriteService.remove(widget.tailorId);
      } else {
        await _favoriteService.add(widget.tailorId);
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui favorit: $e')));
      }
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _tailor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final images = _tailor!.images ?? [];
    final hasImages = images.isNotEmpty;
    final showImageNavigation = images.length > 1;

    return Scaffold(
      backgroundColor: AppColors.chalk,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.indigo,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(builder: (context, constraints) {
              return FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image carousel / gallery
                    if (hasImages)
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _currentImage = i),
                            itemBuilder: (context, index) {
                              final url = images[index];
                              return Image.network(
                                ApiClient.storageProxyUrl(url),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.indigoDeep,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 60, color: AppColors.linen),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (showImageNavigation)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  '${_currentImage + 1}/${images.length}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.indigo, AppColors.indigoLight],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.photo_library,
                                  size: 72, color: AppColors.linen),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada portofolio',
                                style: TextStyle(
                                  color: AppColors.linen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Top-left floating back button
                    Positioned(
                      left: 12,
                      top: topPadding + 8,
                      child: Material(
                        color: Colors.black26,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      ),
                    ),

                    // Image indicator (bottom-center)
                    if (showImageNavigation)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImage == i ? 18 : 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentImage == i
                                    ? AppColors.white
                                    : AppColors.white.withAlpha(128),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.red : Colors.white),
                onPressed: _favoriteBusy ? null : _toggleFavorite,
              ),
            ],
          ),

          if (showImageNavigation)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 76,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final url = images[index];
                          final selected = index == _currentImage;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() => _currentImage = index);
                            },
                            child: Container(
                              width: 76,
                              margin: EdgeInsets.only(
                                right: index == images.length - 1 ? 0 : 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? AppColors.gold
                                      : AppColors.white,
                                  width: selected ? 2.2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  ApiClient.storageProxyUrl(url),
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppColors.chalk,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                    color: AppColors.indigoDeep,
                                    child: const Icon(Icons.broken_image,
                                        color: AppColors.white),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Small avatar/icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.indigoDeep.withAlpha(28),
                                blurRadius: 14,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.content_cut,
                              color: AppColors.indigo, size: 32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_tailor!.shopName,
                              style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                RatingStars(
                                    rating: _tailor!.ratingAvg,
                                    count: _tailor!.ratingCount),
                                const SizedBox(width: 8),
                                Text('(${_tailor!.ratingCount})',
                                    style: const TextStyle(
                                        color: AppColors.charcoalSoft,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: AppColors.sagePale,
                                  borderRadius: BorderRadius.circular(99)),
                              child: const Text('✓ Terverifikasi',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sage)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),
                  const StitchDivider(),
                  const SizedBox(height: 12),

                  // Skills / categories (like variants)
                  Text('Keahlian',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold)),
                  const SizedBox(height: 8),
                  if ((_tailor!.skills ?? []).isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tailor!.skills!
                          .map((s) => Chip(
                                label: Text(s),
                                backgroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: AppColors.charcoalSoft.withAlpha(15)),
                                    borderRadius: BorderRadius.circular(8)),
                              ))
                          .toList(),
                    )
                  else
                    const Text('Belum ada keahlian terdaftar.'),

                  const SizedBox(height: 16),
                  const StitchDivider(),
                  const SizedBox(height: 12),

                  // Reviews header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ulasan Pelanggan',
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton(
                          onPressed: () {},
                          child: const Text('Lihat Semua'))
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_tailor!.ratingCount > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(_tailor!.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RatingStars(rating: _tailor!.ratingAvg, size: 14),
                              const SizedBox(height: 4),
                              Text('${_tailor!.ratingCount} penilaian',
                                  style: const TextStyle(
                                      color: AppColors.charcoalSoft))
                            ],
                          )
                        ]),
                        const SizedBox(height: 12),
                        if (_tailor!.reviews != null && _tailor!.reviews!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _tailor!.reviews!
                                .map((review) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: Card(
                                        elevation: 0,
                                        color: AppColors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(review.pelangganName ??
                                                          'Pelanggan',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  RatingStars(
                                                      rating:
                                                          review.rating.toDouble(),
                                                      size: 14),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(review.comment ??
                                                  'Tidak ada komentar.'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          )
                        else
                          const Text('Belum ada ulasan.'),
                      ],
                    )
                  else
                    const Text('Belum ada ulasan.'),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky bottom bar with Chat, Favorite, and primary action
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: AppColors.chalk,
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))
            ],
          ),
          child: Row(
            children: [
              // Chat
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatService: ChatService(widget.apiClient),
                        tailorProfileId: _tailor!.id,
                        tailorName: _tailor!.shopName,
                        tailorAvatarUrl: _tailor!.images?.isNotEmpty == true ? _tailor!.images!.first : null,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                color: AppColors.indigo,
              ),

              // Favorite
              IconButton(
                onPressed: _favoriteBusy ? null : _toggleFavorite,
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.red : AppColors.charcoalSoft),
              ),

              const SizedBox(width: 8),

              // Primary action
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderFormScreen(
                        tailorId: _tailor!.id,
                        orderService: widget.orderService,
                        apiClient: widget.apiClient,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Buat Pesanan Permak'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
