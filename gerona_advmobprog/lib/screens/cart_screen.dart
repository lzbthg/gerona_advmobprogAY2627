import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, this.userId = 1});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    // LAB_ACT3 ENHANCEMENT 3:
    // Created a CartScreen to render the cart data from the DummyJSON API.
    // Cart products are clickable and navigate to ProductDetailsScreen.
    final cartProvider = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<void>(
        future: cartProvider.loadCart(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _message('Unable to load your cart.');
          }

          final cart = cartProvider.cart;

          if (cart == null || cart.products.isEmpty) {
            return _message('Your cart is empty.');
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              ...cart.products.map(_cartItem),

              SizedBox(height: 4.h),

              _orderSummary(cart),

              SizedBox(height: 20.h),

              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => _confirmOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Confirm Order',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cartItem(CartProduct item) {
    final theme = Theme.of(context);
    final discountedPrice = _discountedUnitPrice(item);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        // LAB_ACT3 ENHANCEMENT 1:
        // Allows the user to click a cart product and navigate to its detail screen.
        onTap: () async {
          final product = await CartService().getProductById(item.id);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(
                  product: product,
                  showAddToCart: false,
                ),
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: 96.w,
              height: 96.h,
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Image.network(
                item.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 28.sp,
                  color: theme.disabledColor,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: item.title,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 6.h),

                  Row(
                    children: [
                      CustomText(
                        text: '₱${discountedPrice.toStringAsFixed(2)}',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),

                      if (item.discountPercentage > 0) ...[
                        SizedBox(width: 6.w),
                        Text(
                          '₱${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.disabledColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (item.discountPercentage > 0) ...[
                    SizedBox(height: 5.h),
                    Text(
                      '${item.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],

                  SizedBox(height: 10.h),

                  // Quantity and item total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _quantityControl(item),

                      SizedBox(width: 8.w),

                      Flexible(
                        child: Text(
                          '₱${(discountedPrice * item.quantity).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
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

  Widget _quantityControl(CartProduct item) {
    final theme = Theme.of(context);

    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove,
            onPressed: () {
              context.read<CartProvider>().updateQuantity(item, -1);
            },
          ),

          SizedBox(width: 8.w),

          SizedBox(
            width: 22.w,
            child: Center(
              child: CustomText(
                text: '${item.quantity}',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          _quantityButton(
            icon: Icons.add,
            onPressed: () {
              context.read<CartProvider>().updateQuantity(item, 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 26.w,
          height: 26.h,
          child: Icon(icon, size: 15.sp, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _orderSummary(Cart cart) {
    final theme = Theme.of(context);

    final subtotal = cart.products.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    final discount = cart.products.fold<double>(
      0,
      (sum, item) =>
          sum + (item.price * item.quantity * item.discountPercentage / 100),
    );

    final total = subtotal - discount;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          // Summary title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Subtotal
          _summaryRow('Subtotal', subtotal),

          SizedBox(height: 10.h),

          // Discount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 16.sp,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Discount',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '-₱${discount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Total
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  double _discountedUnitPrice(CartProduct item) {
    if (item.quantity == 0) {
      return 0;
    }

    return item.discountedTotal / item.quantity;
  }

  Future<void> _confirmOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Are you sure you want to place this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order confirmed')));
    }
  }

  Widget _message(String text) {
    return Center(
      child: CustomText(text: text, fontSize: 16.sp),
    );
  }
}
