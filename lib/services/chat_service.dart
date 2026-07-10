import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api;
  io.Socket? _socket;

  ChatService(this._api);

  void connectSocket(String token) {
    _socket = io.io(AppConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'extraHeaders': {'Authorization': 'Bearer $token'},
      'auth': {'token': token},
    });
    _socket?.connect();
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  io.Socket? get socket => _socket;

  void joinConversation(String conversationId) {
    _socket?.emit('join:conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave:conversation', conversationId);
  }

  void sendMessageViaSocket(String conversationId, String content, {String? imageUrl}) {
    _socket?.emit('send:message', {
      'conversationId': conversationId,
      'content': content,
      'imageUrl': imageUrl,
    });
  }

  void emitTyping(String conversationId) {
    _socket?.emit('typing:start', conversationId);
  }

  void emitStopTyping(String conversationId) {
    _socket?.emit('typing:stop', conversationId);
  }

  Future<Conversation?> getExistingConversation(
    String productId, String buyerId, String farmerId) async {
    final conversations = await getConversations();
    try {
      return conversations.firstWhere(
        (c) => c.productId == productId && c.buyerId == buyerId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Conversation> createConversation(
    String productId, String productTitle,
    String buyerId, String buyerName,
    String farmerId, String farmerName,
  ) async {
    final data = await _api.post('/chat/conversations', {
      'productId': productId,
      'productTitle': productTitle,
      'farmerId': farmerId,
      'farmerName': farmerName,
    });
    return Conversation.fromJson(data);
  }

  Future<List<Conversation>> getConversations() async {
    final data = await _api.getList('/chat/conversations');
    return data.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final data = await _api.getList('/chat/conversations/$conversationId/messages');
    return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? imageUrl,
  }) async {
    await _api.post('/chat/messages', {
      'conversationId': conversationId,
      'content': content,
      'imageUrl': imageUrl,
    });
  }

  Future<int> getInquiryCount() async {
    final data = await _api.get('/chat/inquiry-count');
    return data['count'] as int? ?? 0;
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(apiServiceProvider));
});
