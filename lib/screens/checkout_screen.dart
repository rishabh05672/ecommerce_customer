import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/order_model.dart';
import '../provider/auth_provider.dart';
import '../provider/cart_provider.dart';
import '../provider/order_provider.dart';


class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(child: Text('Cart is empty'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary
                      Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...cart.items.map((item) => ListTile(
                        title: Text(item.productName),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text('₹${item.totalPrice}'),
                      )).toList(),
                      Divider(),
                      ListTile(
                        title: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text('₹${cart.totalAmount}', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20),

                      // Delivery Details
                      Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              // Place Order Button
              Container(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _placeOrder,
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text('Place Order', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
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

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Create order items
    final orderItems = cart.items.map((item) => OrderItem(
      id: '',
      orderId: '',
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
    )).toList();

    // Create order
    final order = Order(
      id: '',
      customerEmail: auth.userEmail!,
      totalAmount: cart.totalAmount,
      taxAmount: 0,
      shippingAmount: 0,
      discountAmount: 0,
      status: 'pending',
      paymentStatus: 'pending',
      shippingAddress: {
        'address': _addressController.text,
        'phone': _phoneController.text,
      },
      items: orderItems,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await orderProvider.createOrder(order);

    setState(() => _isLoading = false);

    if (success) {
      cart.clearCart();
      Navigator.pushReplacementNamed(context, '/orders');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order')),
      );
    }
  }
}
