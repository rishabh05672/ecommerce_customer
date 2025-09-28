import 'package:ecommerce_customer/model/category_model.dart';
import 'package:ecommerce_customer/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Product> _products = []; // Ab error nahi aayega
  List<Category> _categories = []; // Ab error nahi aayega
  List<Product> _filteredProducts = []; // Ab error nahi aayega

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategoryId = '';

  // Getters
  List<Product> get products =>
      _filteredProducts.isNotEmpty ? _filteredProducts : _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    fetchProducts();
    fetchCategories();
  }

  Future<void> fetchProducts() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _products = (response as List)
          .map((product) => Product.fromJson(product))
          .toList();

      _applyFilters();
    } catch (e) {
      _setError('Failed to load products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      _categories = (response as List)
          .map((category) => Category.fromJson(category))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void filterByCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_products);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(_searchQuery) ||
                product.description.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    if (_selectedCategoryId.isNotEmpty) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    _filteredProducts = filtered;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = '';
    _filteredProducts.clear();
    notifyListeners();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
