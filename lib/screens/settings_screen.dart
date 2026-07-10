import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/localization.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          userAsync.when(
            data: (user) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  radius: 28,
                  child: Text(
                    user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user?.username ?? 'User', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(user?.userType ?? ''),
              ),
            ),
            loading: () => const Card(child: ListTile(leading: CircularProgressIndicator(), title: Text('Loading...'))),
            error: (e, _) => const Card(child: ListTile(title: Text('Error'))),
          ),
          const SizedBox(height: 24),
          const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppTheme.primaryGreen),
              title: Text(AppStrings.language),
              subtitle: Text(AppStrings.isAmharic ? 'አማርኛ' : 'English'),
              trailing: Switch(
                activeTrackColor: AppTheme.primaryGreen,
                value: AppStrings.isAmharic,
                onChanged: (v) {
                  AppStrings.isAmharic = v;
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(AppStrings.logout, style: const TextStyle(color: Colors.red)),
              onTap: () async {
                await ref.read(authServiceProvider).logout();
                ref.read(chatServiceProvider).disconnectSocket();
                ref.invalidate(currentUserProvider);
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('ቀጥታ v1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
