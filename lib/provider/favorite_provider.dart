import 'package:ecommerce_customer/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoriteProvider with ChangeNotifier {
  List<Product> _favorites = [];

  List<Product> get favorites => _favorites;
  int get count => _favorites.length;

  FavoriteProvider() {
    _loadFavorites();
  }

  bool isFavorite(String productId) {
    return _favorites.any((product) => product.id == productId);
  }

  Future<void> addToFavorites(Product product) async {
    if (!isFavorite(product.id)) {
      _favorites.add(product);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    _favorites.removeWhere((product) => product.id == productId);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = _favorites
        .map((product) => product.toJson())
        .toList();
    await prefs.setString('favorites', json.encode(favoritesJson));
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesString = prefs.getString('favorites');

      if (favoritesString != null) {
        final favoritesJson = json.decode(favoritesString) as List;
        _favorites = favoritesJson
            .map((product) => Product.fromJson(product))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _favorites = [];
    }
  }
}
