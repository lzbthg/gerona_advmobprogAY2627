import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  int _userId;

  // Enhancement (per-account local cart):
  // DummyJSON sessions use the real remote cart (getCartByUserId/addToCart).
  // Firebase sessions have no real DummyJSON identity, so instead of
  // borrowing DummyJSON's demo user #1 cart (which every Firebase account
  // would then share), each Firebase account gets its own cart persisted
  // on-device under a key derived from its Firebase uid.
  bool _isLocalCart = false;
  String? _localCartKey;

  Cart? _cart;
  Future<void>? _loadFuture;

  // ignore: prefer_initializing_formals
  CartProvider({int userId = 1}) : _userId = userId;

  int get userId => _userId;
  Cart? get cart => _cart;
  bool get isLocalCart => _isLocalCart;

  // LAB_ACT4 ENHANCEMENT 3 / Enhancement (per-account local cart):
  // Points this provider at whoever is currently signed in, and decides
  // whether their cart should come from DummyJSON or from the local,
  // per-account store. Reloads the cart whenever the session actually
  // changes (a different user, or switching between DummyJSON/Firebase).
  void configureForUser(User user) {
    final isLocal = user.loginType == LoginType.firebase;
    final localKey = isLocal ? user.localCartKey : null;
    final userId = user.cartUserId;

    final unchanged = _isLocalCart == isLocal &&
        (isLocal ? _localCartKey == localKey : _userId == userId);
    if (unchanged) {
      return;
    }

    _isLocalCart = isLocal;
    _localCartKey = localKey;
    _userId = userId;
    _cart = null;
    _loadFuture = null;
    notifyListeners();
  }

  // Kept for compatibility with any older call sites; prefer
  // configureForUser(user) so local-cart accounts are handled correctly.
  void setUserId(int newUserId) {
    if (!_isLocalCart && _userId == newUserId) {
      return;
    }
    _isLocalCart = false;
    _localCartKey = null;
    _userId = newUserId;
    _cart = null;
    _loadFuture = null;
    notifyListeners();
  }

  Future<void> loadCart() {
    return _loadFuture ??= _loadCart();
  }

  Future<void> _loadCart() async {
    _cart = _isLocalCart
        ? await _loadLocalCart()
        : await _cartService.getCartByUserId(userId);
    notifyListeners();
  }

  Future<Cart> _loadLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localCartKey!);

    if (raw != null) {
      try {
        return Cart.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Fall through to an empty cart if the saved data is unreadable.
      }
    }

    return _emptyCart();
  }

  Cart _emptyCart() {
    return Cart(
      id: 0,
      products: const [],
      total: 0,
      discountedTotal: 0,
      userId: _userId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }

  Future<void> _persistLocalCart() async {
    if (_localCartKey == null || _cart == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localCartKey!, jsonEncode(_cart!.toJson()));
  }

  Future<void> addProduct(Product product) async {
    // DummyJSON accounts still round-trip through the real /carts/add
    // endpoint; local-cart accounts skip the network call entirely, since
    // there is no DummyJSON account behind them to add anything to.
    int? remoteCartId;
    if (!_isLocalCart) {
      final addedCart = await _cartService.addToCart(
        userId: userId,
        products: [
          {'id': product.id, 'quantity': 1},
        ],
      );
      remoteCartId = addedCart.id;
    }

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
      id: _cart?.id ?? remoteCartId ?? 0,
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

    if (_isLocalCart) {
      await _persistLocalCart();
    }

    notifyListeners();
  }

  Future<void> updateQuantity(CartProduct item, int change) async {
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

    if (_isLocalCart) {
      await _persistLocalCart();
    }
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