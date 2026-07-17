import 'dart:developer' as developer;

import '../models/chat_model.dart';
import 'api_client.dart';

/// F-06: chat antara pelanggan dan penjahit per pesanan
class ChatService {
  final ApiClient api;
  ChatService(this.api);

  Future<List<ChatMessage>> getMessages(int orderId) async {
    final res = await api.get('/orders/$orderId/chats');
    return (res as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendMessage(int orderId, String message) async {
    developer.log('[ChatService] Sending message to order $orderId', name: 'ChatService');
    final res = await api.post('/orders/$orderId/chats', {
      'message_type': 'text',
      'message': message,
    });
    developer.log('[ChatService] Response from POST /orders/$orderId/chats: $res', name: 'ChatService');
    return ChatMessage.fromJson(res);
  }

  // Direct chat (not tied to an order)
  Future<List<ChatMessage>> getConversationMessages(int tailorProfileId) async {
    final res = await api.get('/conversations/$tailorProfileId');
    return (res as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendConversationMessage(int tailorProfileId, String message) async {
    developer.log('[ChatService] Sending conversation message to tailor $tailorProfileId', name: 'ChatService');
    final res = await api.post('/conversations/$tailorProfileId/messages', {
      'message_type': 'text',
      'message': message,
    });
    developer.log('[ChatService] Response from POST /conversations/$tailorProfileId/messages: $res', name: 'ChatService');
    return ChatMessage.fromJson(res);
  }

  Future<ChatMessage> sendConversationImage(int tailorProfileId, String attachmentPath) async {
    developer.log('[ChatService] Sending conversation image to tailor $tailorProfileId', name: 'ChatService');
    final res = await api.post('/conversations/$tailorProfileId/messages', {
      'message_type': 'image',
      'message': '',
      'attachment_path': attachmentPath,
    });
    developer.log('[ChatService] Response from POST /conversations/$tailorProfileId/messages (image): $res', name: 'ChatService');
    return ChatMessage.fromJson(res);
  }

  Future<List<ChatMessage>> getMessagesDirect(int tailorProfileId) async {
    return getConversationMessages(tailorProfileId);
  }

  Future<ChatMessage> sendMessageDirect(int tailorProfileId, String message) async {
    return sendConversationMessage(tailorProfileId, message);
  }

  /// List conversations (summary per tailor) - expected response: List of {
  ///  tailor_profile_id, tailor: {id, shop_name, avatar_url?}, last_message, last_message_at, unread_count
  /// }
  Future<List<Map<String, dynamic>>> listConversations() async {
    final res = await api.get('/conversations');
    // Expect the API to return a JSON array of conversation objects.
    return (res as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Mark conversation as read for the given tailor profile
  Future<void> markConversationAsRead(int tailorProfileId) async {
    developer.log('[ChatService] Marking conversation $tailorProfileId as read', name: 'ChatService');
    await api.put('/conversations/$tailorProfileId/mark-read', {});
    developer.log('[ChatService] Conversation $tailorProfileId marked as read', name: 'ChatService');
  }
}
