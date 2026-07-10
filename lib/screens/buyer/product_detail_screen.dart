import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _contacting = false;
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isFavorite = false;

  Future<void> _contactFarmer(Product product) async {
    if (_contacting) return;
    setState(() => _contacting = true);
    try {
      final chatService = ref.read(chatServiceProvider);
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        if (context.mounted) Navigator.pushNamed(context, '/login');
        return;
      }
      if (user.id == product.farmerId) return;

      var conv = await chatService.getExistingConversation(
        product.id, user.id, product.farmerId);
      if (conv == null) {
        final farmerName = product.farmerName ?? 'Farmer';
        conv = await chatService.createConversation(
          product.id, product.title,
          user.id, user.username,
          product.farmerId, farmerName);
      }
      await chatService.sendMessage(
        conversationId: conv.id,
        senderId: user.id,
        content: '${AppStrings.contactMessage}: ${product.title}',
      );
      if (context.mounted) {
        Navigator.pushNamed(context, '/chat', arguments: conv);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Product) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false));
      return const SizedBox();
    }
    final product = args;
    final userAsync = ref.watch(currentUserProvider);
    final isFarmerViewing = userAsync.valueOrNull?.isFarmer == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_outline,
                color: _isFavorite ? Colors.red : Colors.white),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(product),
                  _buildPriceSection(product),
                  _buildSellerCard(product),
                  _buildSpecsSection(product),
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    _buildSectionHeader(AppStrings.isAmharic ? 'መግለጫ' : 'Description'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(product.description!,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6)),
                    ),
                  ],
                  if (isFarmerViewing) _buildFarmerNote(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (!isFarmerViewing) _buildBottomBar(product),
        ],
      ),
    );
  }

  Widget _buildImageGallery(Product product) {
    if (product.images.isEmpty) {
      return Container(height: 260, color: AppTheme.cream, child: const Center(child: Icon(Icons.agriculture, size: 64, color: AppTheme.primaryGreen)));
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: product.images.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => Image.network(product.images[i],
                  fit: BoxFit.cover, filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 64, color: Colors.grey))),
              ),
              if (product.images.length > 1) ...[
                if (_currentPage > 0)
                  Positioned(
                    left: 8, top: 0, bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage < product.images.length - 1)
                  Positioned(
                    right: 8, top: 0, bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (product.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(product.images.length, (i) =>
              GestureDetector(
                onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppTheme.primaryGreen : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: product.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = i == _currentPage;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(product.images[i], fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPriceSection(Product product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${product.priceFormatted} ብር',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                const SizedBox(width: 6),
                Text('/ ${product.unit}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500])),
              ]),
              const SizedBox(height: 2),
              Text('${product.quantity} ${product.unit} ${AppStrings.isAmharic ? "ይገኛል" : "available"}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: product.status == 'active' ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: product.status == 'active' ? Colors.green : Colors.orange, width: 0.5),
            ),
            child: Text(
              product.status == 'active'
                  ? (AppStrings.isAmharic ? 'ንቁ' : 'Active')
                  : (AppStrings.isAmharic ? 'ተሽጧል' : 'Sold'),
              style: TextStyle(fontSize: 12, color: product.status == 'active' ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
              child: Text(product.farmerName?.isNotEmpty == true ? product.farmerName![0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.farmerName ?? 'Unknown',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(product.location, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSpecsSection(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(AppStrings.isAmharic ? 'ዝርዝሮች' : 'Details'),
          Card(
            elevation: 0,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _specRow(AppStrings.isAmharic ? 'ምድብ' : 'Category', product.categoryName ?? '-'),
                  const Divider(height: 16),
                  _specRow(AppStrings.isAmharic ? 'ብዛት' : 'Quantity', '${product.quantity} ${product.unit}'),
                  const Divider(height: 16),
                  _specRow(AppStrings.isAmharic ? 'አካባቢ' : 'Location', product.location),
                  if (product.paymentMethods.isNotEmpty) ...[
                    const Divider(height: 16),
                    _specRow(AppStrings.isAmharic ? 'የክፍያ ዘዴ' : 'Payment', product.paymentMethods.join(', ')),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFarmerNote() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          const Icon(Icons.info_outline, color: AppTheme.darkGreen, size: 28),
          const SizedBox(height: 8),
          Text(
            AppStrings.isAmharic
                ? 'ለመግዛት ከፈለጉ እባክዎ በገዢ መለያ ይግቡ'
                : 'To purchase, please sign in as a buyer',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppTheme.darkGreen, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _contactFarmer(product),
                icon: _contacting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.chat),
                label: Text(_contacting ? AppStrings.pleaseWait : AppStrings.contactFarmer,
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryGreen,
                  disabledBackgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
