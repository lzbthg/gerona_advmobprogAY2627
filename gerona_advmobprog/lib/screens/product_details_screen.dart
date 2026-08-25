import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product_model.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final discountPrice =
        product.price * (1 - product.discountPercentage / 100);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Product Details',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhancement 2: Added a product details page that opens when the user clicks/taps a product card.
            Container(
              width: double.infinity,
              height: 300.h,
              color: Theme.of(context).cardColor,
              child: product.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Image.network(
                            product.images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 70.sp,
                                  color: Theme.of(context).disabledColor,
                                ),
                              );
                            },
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return Center(
                                child: SizedBox(
                                  width: 28.w,
                                  height: 28.h,
                                  child: const CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    )
                  : Image.network(
                      product.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 70.sp,
                            color: Theme.of(context).disabledColor,
                          ),
                        );
                      },
                    ),
            ),

            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BRAND
                  if (product.brand.isNotEmpty)
                    CustomText(
                      text: product.brand.toUpperCase(),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),

                  SizedBox(height: 6.h),

                  // TITLE
                  CustomText(
                    text: product.title,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),

                  SizedBox(height: 8.h),

                  // CATEGORY + AVAILABILITY
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 17.sp,
                              color: Theme.of(context).hintColor,
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: CustomText(
                                text: product.category,
                                fontSize: 13.sp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _availabilityBadge(context),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // PRICE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        text: '\$${discountPrice.toStringAsFixed(2)}',
                        fontSize: 27.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(width: 9.w),
                      if (product.discountPercentage > 0)
                        CustomText(
                          text: '\$${product.price.toStringAsFixed(2)}',
                          fontSize: 14.sp,
                        ),
                    ],
                  ),

                  if (product.discountPercentage > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: Row(
                        children: [
                          CustomText(
                            text:
                                'Save \$${(product.price - discountPrice).toStringAsFixed(2)}',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: CustomText(
                              text:
                                  '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 16.h),

                  // RATING + REVIEWS + STOCK
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 21.sp,
                        ),
                        SizedBox(width: 5.w),
                        CustomText(
                          text: product.rating.toStringAsFixed(1),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(width: 6.w),
                        CustomText(
                          text: '${product.reviews.length} reviews',
                          fontSize: 12.sp,
                        ),
                        const Spacer(),
                        Icon(
                          product.stock > 0
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          size: 18.sp,
                          color: product.stock > 0
                              ? Colors.green
                              : colorScheme.error,
                        ),
                        SizedBox(width: 5.w),
                        CustomText(
                          text: '${product.stock} in stock',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // TAGS
                  if (product.tags.isNotEmpty) ...[
                    _sectionTitle(
                      context,
                      'Tags',
                      Icons.local_offer_outlined,
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 7.w,
                      runSpacing: 7.h,
                      children: product.tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 11.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: CustomText(
                            text: tag,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 22.h),
                  ],

                  // DESCRIPTION
                  _sectionTitle(
                    context,
                    'Description',
                    Icons.description_outlined,
                  ),

                  SizedBox(height: 9.h),

                  CustomText(
                    text: product.description,
                    fontSize: 14.sp,
                    letterSpacing: 0.1,
                  ),

                  SizedBox(height: 24.h),

                  // PRODUCT INFORMATION
                  _sectionTitle(
                    context,
                    'Product Information',
                    Icons.inventory_2_outlined,
                  ),

                  SizedBox(height: 10.h),

                  _infoCard(
                    context,
                    [
                      _infoRow(
                        context,
                        'Product ID',
                        '${product.id}',
                      ),
                      _infoRow(
                        context,
                        'Category',
                        product.category,
                      ),
                      _infoRow(
                        context,
                        'Brand',
                        product.brand,
                      ),
                      _infoRow(
                        context,
                        'SKU',
                        product.sku,
                      ),
                      _infoRow(
                        context,
                        'Stock',
                        '${product.stock}',
                      ),
                      _infoRow(
                        context,
                        'Availability',
                        product.availabilityStatus,
                      ),
                      _infoRow(
                        context,
                        'Minimum Order',
                        '${product.minimumOrderQuantity}',
                      ),
                      _infoRow(
                        context,
                        'Weight',
                        '${product.weight}',
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // DIMENSIONS
                  _sectionTitle(
                    context,
                    'Dimensions',
                    Icons.straighten_outlined,
                  ),

                  SizedBox(height: 10.h),

                  Row(
                    children: [
                      Expanded(
                        child: _dimensionCard(
                          context,
                          'Width',
                          product.dimensions.width,
                          Icons.swap_horiz,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _dimensionCard(
                          context,
                          'Height',
                          product.dimensions.height,
                          Icons.height,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _dimensionCard(
                          context,
                          'Depth',
                          product.dimensions.depth,
                          Icons.view_in_ar_outlined,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // SHIPPING & WARRANTY
                  _sectionTitle(
                    context,
                    'Shipping & Warranty',
                    Icons.local_shipping_outlined,
                  ),

                  SizedBox(height: 10.h),

                  _infoCard(
                    context,
                    [
                      _infoRow(
                        context,
                        'Warranty',
                        product.warrantyInformation,
                      ),
                      _infoRow(
                        context,
                        'Shipping',
                        product.shippingInformation,
                      ),
                      _infoRow(
                        context,
                        'Return Policy',
                        product.returnPolicy,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // REVIEWS
                  _sectionTitle(
                    context,
                    'Reviews',
                    Icons.rate_review_outlined,
                  ),

                  SizedBox(height: 10.h),

                  if (product.reviews.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: CustomText(
                        text: 'No reviews available.',
                        fontSize: 13.sp,
                      ),
                    )
                  else
                    ...product.reviews.map(
                      (review) => _reviewCard(
                        context,
                        review,
                      ),
                    ),

                  SizedBox(height: 24.h),

                  // METADATA
                  _sectionTitle(
                    context,
                    'Product Metadata',
                    Icons.info_outline,
                  ),

                  SizedBox(height: 10.h),

                  _infoCard(
                    context,
                    [
                      _infoRow(
                        context,
                        'Barcode',
                        product.meta.barcode,
                      ),
                      _infoRow(
                        context,
                        'Created',
                        product.meta.createdAt,
                      ),
                      _infoRow(
                        context,
                        'Updated',
                        product.meta.updatedAt,
                      ),
                      _infoRow(
                        context,
                        'QR Code',
                        product.meta.qrCode,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final inStock = product.stock > 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 9.w,
        vertical: 5.h,
      ),
      decoration: BoxDecoration(
        color: inStock
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: CustomText(
        text: product.availabilityStatus,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: colorScheme.primary,
          ),
        ),
        SizedBox(width: 9.w),
        CustomText(
          text: title,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: CustomText(
              text: label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: CustomText(
              text: value.isEmpty ? 'Not available' : value,
              fontSize: 12.sp,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dimensionCard(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 14.h,
        horizontal: 5.w,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21.sp,
            color: colorScheme.primary,
          ),
          SizedBox(height: 7.h),
          CustomText(
            text: label,
            fontSize: 11.sp,
          ),
          SizedBox(height: 3.h),
          CustomText(
            text: value.toString(),
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(
    BuildContext context,
    ProductReview review,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                child: CustomText(
                  text: review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: review.reviewerName,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text: review.date,
                      fontSize: 10.sp,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) {
                    return Icon(
                      index < review.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16.sp,
                    );
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          CustomText(
            text: review.comment,
            fontSize: 12.sp,
          ),
        ],
      ),
    );
  }
}