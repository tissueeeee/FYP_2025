import 'package:flutter/foundation.dart';
import 'package:fyp_project/models/cart_model.dart' as model;
import 'package:fyp_project/models/cart_model.dart';
import 'package:fyp_project/screens/cart_page.dart' as screen;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartProvider with ChangeNotifier {
  List<model.CartItem> _items = [];

  List<model.CartItem> get items => [..._items];

  int get itemCount => _items.length;

  void addSimpleItem(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeSimpleItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      double price = double.tryParse(item.price) ?? 0.0;
      total += price * item.quantity;
    }
    return total;
  }

  // Initialize cart from shared preferences
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cart_data');

    if (cartData != null) {
      try {
        final List<dynamic> decodedData = json.decode(cartData);
        _items =
            decodedData.map((item) => model.CartItem.fromMap(item)).toList();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error loading cart data: $e');
        }
      }
    }
  }

  // Save cart to shared preferences
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(_items.map((item) => item.toMap()).toList());
    await prefs.setString('cart_data', cartData);
  }

  void addItem(model.CartItem item) {
    final existingItemIndex =
        _items.indexWhere((i) => i.productId == item.productId);

    if (existingItemIndex >= 0) {
      // Update quantity if item already exists
      _items[existingItemIndex] = model.CartItem(
        productId: item.productId,
        productName: item.productName,
        storeName: item.storeName,
        price: item.price,
        imagePath: item.imagePath,
        quantity: _items[existingItemIndex].quantity + item.quantity,
      );
    } else {
      // Add new item
      _items.add(item);
    }

    saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    saveCart();
    notifyListeners();
  }

  void updateItemQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);

    if (index >= 0) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        _items[index] = model.CartItem(
          productId: _items[index].productId,
          productName: _items[index].productName,
          storeName: _items[index].storeName,
          price: _items[index].price,
          imagePath: _items[index].imagePath,
          quantity: quantity,
        );
        saveCart();
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items = [];
    saveCart();
    notifyListeners();
  }
}
