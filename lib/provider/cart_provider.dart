import 'dart:convert';

import 'package:ecommerce_customer/model/cart_model.dart';
import 'package:ecommerce_customer/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  CartProvider() {
    _loadCart();
  }

  // Add product to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      final existingIndex = _items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        // Product already exists, update quantity
        _items[existingIndex] = CartItem(
          id: _items[existingIndex].id,
          productId: _items[existingIndex].productId,
          productName: _items[existingIndex].productName,
          unitPrice: _items[existingIndex].unitPrice,
          quantity: _items[existingIndex].quantity + quantity,
          imageUrl: _items[existingIndex].imageUrl,
        );
      } else {
        // Add new product
        _items.add(
          CartItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: product.id,
            productName: product.name,
            unitPrice: product.discountPrice ?? product.price,
            quantity: quantity,
            imageUrl: product.images.isNotEmpty ? product.images.first : null,
          ),
        );
      }

      await _saveCart();
      notifyListeners();
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  // Remove product from cart
  Future<void> removeFromCart(String productId) async {
    try {
      _items.removeWhere((item) => item.productId == productId);
      await _saveCart();
      notifyListeners();
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  // Update quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      final index = _items.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        if (quantity <= 0) {
          _items.removeAt(index);
        } else {
          _items[index] = CartItem(
            id: _items[index].id,
            productId: _items[index].productId,
            productName: _items[index].productName,
            unitPrice: _items[index].unitPrice,
            quantity: quantity,
            imageUrl: _items[index].imageUrl,
          );
        }
        await _saveCart();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  // Clear entire cart
  Future<void> clearCart() async {
    try {
      _items.clear();
      await _saveCart();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  // Get item quantity for specific product
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        id: '',
        productId: '',
        productName: '',
        unitPrice: 0,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // Get cart item by product ID
  CartItem? getCartItem(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = _items.map((item) => item.toJson()).toList();
      await prefs.setString('shopping_cart', json.encode(cartJson));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Load cart from local storage
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('shopping_cart');

      if (cartString != null && cartString.isNotEmpty) {
        final cartJson = json.decode(cartString) as List;
        _items = cartJson.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
      _items = []; // Reset to empty cart if error
    }
  }

  // Calculate total for specific items
  double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Get cart summary
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'totalAmount': totalAmount,
      'items': _items.map((item) => item.toJson()).toList(),
    };
  }
}
