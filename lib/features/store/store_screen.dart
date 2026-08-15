import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/phone_verification_helper.dart';
import 'package:shelpet/features/store/my_orders_screen.dart';

class Product {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? image;
  final int stock;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.image,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      name: json['name'] ?? '',
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: json['category'] ?? 'accessory',
      image: json['image'],
      stock: int.parse((json['stock'] ?? 0).toString()),
    );
  }
}

final storeCategoryProvider = StateProvider<String>((ref) => 'All');
final storeSearchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final category = ref.watch(storeCategoryProvider);
  final list = await ApiService.getProducts(category);
  return list.map((e) => Product.fromJson(e)).toList();
});

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  void _showAddProduct(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateProductDialog(),
    );
  }

  void _showOrderConfirmation(BuildContext context, Product product, WidgetRef ref) {
    final addressController = TextEditingController(text: ref.read(userProvider)?.address ?? '');
    final phoneController = TextEditingController(text: ref.read(userProvider)?.phone ?? '');
    final user = ref.read(userProvider);
    bool isOrdering = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm Your Order', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Product: ${product.name}', style: const TextStyle(color: ShelPetTheme.textSecondary)),
              Text('Total Price: ৳${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: ShelPetTheme.primaryAccent)),
              const Divider(height: 32),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isOrdering ? null : () async {
                    if (!PhoneVerificationHelper.checkPhoneAndPrompt(context, ref)) return;
                    if (addressController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in both delivery address and phone number.'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    setModalState(() => isOrdering = true);
                    
                    final res = await ApiService.placeOrder(
                      buyerId: user!.id,
                      productId: product.id,
                      address: addressController.text.trim(),
                      phone: phoneController.text.trim(),
                    );

                    if (res['status'] == true) {
                      ref.invalidate(myOrdersProvider(user!.id));
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Order Placed! Admin will process soon. 🎉'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'TRACK STATUS',
                              textColor: Colors.white,
                              onPressed: () => context.push('/my-orders'),
                            ),
                          ),
                        );
                      }
                    } else {
                      setModalState(() => isOrdering = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${res['message']}')),
                        );
                      }
                    }
                  },
                  child: isOrdering 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  product.image!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product.name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold))),
                Text('৳ ${product.price.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: ShelPetTheme.primaryAccent)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: ShelPetTheme.primaryAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text(product.category.toUpperCase(), style: const TextStyle(color: ShelPetTheme.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Text('Available Stock: ${product.stock}', style: TextStyle(color: product.stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Text(product.description ?? '', style: const TextStyle(fontSize: 14, color: ShelPetTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: product.stock > 0 ? () {
                  Navigator.pop(context);
                  _showOrderConfirmation(context, product, ref);
                } : null,
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                label: Text(product.stock > 0 ? 'Buy Now' : 'Out of Stock', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final selectedCat = ref.watch(storeCategoryProvider);
    final searchQuery = ref.watch(storeSearchQueryProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text('Pet Store', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: ShelPetTheme.primaryAccent, size: 26),
            tooltip: 'My Store Orders',
            onPressed: () => context.push('/my-orders'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productsProvider.future),
        color: ShelPetTheme.primaryAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(ref),
              const SizedBox(height: 16),
              _buildActiveOrderStatusCard(context, ref, user),
              _buildCategories(ref, selectedCat),
              const SizedBox(height: 24),
              productsAsync.when(
                data: (products) {
                  final filteredProducts = searchQuery.trim().isEmpty
                      ? products
                      : products.where((p) =>
                          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          (p.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No items found in $selectedCat category',
                          style: const TextStyle(color: ShelPetTheme.textMuted),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) => _buildProductCard(context, filteredProducts[index], ref),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: user?.role == 'admin' 
        ? FloatingActionButton.extended(
            onPressed: () => _showAddProduct(context),
            backgroundColor: ShelPetTheme.primaryAccent,
            label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          )
        : null,
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: TextField(
        onChanged: (val) => ref.read(storeSearchQueryProvider.notifier).state = val,
        decoration: const InputDecoration(
          hintText: 'Search items...',
          hintStyle: TextStyle(color: ShelPetTheme.textMuted),
          icon: Icon(Icons.search, color: ShelPetTheme.primaryAccent),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActiveOrderStatusCard(BuildContext context, WidgetRef ref, UserProfile? user) {
    if (user == null) return const SizedBox.shrink();

    final ordersAsync = ref.watch(myOrdersProvider(user.id));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();

        final latestOrder = orders.first;
        final String status = latestOrder['status'] ?? 'pending';
        final String productName = latestOrder['product_name'] ?? 'Product Item';
        final double totalPrice = double.tryParse(latestOrder['total_price'].toString()) ?? 0.0;
        final int totalOrders = orders.length;

        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (status.toLowerCase()) {
          case 'accepted':
            statusColor = Colors.blue.shade700;
            statusText = 'ACCEPTED';
            statusIcon = Icons.inventory_2_outlined;
            break;
          case 'shipped':
            statusColor = Colors.purple.shade700;
            statusText = 'ON THE WAY';
            statusIcon = Icons.local_shipping_outlined;
            break;
          case 'delivered':
            statusColor = Colors.green.shade700;
            statusText = 'DELIVERED';
            statusIcon = Icons.check_circle_outline;
            break;
          case 'cancelled':
            statusColor = Colors.red.shade700;
            statusText = 'CANCELLED';
            statusIcon = Icons.cancel_outlined;
            break;
          case 'pending':
          default:
            statusColor = Colors.orange.shade800;
            statusText = 'PENDING APPROVAL';
            statusIcon = Icons.hourglass_empty_rounded;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusColor.withOpacity(0.08), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/my-orders'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_mall_outlined, size: 18, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              'My Orders ($totalOrders)',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: ShelPetTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ShelPetTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total: ৳${totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: ShelPetTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'View Status',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ShelPetTheme.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: ShelPetTheme.primaryAccent),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategories(WidgetRef ref, String selectedCat) {
    final cats = ['All', 'Food', 'Accessories', 'Medicine'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final cat = cats[index];
          final isSelected = selectedCat == cat;
          return GestureDetector(
            onTap: () => ref.read(storeCategoryProvider.notifier).state = cat,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? ShelPetTheme.primaryAccent : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.04)),
              ),
              child: Center(child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : ShelPetTheme.textSecondary, fontWeight: FontWeight.bold))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showProductDetails(context, product, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: product.image != null
                    ? Image.network(product.image!, width: double.infinity, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('৳${product.price.toStringAsFixed(0)}', style: const TextStyle(color: ShelPetTheme.primaryAccent, fontWeight: FontWeight.bold)),
                      if (product.stock <= 3 && product.stock > 0)
                        Text('Low Stock', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
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

class CreateProductDialog extends ConsumerStatefulWidget {
  const CreateProductDialog({super.key});

  @override
  ConsumerState<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends ConsumerState<CreateProductDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  String _selectedCategory = 'Food';
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final user = ref.read(userProvider);
    String? imageUrl;

    if (_image != null) {
      imageUrl = await ApiService.uploadImage(_image!.path);
    }

    final response = await ApiService.createProduct(
      userId: user?.id ?? 0,
      name: _nameController.text,
      description: _descController.text,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      image: imageUrl,
      stock: int.tryParse(_stockController.text) ?? 0,
    );

    setState(() => _isLoading = false);
    if (response['status'] == true) {
      ref.invalidate(productsProvider);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Product', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                child: _image != null ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_image!, fit: BoxFit.cover)) : const Icon(Icons.add_a_photo),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('🍲 Food')),
                DropdownMenuItem(value: 'Accessories', child: Text('🧸 Accessories')),
                DropdownMenuItem(value: 'Medicine', child: Text('💊 Medicine')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (৳)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShelPetTheme.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add to Store', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
