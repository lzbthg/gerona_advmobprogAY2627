import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartService {
  // Gets all carts from the DummyJSON API.
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(
      Uri.parse('$host/carts'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      return cartsJson
          .map((json) => Cart.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // LAB_ACT3 ENHANCEMENT 3:
  // Get the cart belonging to a specific user.
  // DummyJSON endpoint:
  // GET /carts/user/{userId}
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$host/carts/user/$userId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      if (cartsJson.isEmpty) {
        return null;
      }

      return Cart.fromJson(cartsJson.first);
    } else {
      throw Exception(
        'Failed to load cart for user $userId',
      );
    }
  }

  // LAB_ACT3 ENHANCEMENT 3:
  // Add products to a user's cart.
  // DummyJSON endpoint:
  // POST /carts/add
  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'products': products,
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Cart.fromJson(
        jsonDecode(response.body),
      );
    } else {
      throw Exception(
        'Failed to add product to cart',
      );
    }
  }

  // LAB_ACT3 ENHANCEMENT 1: CartProduct only contains limited product information.
  // The existing ProductDetailsScreen requires a complete Product object, so fetch the complete product using the product ID from the cart.
  // DummyJSON endpoint:
  // GET /products/{id} 
  Future<Product> getProductById(int productId) async {
    final response = await http.get(
      Uri.parse('$host/products/$productId'),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(
        jsonDecode(response.body),
      );
    } else {
      throw Exception(
        'Failed to load product $productId',
      );
    }
  }
}
