class ChatMessage {
  final int id;
  final int? orderId;
  final int senderId;
  final String message;
  final String messageType;
  final String? attachmentPath;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    this.orderId,
    required this.senderId,
    required this.message,
    required this.messageType,
    this.attachmentPath,
    required this.createdAt,
  });

  bool get isImage => messageType == 'image' && attachmentPath != null && attachmentPath!.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse created_at: backend returns ISO 8601 UTC format (e.g., "2026-07-05T10:51:00Z")
    // tryParse() assumes local time by default, so we need to handle UTC explicitly
    DateTime createdAt = DateTime.now();
    final rawTime = json['created_at'] ?? '';
    if (rawTime.isNotEmpty) {
      try {
        // If the string ends with 'Z', it's UTC; parse and convert to local
        if (rawTime.toString().endsWith('Z')) {
          createdAt = DateTime.parse(rawTime).toLocal();
        } else {
          // Otherwise, try parsing as ISO 8601
          final parsed = DateTime.tryParse(rawTime);
          if (parsed != null) {
            // Assume it's UTC from backend
            createdAt = parsed.toLocal();
          }
        }
      } catch (_) {
        createdAt = DateTime.now();
      }
    }
    return ChatMessage(
      id: json['id'],
      orderId: json['order_id'],
      senderId: json['sender_id'],
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      attachmentPath: json['attachment_path'],
      createdAt: createdAt,
    );
  }
}
