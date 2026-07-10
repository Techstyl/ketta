class Conversation {
  final String id;
  final String productId;
  final String productTitle;
  final String buyerId;
  final String buyerName;
  final String farmerId;
  final String farmerName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.buyerName,
    required this.farmerId,
    required this.farmerName,
    this.lastMessage,
    this.lastMessageAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productTitle: json['product_title'] as String? ?? '',
      buyerId: json['buyer_id'] as String,
      buyerName: json['buyer_name'] as String? ?? '',
      farmerId: json['farmer_id'] as String,
      farmerName: json['farmer_name'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
