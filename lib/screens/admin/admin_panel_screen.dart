import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  bool _shutdown = false;
  String _maintenanceMsg = '';
  String _forceVersion = '';
  bool _loading = true;
  List<AppUser> _users = [];

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
      final users = await admin.getAllUsers();
      if (mounted) {
        setState(() {
          _shutdown = shutdown;
          _maintenanceMsg = msg;
          _forceVersion = version ?? '';
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admin data: $e'), backgroundColor: Colors.red),
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
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: ListView(
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.people, color: AppTheme.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Text('${AppStrings.users} (${_users.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  if (_users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('No users', style: TextStyle(color: Colors.grey[500]))),
                    )
                  else
                    ..._users.map((user) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isFarmer ? Colors.green : Colors.blue,
                        child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(user.username),
                      subtitle: Text('${user.userType} • ${user.location ?? "No location"}'),
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
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
