import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/product_service.dart';
import '../../services/chat_service.dart';

final _myProductsProvider = FutureProvider.autoDispose<List>((ref) =>
    ref.read(productServiceProvider).getMyProducts());

final _inquiriesProvider = FutureProvider.autoDispose<List>((ref) =>
    ref.read(chatServiceProvider).getConversations());

class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 3 ? AppStrings.market : AppStrings.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: AppStrings.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2), label: AppStrings.myListings),
          BottomNavigationBarItem(icon: const Icon(Icons.contact_mail), label: AppStrings.buyerInquiries),
          BottomNavigationBarItem(icon: const Icon(Icons.store), label: AppStrings.market),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/post-product'),
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.darkGreen,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.postProduct),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardView();
      case 1:
        return const _MyProductsView();
      case 2:
        return const _InquiriesView();
      case 3:
        return const _MarketView();
      default:
        return const SizedBox();
    }
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: Future.wait([
        ref.read(productServiceProvider).getProductCount(),
        ref.read(productServiceProvider).getActiveCount(),
        ref.read(productServiceProvider).getSoldCount(),
        ref.read(chatServiceProvider).getInquiryCount(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text('${snapshot.error}', style: TextStyle(color: Colors.red[300])),
            ],
          ));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data as List<int>;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.welcome,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _StatCard(
                  icon: Icons.inventory_2, label: AppStrings.totalProducts,
                  value: '${data[0]}', color: AppTheme.primaryGreen,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.check_circle, label: AppStrings.activeListings,
                  value: '${data[1]}', color: AppTheme.gold,
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatCard(
                  icon: Icons.shopping_cart, label: AppStrings.soldItems,
                  value: '${data[2]}', color: AppTheme.earth,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.contact_mail, label: AppStrings.newInquiries,
                  value: '${data[3]}', color: Colors.blue,
                )),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/post-product'),
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.postProduct),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _MyProductsView extends ConsumerWidget {
  const _MyProductsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_myProductsProvider);

    return productsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(AppStrings.noProducts, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/post-product'),
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.postProduct),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_myProductsProvider),
          child: ListView.builder(
            key: const PageStorageKey('my_products'),
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) => _ProductListItem(product: list[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text('$e', style: TextStyle(color: Colors.red[300])),
        ],
      )),
    );
  }
}

class _ProductListItem extends ConsumerWidget {
  final dynamic product;
  const _ProductListItem({required this.product});

  Color _statusColor() {
    switch (product.status) {
      case 'active': return Colors.green;
      case 'sold': return Colors.grey;
      case 'out_of_stock': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (product.status) {
      case 'active': return AppStrings.active;
      case 'sold': return AppStrings.sold;
      case 'out_of_stock': return 'Out of Stock';
      default: return product.status;
    }
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(product.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${product.priceFormatted} ብር / ${product.unit}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                title: const Text('Edit Product'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/post-product', arguments: product);
                },
              ),
              if (product.status == 'active') ...[
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                  title: const Text('Mark as Out of Stock'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(productServiceProvider).updateProduct(product.id, {'status': 'out_of_stock'});
                    ref.invalidate(_myProductsProvider);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: const Text('Mark as Sold'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(productServiceProvider).updateProduct(product.id, {'status': 'sold'});
                    ref.invalidate(_myProductsProvider);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Product', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context, builder: (c) => AlertDialog(
                      title: const Text('Delete Product'),
                      content: Text('Delete "${product.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(productServiceProvider).deleteProduct(product.id);
                    ref.invalidate(_myProductsProvider);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: AppTheme.cream, borderRadius: BorderRadius.circular(12)),
          child: product.images.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(product.images[0], fit: BoxFit.cover, filterQuality: FilterQuality.high, errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey[400])),
                )
              : const Icon(Icons.image, color: Colors.grey),
        ),
        title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${product.priceFormatted} ብር / ${product.unit} • ${product.location}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_statusLabel(),
                  style: TextStyle(fontSize: 11, color: _statusColor(), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
        onTap: () => _showActions(context, ref),
      ),
    );
  }
}

class _MarketView extends ConsumerStatefulWidget {
  const _MarketView();
  @override
  ConsumerState<_MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends ConsumerState<_MarketView> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'All', 'name_am': 'ሁሉም', 'icon': Icons.all_inclusive},
    {'id': 1, 'name': 'Teff', 'name_am': 'ጤፍ', 'icon': Icons.grass},
    {'id': 2, 'name': 'Maize', 'name_am': 'በቆሎ', 'icon': Icons.grass},
    {'id': 3, 'name': 'Wheat', 'name_am': 'ስንዴ', 'icon': Icons.grass},
    {'id': 4, 'name': 'Coffee', 'name_am': 'ቡና', 'icon': Icons.coffee},
    {'id': 5, 'name': 'Beans', 'name_am': 'አተር', 'icon': Icons.eco},
    {'id': 6, 'name': 'Other', 'name_am': 'ሌላ', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.search,
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat['id']?.toString();
              final label = AppStrings.isAmharic ? cat['name_am'] as String : cat['name'] as String;
              return FilterChip(
                label: Text(label),
                selected: selected,
                avatar: Icon(cat['icon'] as IconData, size: 18, color: selected ? Colors.white : AppTheme.primaryGreen),
                selectedColor: AppTheme.primaryGreen,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13),
                onSelected: (_) => setState(() {
                  _selectedCategory = cat['id']?.toString();
                }),
              );
            },
          ),
        ),
        Expanded(child: products.when(
          data: (list) {
            var filtered = list;
            if (_selectedCategory != null) {
              filtered = filtered.where((p) => p.categoryId.toString() == _selectedCategory).toList();
            }
            if (_searchQuery.isNotEmpty) {
              filtered = filtered.where((p) =>
                p.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
            }
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(AppStrings.noProducts, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(productsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _MarketProductCard(product: filtered[i]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        )),
      ],
    );
  }
}

class _MarketProductCard extends StatelessWidget {
  final dynamic product;
  const _MarketProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (hasImage)
                  Image.network(product.images[0], height: 180, width: double.infinity, fit: BoxFit.cover, filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => Container(height: 180, color: AppTheme.cream, child: const Icon(Icons.agriculture, size: 64, color: AppTheme.primaryGreen)))
                else
                  Container(height: 140, color: AppTheme.cream, child: const Center(child: Icon(Icons.agriculture, size: 64, color: AppTheme.primaryGreen))),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${product.priceFormatted} ብር / ${product.unit}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!hasImage)
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkGreen.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(product.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.gold.withValues(alpha: 0.2),
                    child: Text(product.farmerName?.isNotEmpty == true ? product.farmerName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage)
                          Text(product.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.person, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(product.farmerName ?? 'Unknown',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(product.location ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${product.quantity} ${product.unit}',
                      style: TextStyle(color: AppTheme.darkGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiriesView extends ConsumerWidget {
  const _InquiriesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convAsync = ref.watch(_inquiriesProvider);

    return convAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contact_mail, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(AppStrings.noMessages, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
              ],
            ),
          );
        }
        return ListView.builder(
          key: const PageStorageKey('inquiries'),
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  child: Text(c.buyerName.isNotEmpty ? c.buyerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
                title: Text(c.buyerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.productTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryGreen),
                onTap: () => Navigator.pushNamed(context, '/chat', arguments: c),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text('$e', style: TextStyle(color: Colors.red[300])),
        ],
      )),
    );
  }
}
