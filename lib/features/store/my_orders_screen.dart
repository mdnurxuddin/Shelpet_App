import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelpet/core/theme.dart';
import 'package:shelpet/core/user_provider.dart';
import 'package:shelpet/core/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

final myOrdersProvider = FutureProvider.family<List<dynamic>, int>((ref, userId) async {
  return await ApiService.getMyOrders(userId, role: 'buyer');
});

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue.shade700;
      case 'shipped':
        return Colors.purple.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'pending':
      default:
        return Colors.orange.shade800;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'ORDER ACCEPTED';
      case 'shipped':
        return 'SHIPPED / ON THE WAY';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
      default:
        return 'PENDING APPROVAL';
    }
  }

  Widget _buildStatusStepper(String status) {
    final lower = status.toLowerCase();
    if (lower == 'cancelled') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 16),
            const SizedBox(width: 8),
            Text(
              'This order has been cancelled',
              style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final steps = ['pending', 'accepted', 'shipped', 'delivered'];
    int currentIndex = steps.indexOf(lower);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ShelPetTheme.lightBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;

          String label;
          switch (index) {
            case 0: label = 'Placed'; break;
            case 1: label = 'Accepted'; break;
            case 2: label = 'Shipped'; break;
            case 3: label = 'Delivered'; break;
            default: label = '';
          }

          Color activeColor = isCompleted ? ShelPetTheme.primaryAccent : Colors.grey.shade300;
          if (isCurrent) activeColor = Colors.orange.shade800;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 11, color: Colors.white)
                            : Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCompleted ? ShelPetTheme.textPrimary : ShelPetTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      color: index < currentIndex ? ShelPetTheme.primaryAccent : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please log in to view your orders.')),
      );
    }

    final ordersAsync = ref.watch(myOrdersProvider(user.id));

    return Scaffold(
      backgroundColor: ShelPetTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'My Store Orders',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: ShelPetTheme.textPrimary),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOrdersProvider(user.id));
        },
        color: ShelPetTheme.primaryAccent,
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: ShelPetTheme.primaryAccent.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, size: 64, color: ShelPetTheme.primaryAccent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Orders Found',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: ShelPetTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You haven\'t ordered any items from the store yet.',
                          style: GoogleFonts.outfit(fontSize: 14, color: ShelPetTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final String status = order['status'] ?? 'pending';
                final Color statusColor = _getStatusColor(status);
                final String productName = order['product_name'] ?? 'Product Item';
                final String sellerName = order['seller_name'] ?? 'Pet Store';
                final String? productImage = order['product_image'];
                final int quantity = int.tryParse(order['quantity'].toString()) ?? 1;
                final double totalPrice = double.tryParse(order['total_price'].toString()) ?? 0.0;
                final String rawDate = order['created_at'] ?? '';
                
                String formattedDate = rawDate;
                try {
                  if (rawDate.isNotEmpty) {
                    final dateTime = DateTime.parse(rawDate);
                    formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
                  }
                } catch (_) {}

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(status), size: 14, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusTitle(status),
                                    style: GoogleFonts.outfit(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: GoogleFonts.outfit(color: ShelPetTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: productImage != null && productImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: productImage,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade100,
                                        child: const Icon(Icons.shopping_bag, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.shopping_bag, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: ShelPetTheme.textPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Seller: $sellerName',
                                    style: GoogleFonts.outfit(fontSize: 12, color: ShelPetTheme.textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Qty: $quantity',
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: ShelPetTheme.textSecondary),
                                      ),
                                      Text(
                                        '৳${totalPrice.toStringAsFixed(0)}',
                                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ShelPetTheme.primaryAccent),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildStatusStepper(status),
                        if (order['shipping_address'] != null && order['shipping_address'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ShelPetTheme.lightBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: ShelPetTheme.secondaryAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Delivery: ${order['shipping_address']}',
                                    style: GoogleFonts.outfit(fontSize: 11, color: ShelPetTheme.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading orders: $err')),
        ),
      ),
    );
  }
}
