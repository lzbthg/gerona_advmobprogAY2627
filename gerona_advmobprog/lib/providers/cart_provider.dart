import 'package:flutter/foundation.dart';

import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  final int userId;

  Cart? _cart;
  Future<void>? _loadFuture;

  CartProvider({this.userId = 1});

  Cart? get cart => _cart;

  Future<void> loadCart() {
    return _loadFuture ??= _loadCart();
  }

  Future<void> _loadCart() async {
    _cart = await _cartService.getCartByUserId(userId);
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final addedCart = await _cartService.addToCart(
      userId: userId,
      products: [
        {'id': product.id, 'quantity': 1},
      ],
    );

    final currentProducts = List<CartProduct>.from(_cart?.products ?? []);
    final existingIndex = currentProducts.indexWhere(
      (item) => item.id == product.id,
    );
    final cartProduct = CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: 1,
      total: product.price,
      discountPercentage: product.discountPercentage,
      discountedTotal: product.price * (1 - product.discountPercentage / 100),
      thumbnail: product.thumbnail,
    );

    if (existingIndex >= 0) {
      final existing = currentProducts[existingIndex];
      currentProducts[existingIndex] = _withQuantity(
        cartProduct,
        existing.quantity + 1,
      );
    } else {
      currentProducts.add(cartProduct);
    }

    _cart = Cart(
      id: _cart?.id ?? addedCart.id,
      products: currentProducts,
      total: _total(currentProducts, discounted: false),
      discountedTotal: _total(currentProducts, discounted: true),
      userId: userId,
      totalProducts: currentProducts.length,
      totalQuantity: currentProducts.fold(
        0,
        (sum, item) => sum + item.quantity,
      ),
    );
    notifyListeners();
  }

  void updateQuantity(CartProduct item, int change) {
    if (_cart == null) {
      return;
    }

    final products = List<CartProduct>.from(_cart!.products);
    final index = products.indexOf(item);
    if (index < 0) {
      return;
    }

    final quantity = item.quantity + change;
    if (quantity <= 0) {
      products.removeAt(index);
    } else {
      products[index] = _withQuantity(item, quantity);
    }

    _cart = Cart(
      id: _cart!.id,
      products: products,
      total: _total(products, discounted: false),
      discountedTotal: _total(products, discounted: true),
      userId: _cart!.userId,
      totalProducts: products.length,
      totalQuantity: products.fold(0, (sum, product) => sum + product.quantity),
    );
    notifyListeners();
  }

  CartProduct _withQuantity(CartProduct item, int quantity) {
    final discountedPrice = item.price * (1 - item.discountPercentage / 100);
    return CartProduct(
      id: item.id,
      title: item.title,
      price: item.price,
      quantity: quantity,
      total: item.price * quantity,
      discountPercentage: item.discountPercentage,
      discountedTotal: discountedPrice * quantity,
      thumbnail: item.thumbnail,
    );
  }

  double _total(List<CartProduct> products, {required bool discounted}) {
    return products.fold(
      0,
      (sum, item) => sum + (discounted ? item.discountedTotal : item.total),
    );
  }
}
