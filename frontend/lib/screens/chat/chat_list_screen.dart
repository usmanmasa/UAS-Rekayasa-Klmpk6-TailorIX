import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_screen.dart';

/// Chat list / conversations screen
class ChatListScreen extends StatefulWidget {
  final ApiClient apiClient;
  final OrderService orderService;
  final int currentUserId;

  const ChatListScreen({super.key, required this.apiClient, required this.orderService, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  late final ChatService _chatService;
  bool _loading = true;
  List<Map<String, dynamic>> _conversations = [];
  String _filter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.apiClient);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('[ChatListScreen] App resumed, reloading conversations');
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final conv = await _chatService.listConversations();
        if (!mounted) {
          return;
        }
      setState(() => _conversations = conv);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat percakapan: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.toLowerCase();
    final list = _conversations.where((c) {
      if (_filter == 'active' && (c['unread_count'] as int? ?? 0) == 0) return false;
      if (q.isNotEmpty) {
        final participant = c['participant'] as Map<String, dynamic>?;
        final name = (participant?['name'] ?? c['tailor']?['shop_name'] ?? '').toString().toLowerCase();
        final last = (c['last_message'] ?? '').toString().toLowerCase();
        return name.contains(q) || last.contains(q);
      }
      return true;
    }).toList();
    
    // Sort by last_message_at (newest first)
    list.sort((a, b) {
      final aTime = DateTime.tryParse(a['last_message_at']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['last_message_at']?.toString() ?? '');
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime); // Newest first
    });
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Kontak, Penjahit, & Pesan',
                  prefixIcon: const Icon(Icons.search, color: AppColors.charcoalSoft),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
                    selectedColor: AppColors.goldPale,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Aktif'),
                    selected: _filter == 'active',
                    onSelected: (_) => setState(() => _filter = 'active'),
                    selectedColor: AppColors.goldPale,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.gold,
                      child: ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final c = _filtered[i];
                          final participant = c['participant'] as Map<String, dynamic>?;
                          final tailor = c['tailor'] as Map<String, dynamic>?;
                          final name = participant?['name'] as String? ?? tailor?['shop_name'] as String? ?? 'Chat';
                          final avatar = participant?['avatar_url'] as String? ?? tailor?['avatar_url'] as String?;
                          final unread = c['unread_count'] as int? ?? 0;
                          final tailorProfileId = c['tailor_profile_id'] as int;
                          
                          return ListTile(
                            onTap: () => _openChat(tailorProfileId, name, avatar),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.linen,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null ? const Icon(Icons.content_cut, color: AppColors.indigo) : null,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(c['last_message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_formatTime(c['last_message_at'])),
                                if (unread > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(int tailorProfileId, String? tailorName, String? avatar) async {
    // Mark conversation as read
    try {
      await _chatService.markConversationAsRead(tailorProfileId);
    } catch (e) {
      debugPrint('[ChatListScreen] Error marking conversation as read: $e');
    }
    
      if (!mounted) {
        return;
      }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatService: ChatService(widget.apiClient),
          tailorProfileId: tailorProfileId,
          tailorName: tailorName,
          tailorAvatarUrl: avatar,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    
    // Refresh list when returning from ChatScreen
    if (mounted && result == true) {
      _load();
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    try {
      DateTime dt;
      final rawStr = raw.toString();
      // Parse with timezone handling: assume backend sends UTC
      if (rawStr.endsWith('Z')) {
        dt = DateTime.parse(rawStr).toLocal();
      } else {
        final parsed = DateTime.tryParse(rawStr);
        dt = (parsed ?? DateTime.now()).toLocal();
      }
      final now = DateTime.now();
      final diff = now.difference(dt);
      // Format: "4 Jul 10:51" for today, "4 Jul" for past days
      if (diff.inDays == 0) {
        // Same day: show time with date
        final hours = dt.hour.toString().padLeft(2, '0');
        final minutes = dt.minute.toString().padLeft(2, '0');
        return '${dt.day} Jul $hours:$minutes';
      } else if (diff.inDays == 1) {
        return 'yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${dt.day}/${dt.month}';
      }
    } catch (_) {
      return '';
    }
  }
}
