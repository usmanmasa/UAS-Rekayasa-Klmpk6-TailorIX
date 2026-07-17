import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

import 'api_client.dart';

typedef RealtimePayloadHandler = void Function(Map<String, dynamic> payload);

class RealtimeService {
  final ApiClient apiClient;
  late final PusherClient _pusher;
  final Map<String, Channel> _channels = {};
  bool _connected = false;

  RealtimeService(this.apiClient) {
    final apiKey = dotenv.env['REVERB_APP_KEY'] ?? 'tailorlx_dev_key';
    final host = dotenv.env['REVERB_HOST'] ?? 'localhost:8080';
    final authEndpoint = '${ApiClient.baseHost}/broadcasting/auth';

    debugPrint('[RealtimeService] Initializing with:');
    debugPrint('  • API Key: $apiKey');
    debugPrint('  • Host: $host');
    debugPrint('  • Auth Endpoint: $authEndpoint');

    // Parse host and port
    final hostParts = host.split(':');
    final hostname = hostParts[0];
    final wsPort = hostParts.length > 1 ? int.tryParse(hostParts[1]) ?? 8080 : 8080;

    final options = PusherOptions(
      key: apiKey,
      host: hostname,
      wsPort: wsPort,
      wssPort: 443,
      encrypted: false, // Set to true if using wss://
      authOptions: PusherAuthOptions(
        authEndpoint,
        headers: () async {
          return apiClient.authHeaders;
        },
      ),
      autoConnect: false,
    );

    _pusher = PusherClient(options: options);

    _setupConnectionListeners();
  }

  void _setupConnectionListeners() {
    // Connection established
    _pusher.onConnectionEstablished((data) {
      _connected = true;
      debugPrint('[RealtimeService] ✓ Connected to Reverb');
      debugPrint('  • Socket ID: ${_pusher.socketId}');
    });

    // Connection error
    _pusher.onConnectionError((error) {
      _connected = false;
      debugPrint('[RealtimeService] ✗ Connection Error');
      debugPrint('  • Error: $error');
    });

    // General error
    _pusher.onError((error) {
      debugPrint('[RealtimeService] ✗ Error');
      debugPrint('  • Error: $error');
    });

    // Disconnected
    _pusher.onDisconnected((data) {
      _connected = false;
      debugPrint('[RealtimeService] ⚠ Disconnected from Reverb');
    });
  }

  bool get isConnected => _connected;

  /// Connect to Reverb WebSocket server
  Future<void> connect() async {
    if (_connected) {
      debugPrint('[RealtimeService] Already connected, skipping');
      return;
    }

    try {
      debugPrint('[RealtimeService] Connecting to Reverb...');
      _pusher.connect();

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 800));

      if (_connected) {
        debugPrint('[RealtimeService] ✓ Connection successful');
      } else {
        debugPrint('[RealtimeService] ⚠ Connection initiated, waiting for established...');
      }
    } catch (e) {
      debugPrint('[RealtimeService] ✗ Error connecting: $e');
      rethrow;
    }
  }

  /// Subscribe to a private channel (internal method)
  Future<void> subscribePrivateChannel(String channelName) async {
    if (_channels.containsKey(channelName)) {
      debugPrint('[RealtimeService] Already subscribed to $channelName');
      return;
    }

    try {
      debugPrint('[RealtimeService] Subscribing to private-$channelName...');

      final channel = _pusher.private(channelName);
      _channels[channelName] = channel;

      // Wait for subscription to be processed
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('[RealtimeService] ✓ Subscribed to private-$channelName');
    } catch (e) {
      debugPrint('[RealtimeService] ✗ Error subscribing to $channelName: $e');
      rethrow;
    }
  }

  /// Subscribe to user's conversation updates channel
  /// Listen for ConversationUpdated events from direct messages
  Future<void> subscribeUserConversationsChannel(int userId) async {
    return subscribePrivateChannel('user.$userId');
  }

  /// Subscribe to order chat channel for messages
  /// Listen for OrderChatMessageSent events
  Future<void> subscribeOrderChatChannel(int orderId) async {
    return subscribePrivateChannel('order.$orderId');
  }

  /// Subscribe to conversation channel for direct message sync
  /// Listen for ConversationUpdated events from a specific tailor profile
  Future<void> subscribeConversationChannel(int tailorProfileId) async {
    return subscribePrivateChannel('conversation.$tailorProfileId');
  }

  /// Listen to specific event on a channel
  /// Usage: listen('user.123', 'ConversationUpdated', (data) { ... })
  void listen(String channelName, String eventName, RealtimePayloadHandler callback) {
    final channel = _channels[channelName];
    if (channel == null) {
      debugPrint('[RealtimeService] ✗ Channel "$channelName" not subscribed!');
      debugPrint('[RealtimeService]   Available channels: ${_channels.keys.toList()}');
      return;
    }

    channel.bind(eventName, (message) {
      try {
        final data = message.data;
        if (data is Map<String, dynamic>) {
          callback(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            callback(decoded);
          }
        }
      } catch (e) {
        debugPrint('[RealtimeService] Error parsing event: $e');
      }
    });

    debugPrint('[RealtimeService] Bound "$eventName" on channel "$channelName"');
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String channelName) async {
    final channel = _channels.remove(channelName);
    if (channel != null) {
      try {
        _pusher.unsubscribe(channelName);
        debugPrint('[RealtimeService] ✓ Unsubscribed from $channelName');
      } catch (e) {
        debugPrint('[RealtimeService] ✗ Error unsubscribing from $channelName: $e');
      }
    }
  }

  /// Disconnect from Reverb
  void disconnect() {
    try {
      debugPrint('[RealtimeService] Disconnecting from Reverb...');

      // Unsubscribe from all channels
      for (final channelName in List<String>.from(_channels.keys)) {
        _pusher.unsubscribe(channelName);
      }
      _channels.clear();

      // Disconnect from server
      _pusher.disconnect();
      _connected = false;

      debugPrint('[RealtimeService] ✓ Disconnected from Reverb');
    } catch (e) {
      debugPrint('[RealtimeService] ✗ Error disconnecting: $e');
    }
  }
}
