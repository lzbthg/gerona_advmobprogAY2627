import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  // Gets all products from the DummyJSON API.
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('$host/products?limit=0'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];

      return productsJson
          .map((json) => Product.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // LAB_ACT3 ENHANCEMENT 1:
  // Gets one product by its ID. This is used by CartScreen so that a cart item can open the same ProductDetailsScreen used by the product screen.
  Future<Product> getProductById(int id) async {
    final response = await http.get(
      Uri.parse('$host/products/$id'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      return Product.fromJson(data);
    } else {
      throw Exception(
        'Failed to load product with ID $id',
      );
    }
  }
}