import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_model.dart';
import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

/// F-06: Chat dengan penjahit terkait pesanan tertentu.
class ChatScreen extends StatefulWidget {
  final ChatService chatService;
  final int? orderId;
  final int? tailorProfileId;
  final int currentUserId;
  final String? tailorName;
  final String? tailorAvatarUrl;
  final String? tailorStatus;

  const ChatScreen({
    super.key,
    required this.chatService,
    this.orderId,
    this.tailorProfileId,
    required this.currentUserId,
    this.tailorName,
    this.tailorAvatarUrl,
    this.tailorStatus,
  }) : assert(orderId != null || tailorProfileId != null, 'Either orderId or tailorProfileId must be provided');

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    
    // Mark conversation as read when opening (for direct conversations)
    if (widget.tailorProfileId != null) {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    try {
      if (widget.tailorProfileId != null) {
        await widget.chatService.markConversationAsRead(widget.tailorProfileId!);
        debugPrint('[ChatScreen] Conversation marked as read');
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error marking as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final messages = widget.orderId != null
        ? await widget.chatService.getMessages(widget.orderId!)
        : await widget.chatService.getConversationMessages(widget.tailorProfileId!);
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _scrollToBottom();
  }

  bool _sendingMedia = false;

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      debugPrint('[ChatScreen] Sending message: "$text"');
      
      final sent = widget.orderId != null
          ? await widget.chatService.sendMessage(widget.orderId!, text)
          : await widget.chatService.sendConversationMessage(widget.tailorProfileId!, text);

      debugPrint('[ChatScreen] Message sent successfully. ID: ${sent.id}, sender: ${sent.senderId}, created_at: ${sent.createdAt}');

      if (mounted) {
        setState(() {
          _messageController.clear();
          _messages = [..._messages, sent];
        });
        _scrollToBottom();
      }
    } catch (e, st) {
      debugPrint('[ChatScreen] Error sending message: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _onAttachmentPressed() async {
    if (widget.tailorProfileId == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pickAndSendImage(source);
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) {
      debugPrint('[ChatScreen] Image selection cancelled');
      return;
    }

    setState(() => _sendingMedia = true);
    try {
      debugPrint('[ChatScreen] Uploading image: ${pickedFile.path}');
      final uploadService = UploadService(widget.chatService.api);
      final path = await uploadService.uploadImage(pickedFile);
      debugPrint('[ChatScreen] Image uploaded successfully. Path: $path');

      debugPrint('[ChatScreen] Sending conversation image message...');
      final sent = await widget.chatService.sendConversationImage(widget.tailorProfileId!, path);
      debugPrint('[ChatScreen] Image message sent successfully. ID: ${sent.id}');

      if (mounted) {
        setState(() => _messages = [..._messages, sent]);
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil dikirim'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[ChatScreen] Error uploading/sending image: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim gambar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingMedia = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tailorName = widget.tailorName ?? 'Penjahit';
    final tailorStatus = widget.tailorStatus ?? 'Online';
    final avatar = widget.tailorAvatarUrl;

    return Scaffold(
      backgroundColor: AppColors.chalk,
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true), // Pop with result=true to signal list refresh
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.linen,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null ? const Icon(Icons.content_cut, color: AppColors.indigo) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tailorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(tailorStatus, style: const TextStyle(fontSize: 12, color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const EmptyState(
                        emoji: '💬',
                        title: 'Belum ada percakapan',
                        description: 'Kirim pesan untuk memulai chat dengan penjahit.',
                      )
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        children: _buildMessageItems(context),
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.linenDark)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sendingMedia ? null : _onAttachmentPressed,
                  icon: _sendingMedia
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline, color: AppColors.indigo),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.linen, borderRadius: BorderRadius.circular(999)),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis Pesan...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessageItems(BuildContext context) {
    final widgets = <Widget>[];
    DateTime? currentDate;

    for (final msg in _messages) {
      // Use local time for date comparison
      final localTime = msg.createdAt.isUtc ? msg.createdAt.toLocal() : msg.createdAt;
      final date = DateTime(localTime.year, localTime.month, localTime.day);
      if (currentDate == null || date.difference(currentDate).inDays != 0) {
        currentDate = date;
        widgets.add(_buildDateSeparator(localTime));
      }
      widgets.add(_buildMessageBubble(context, msg));
    }

    return widgets;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.linenDark)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: AppColors.charcoalSoft)),
          ),
          const Expanded(child: Divider(color: AppColors.linenDark)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
    final isMine = msg.senderId == widget.currentUserId;
    final bubbleColor = isMine ? AppColors.indigo : AppColors.white;
    final textColor = isMine ? Colors.white : AppColors.charcoal;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: isMine
              ? null
              : [BoxShadow(color: AppColors.indigoDeep.withAlpha(12), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  ApiClient.storageProxyUrl(msg.attachmentPath!),
                  width: MediaQuery.of(context).size.width * 0.62,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: MediaQuery.of(context).size.width * 0.62,
                    height: 180,
                    color: AppColors.linen,
                    child: const Center(child: Icon(Icons.broken_image, color: AppColors.charcoalSoft)),
                  ),
                ),
              )
            else
              Text(msg.message, style: TextStyle(color: textColor, fontSize: 13.2)),
            const SizedBox(height: 6),
            Text(_formatTime(msg.createdAt), style: TextStyle(color: textColor.withAlpha((0.72 * 255).round()), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // _formatDate moved to bottom of file to avoid duplication

  String _formatTime(DateTime dateTime) {
    // Ensure we're using local time
    final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final local = date.isUtc ? date.toLocal() : date;
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}
