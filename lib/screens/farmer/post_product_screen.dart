import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

class PostProductScreen extends ConsumerStatefulWidget {
  final Product? existingProduct;
  const PostProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends ConsumerState<PostProductScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;
  late final TextEditingController _locationController;
  late String _unit;
  late int _categoryId;
  late List<String> _paymentMethods;
  final List<Map<String, dynamic>> _selectedImages = [];
  final List<String> _existingImages = [];
  bool _loading = false;

  final _categories = [
    {'id': 1, 'name': 'ጤፍ', 'icon': Icons.grass},
    {'id': 2, 'name': 'በቆሎ', 'icon': Icons.grass},
    {'id': 3, 'name': 'ስንዴ', 'icon': Icons.grass},
    {'id': 4, 'name': 'ቡና', 'icon': Icons.coffee},
    {'id': 5, 'name': 'አተር', 'icon': Icons.eco},
    {'id': 6, 'name': 'ሌላ', 'icon': Icons.more_horiz},
  ];

  final _allPaymentMethods = ['Cash', 'Bank Transfer', 'Telebirr', 'Chapa', 'CBE Birr'];

  bool get isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    _qtyController = TextEditingController(text: p != null ? p.quantity.toString() : '');
    _locationController = TextEditingController(text: p?.location ?? '');
    _unit = (p?.unit == 'ኪንታል' ? 'ኩንታል' : p?.unit) ?? 'ኩንታል';
    _categoryId = p?.categoryId ?? 1;
    _paymentMethods = p?.paymentMethods ?? <String>[];
    if (p?.images != null) _existingImages.addAll(p!.images);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final xfiles = await picker.pickMultiImage();
    if (xfiles.isEmpty) return;
    for (final xf in xfiles) {
      final bytes = await xf.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImages.add({
          'name': xf.name,
          'filename': xf.name,
          'bytes': bytes,
        });
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final qty = double.tryParse(_qtyController.text.trim());
    final loc = _locationController.text.trim();

    if (title.isEmpty || price == null || qty == null || loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final data = {
        'title': title,
        'categoryId': _categoryId,
        'description': _descController.text.trim(),
        'quantity': qty,
        'unit': _unit,
        'price': price,
        'location': loc,
        'paymentMethods': _paymentMethods,
      };

      final imageFiles = _selectedImages.map((f) {
        return {
          'name': 'images',
          'filename': f['filename'] as String,
          'bytes': f['bytes'] as List<int>,
        };
      }).toList();

      if (isEditing) {
        if (_existingImages.length < (widget.existingProduct!.images.length)) {
          data['existingImages'] = _existingImages.toList();
        }
        await ref.read(productServiceProvider).updateProduct(widget.existingProduct!.id, data, images: imageFiles.isNotEmpty ? imageFiles : null);
      } else {
        await ref.read(productServiceProvider).createProduct(data, images: imageFiles.isNotEmpty ? imageFiles : null);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Product Updated!' : 'Product Posted!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Product' : AppStrings.postProduct),
        actions: [
          TextButton(onPressed: _loading ? null : _submit, child: Text(isEditing ? 'Save' : AppStrings.postProduct,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _sectionHeader('Category', Icons.category),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = _categoryId == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() => _categoryId = cat['id'] as int),
                  child: Container(
                    width: 76, padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey[300]!, width: selected ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(cat['icon'] as IconData, color: selected ? AppTheme.primaryGreen : Colors.grey, size: 24),
                      const SizedBox(height: 4),
                      Text(cat['name'] as String, style: TextStyle(fontSize: 11, color: selected ? AppTheme.primaryGreen : Colors.grey[700])),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Product Details', Icons.description),
          const SizedBox(height: 8),
          Card(
            elevation: 0, color: Colors.grey[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Product Title *', prefixIcon: Icon(Icons.label, color: AppTheme.primaryGreen), filled: true, fillColor: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description, color: AppTheme.primaryGreen), alignLabelWithHint: true, filled: true, fillColor: Colors.white),
              ),
            ])),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Pricing & Quantity', Icons.monetization_on),
          const SizedBox(height: 8),
          Card(
            elevation: 0, color: Colors.grey[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Row(children: [
                Expanded(flex: 2, child: TextField(
                  controller: _priceController, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price per unit (ብር) *', prefixIcon: Icon(Icons.monetization_on, color: AppTheme.primaryGreen), filled: true, fillColor: Colors.white),
                )),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(labelText: 'Unit', filled: true, fillColor: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'ኩንታል', child: Text('ኩንታል')),
                    DropdownMenuItem(value: 'ኪሎ', child: Text('ኪሎ')),
                    DropdownMenuItem(value: 'ቶን', child: Text('ቶን')),
                  ],
                  onChanged: (v) => setState(() => _unit = v!),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: _qtyController, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity *', prefixIcon: Icon(Icons.numbers, color: AppTheme.primaryGreen), filled: true, fillColor: Colors.white),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location *', prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryGreen), filled: true, fillColor: Colors.white),
                )),
              ]),
            ])),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Payment Methods', Icons.payment),
          const SizedBox(height: 8),
          Card(
            elevation: 0, color: Colors.grey[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(padding: const EdgeInsets.all(16), child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _allPaymentMethods.map((m) => FilterChip(
                label: Text(m, style: TextStyle(fontSize: 13, color: _paymentMethods.contains(m) ? Colors.white : Colors.black87)),
                selected: _paymentMethods.contains(m),
                selectedColor: AppTheme.primaryGreen,
                checkmarkColor: Colors.white,
                onSelected: (v) => setState(() {
                  if (v) { _paymentMethods.add(m); } else { _paymentMethods.remove(m); }
                }),
              )).toList(),
            )),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Photos', Icons.image),
          const SizedBox(height: 8),
          Card(
            elevation: 0, color: Colors.grey[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImages.length + _selectedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (i < _existingImages.length) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_existingImages[i], filterQuality: FilterQuality.high,
                                height: 100, width: 100, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(height: 100, width: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image))),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _existingImages.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      final f = _selectedImages[i - _existingImages.length];
                      final bytes = f['bytes'] as List<int>?;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: bytes != null
                                ? Image.memory(Uint8List.fromList(bytes), height: 100, width: 100, fit: BoxFit.cover, filterQuality: FilterQuality.high)
                                : Container(height: 100, width: 100, color: Colors.grey[200], child: const Icon(Icons.image)),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(i - _existingImages.length)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_selectedImages.isEmpty && _existingImages.isEmpty ? 'Add Photos' : 'Add More'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              if (_selectedImages.isNotEmpty || _existingImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${_existingImages.length + _selectedImages.length} photo(s)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ),
            ])),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppTheme.primaryGreen),
              child: _loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Save Changes' : AppStrings.postProduct, style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: AppTheme.primaryGreen),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.darkGreen)),
    ]);
  }
}
