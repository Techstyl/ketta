import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../services/chat_service.dart';
import '../../models/conversation.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.favorites)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No favorites yet', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Save products you like to find them later',
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

final _inquiriesProvider = FutureProvider.autoDispose<List<Conversation>>((ref) =>
    ref.read(chatServiceProvider).getConversations());

class BuyerInquiriesScreen extends ConsumerWidget {
  const BuyerInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(_inquiriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.inquiries)),
      body: conversations.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(AppStrings.noMessages, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final conv = list[i];
              return Card(
                child: ListTile(
                  title: Text(conv.productTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${conv.farmerName} - ${conv.buyerName}'),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                  onTap: () => Navigator.pushNamed(context, '/chat', arguments: conv),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
