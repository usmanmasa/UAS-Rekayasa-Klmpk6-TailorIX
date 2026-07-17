import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';

enum WebNavPage { home, search, orders, favorites }

enum ProfileMenuAction { profile, settings, logout }

class WebNavbar extends StatelessWidget {
  final WebNavPage activePage;
  final VoidCallback onHome;
  final VoidCallback onSearch;
  final VoidCallback onOrders;
  final VoidCallback onFavorites;
  final Widget? trailing;
  final int unreadNotificationCount;
  final VoidCallback? onNotifications;
  final String userInitial;
  final String? userPhoto;
  final ValueChanged<ProfileMenuAction>? onProfileSelected;

  const WebNavbar({
    super.key,
    required this.activePage,
    required this.onHome,
    required this.onSearch,
    required this.onOrders,
    required this.onFavorites,
    this.trailing,
    this.unreadNotificationCount = 0,
    this.onNotifications,
    this.userInitial = 'A',
    this.userPhoto,
    this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFAF6EF);

    return Container(
      color: bg,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE6E1D6), width: 0.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.content_cut, color: Color(0xFF1E3A5F)),
                        SizedBox(width: 8),
                        Text('TailorLX', style: TextStyle(color: Color(0xFF1E3A5F), fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WebNavItem(label: 'Beranda', active: activePage == WebNavPage.home, onTap: onHome),
                        const SizedBox(width: 28),
                        _WebNavItem(label: 'Pencarian', active: activePage == WebNavPage.search, onTap: onSearch),
                        const SizedBox(width: 28),
                        _WebNavItem(label: 'Pesanan', active: activePage == WebNavPage.orders, onTap: onOrders),
                        const SizedBox(width: 28),
                        _WebNavItem(label: 'Favorit', active: activePage == WebNavPage.favorites, onTap: onFavorites),
                      ],
                    ),
                    if (trailing != null) ...[
                      const Spacer(),
                      Expanded(child: trailing!),
                    ] else ...[
                      const Spacer(),
                    ],
                    if (onNotifications != null || onProfileSelected != null) ...[
                      const SizedBox(width: 24),
                      if (onNotifications != null)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: onNotifications,
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_none, color: Color(0xFF5A5A56), size: 24),
                                if (unreadNotificationCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (onNotifications != null && onProfileSelected != null)
                        const SizedBox(width: 16),
                      if (onProfileSelected != null)
                        PopupMenuButton<ProfileMenuAction>(
                          onSelected: onProfileSelected,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: ProfileMenuAction.profile, child: Text('Profil Saya')),
                            PopupMenuItem(value: ProfileMenuAction.settings, child: Text('Pengaturan')),
                            PopupMenuItem(value: ProfileMenuAction.logout, child: Text('Keluar')),
                          ],
                          child: userPhoto != null && userPhoto!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    ApiClient.storageProxyUrl(userPhoto!),
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.indigo,
                                      child: Text(userInitial.isNotEmpty ? userInitial[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.indigo,
                                  child: Text(userInitial.isNotEmpty ? userInitial[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebNavItem extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _WebNavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_WebNavItem> createState() => _WebNavItemState();
}

class _WebNavItemState extends State<_WebNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? AppColors.indigo
        : _hovering
            ? AppColors.charcoal
            : AppColors.charcoalSoft;
    final fontWeight = widget.active ? FontWeight.w700 : FontWeight.w600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              color: color,
              fontWeight: fontWeight,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
