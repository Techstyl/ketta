import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';
import '../../models/product.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  String _tab = 'dashboard';
  bool _shutdown = false;
  String _maintenanceMsg = '';
  String _forceVersion = '';
  bool _loading = true;
  List<AppUser> _users = [];
  List<Product> _products = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final admin = ref.read(adminServiceProvider);
      final shutdown = await admin.isShutdown();
      final msg = await admin.getShutdownMessage();
      final version = await admin.getForceUpdateVersion();
      final stats = await admin.getStats();
      final users = await admin.getAllUsers();
      final products = await admin.getAllProducts();
      if (mounted) {
        setState(() {
          _shutdown = shutdown;
          _maintenanceMsg = msg;
          _forceVersion = version ?? '';
          _stats = stats;
          _users = users;
          _products = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.adminPanel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminPanel),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() => _loading = true); _loadData(); },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _tabBtn('dashboard', Icons.dashboard, 'Dashboard'),
        _tabBtn('users', Icons.people, 'Users (${_stats['users'] ?? _users.length})'),
        _tabBtn('products', Icons.inventory_2, 'Products (${_stats['products'] ?? _products.length})'),
        _tabBtn('settings', Icons.settings, 'Settings'),
      ].map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _tabBtn(String tab, IconData icon, String label) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? AppTheme.primaryGreen : Colors.transparent, width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? AppTheme.primaryGreen : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.primaryGreen : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_tab) {
      case 'dashboard': return _buildDashboard();
      case 'users': return _buildUsers();
      case 'products': return _buildProducts();
      case 'settings': return _buildSettings();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final cards = [
      ('Users', _stats['users'] ?? 0, Icons.people, Colors.blue),
      ('Products', _stats['products'] ?? 0, Icons.inventory_2, AppTheme.primaryGreen),
      ('Active', _stats['active'] ?? 0, Icons.check_circle, Colors.green),
      ('Sold', _stats['sold'] ?? 0, Icons.sell, Colors.orange),
      ('Inquiries', _stats['inquiries'] ?? 0, Icons.chat, Colors.purple),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: cards.length,
          itemBuilder: (_, i) => Card(
            color: cards[i].$4.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cards[i].$3, color: cards[i].$4, size: 28),
                  const SizedBox(height: 8),
                  Text(cards[i].$2.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cards[i].$4)),
                  Text(cards[i].$1, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsers() {
    if (_users.isEmpty) {
      return Center(child: Text('No users', style: TextStyle(color: Colors.grey[500])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final user = _users[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: user.isFarmer ? Colors.green : Colors.blue,
            child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
          ),
          title: Text(user.username),
          subtitle: Text('${user.userType} • ${user.location ?? "—"}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete User'),
                  content: Text('Delete ${user.username}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(AppStrings.cancel)),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(AppStrings.confirm)),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(adminServiceProvider).deleteUser(user.id);
                _loadData();
              }
            },
          ),
          dense: true,
        );
      },
    );
  }

  Widget _buildProducts() {
    if (_products.isEmpty) {
      return Center(child: Text('No products', style: TextStyle(color: Colors.grey[500])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: p.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.images.first, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                  )
                : const Icon(Icons.image, size: 50),
            title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${p.farmerName ?? "?"} • \$${p.priceFormatted} • ${p.status}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: Text('Delete "${p.title}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(AppStrings.cancel)),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: Text(AppStrings.confirm)),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(adminServiceProvider).deleteProduct(p.id);
                  _loadData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.power_settings_new, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Text(AppStrings.shutdownApp, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Switch(
                    activeTrackColor: Colors.red,
                    value: _shutdown,
                    onChanged: (v) async {
                      await ref.read(adminServiceProvider).setShutdown(v, message: _maintenanceMsg);
                      setState(() => _shutdown = v);
                    },
                  ),
                ]),
                if (_shutdown) ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Maintenance Message',
                      hintText: 'App is under maintenance...',
                    ),
                    controller: TextEditingController.fromValue(TextEditingValue(text: _maintenanceMsg)),
                    onChanged: (v) => _maintenanceMsg = v,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(adminServiceProvider).setShutdown(true, message: _maintenanceMsg);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Maintenance message updated'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: Text(AppStrings.save),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.system_update, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Text(AppStrings.forceUpdate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Version',
                    hintText: '2.0.0',
                  ),
                  controller: TextEditingController.fromValue(TextEditingValue(text: _forceVersion)),
                  onChanged: (v) => _forceVersion = v,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(adminServiceProvider).setForceUpdate(_forceVersion);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Force update set'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: Text(AppStrings.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}