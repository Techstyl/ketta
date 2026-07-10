import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
  if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
  if (diff.inDays > 7) return '${diff.inDays ~/ 7}w';
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  return '${diff.inMinutes}m';
}

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;
  String? _selectedCategory;
  String _searchQuery = '';
  String _sortBy = 'newest';

  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'All', 'name_am': 'ሁሉም', 'icon': Icons.grid_view_rounded},
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

  List<Product> _applyFilters(List<Product> list) {
    var filtered = list.where((p) => p.status == 'active').toList();

    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.categoryId.toString() == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
        p.title.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false) ||
        p.location.toLowerCase().contains(q)
      ).toList();
    }

    if (_sortBy == 'price_asc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  Map<int?, int> _countByCategory(List<Product> products) {
    final active = products.where((p) => p.status == 'active').toList();
    final counts = <int?, int>{};
    for (final p in active) {
      counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
    }
    counts[null] = active.length;
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
          });
          return const SizedBox();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('ቀጥታ'),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_outline),
                onPressed: () => Navigator.pushNamed(context, '/favorites'),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) {
              if (i == 1) Navigator.pushNamed(context, '/favorites');
              else if (i == 2) Navigator.pushNamed(context, '/buyer-inquiries');
              else setState(() => _selectedIndex = i);
            },
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppStrings.home),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: AppStrings.favorites),
              BottomNavigationBarItem(icon: const Icon(Icons.chat), label: AppStrings.inquiries),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildBody() {
    final products = ref.watch(productsProvider);

    return products.when(
      data: (list) {
        final filtered = _applyFilters(list);
        final counts = _countByCategory(list);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(productsProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryGrid(counts)),
              if (filtered.isNotEmpty)
                SliverToBoxAdapter(child: _buildTrendingSection(filtered)),
              SliverToBoxAdapter(child: _buildFeedHeader(filtered.length)),
              if (filtered.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ProductCard(product: filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ምርት ፈልግ...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: AppTheme.primaryGreen),
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'newest', child: Text(AppStrings.isAmharic ? 'አዲስ' : 'Newest')),
                  PopupMenuItem(value: 'price_asc', child: Text(AppStrings.isAmharic ? 'ዋጋ በትንሽ' : 'Price: Low')),
                  PopupMenuItem(value: 'price_desc', child: Text(AppStrings.isAmharic ? 'ዋጋ በትልቅ' : 'Price: High')),
                ],
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildCategoryGrid(Map<int?, int> counts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.isAmharic ? 'ምድቦች' : 'Categories',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat['id']?.toString();
              final label = AppStrings.isAmharic ? cat['name_am'] as String : cat['name'] as String;
              final count = counts[cat['id']] ?? 0;

              return Material(
                color: selected ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 1,
                shadowColor: Colors.black12,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    _selectedCategory = _selectedCategory == cat['id']?.toString() ? null : cat['id']?.toString();
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: selected ? null : Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'] as IconData, size: 30, color: selected ? Colors.white : AppTheme.primaryGreen),
                        const SizedBox(height: 6),
                        Text(label, style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.black87,
                        ), textAlign: TextAlign.center),
                        Text('$count ${AppStrings.isAmharic ? "ምርቶች" : "ads"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white70 : Colors.grey[500],
                          )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(List<Product> products) {
    final trending = products.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Text(
                AppStrings.isAmharic ? 'ተወዳጅ ምርቶች' : 'Trending',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _TrendingCard(product: trending[i]),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFeedHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            AppStrings.isAmharic ? 'ሁሉም ምርቶች' : 'All Products',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(AppStrings.noProducts, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Product product;
  const _TrendingCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(product.images[0], fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Container(color: AppTheme.cream, child: const Icon(Icons.agriculture, size: 32, color: AppTheme.primaryGreen)))
                    else
                      Container(color: AppTheme.cream, child: const Center(child: Icon(Icons.agriculture, size: 32, color: AppTheme.primaryGreen))),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                        child: Text('${product.priceFormatted} ብር/${product.unit}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on, size: 11, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(child: Text(product.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.images.isNotEmpty;
    final timeAgo = _timeAgo(product.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (hasImage)
                    Image.network(product.images[0], height: 190, width: double.infinity, fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => Container(height: 190, color: AppTheme.cream, child: const Icon(Icons.agriculture, size: 64, color: AppTheme.primaryGreen)))
                  else
                    Container(height: 160, color: AppTheme.cream, child: const Center(child: Icon(Icons.agriculture, size: 64, color: AppTheme.primaryGreen))),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text('${product.priceFormatted} ብር/${product.unit}',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    left: 12, bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkGreen.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${product.quantity} ${product.unit}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(product.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                      Container(width: 1, height: 14, color: Colors.grey[300]),
                      const SizedBox(width: 8),
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(product.farmerName ?? 'Unknown',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('$timeAgo ago',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      const Spacer(),
                      if (product.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(product.categoryName!,
                            style: TextStyle(color: AppTheme.darkGreen, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
