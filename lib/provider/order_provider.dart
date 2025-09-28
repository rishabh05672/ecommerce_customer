import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/order_model.dart';

class OrderProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch customer's own orders
  Future<void> fetchMyOrders() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_email', user.email!)
          .order('created_at', ascending: false);

      _orders = (response as List)
          .map((order) => Order.fromJson(order))
          .toList();

    } catch (e) {
      _setError('Failed to fetch orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new order
  Future<bool> createOrder(Order order) async {
    try {
      _setLoading(true);
      _clearError();

      // Insert order
      final orderResponse = await _supabase.from('orders').insert({
        'customer_email': order.customerEmail,
        'total_amount': order.totalAmount,
        'tax_amount': order.taxAmount,
        'shipping_amount': order.shippingAmount,
        'discount_amount': order.discountAmount,
        'status': 'pending',
        'payment_status': 'pending',
        'shipping_address': order.shippingAddress,
        'billing_address': order.billingAddress,
        'notes': order.notes,
      }).select().single();

      // Insert order items
      for (OrderItem item in order.items) {
        await _supabase.from('order_items').insert({
          'order_id': orderResponse['id'],
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
          'product_sku': item.productSku,
        });
      }

      await fetchMyOrders(); // Refresh orders
      return true;

    } catch (e) {
      _setError('Failed to create order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get order by ID
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
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
