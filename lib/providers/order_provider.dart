import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_project/models/order_model.dart' as order_model;
import 'package:fyp_project/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderProvider with ChangeNotifier {
  List<order_model.Order> _orders = [];
  List<order_model.Order> _expiredOrders = [];
  List<order_model.Order> get orders => [..._orders];
  List<order_model.Order> get expiredOrders => _expiredOrders;
  List<order_model.Order> get activeOrders =>
      _orders.where((order) => !order.isCompleted).toList();
  List<order_model.Order> get completedOrders =>
      _orders.where((order) => order.isCompleted).toList();
  int get orderCount => _orders.length;

  // Save orders to shared preferences (optional, if still need offline support)
  Future<void> saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orderData =
        json.encode(_orders.map((order) => order.toMap()).toList());
    await prefs.setString('order_data', orderData);
  }

  // Add a new order
  Future<void> addOrder(order_model.Order order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Cannot add order: No user logged in');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('detailed_orders')
          .doc(user.uid)
          .collection('orders')
          .doc(order.id)
          .set(order.toMap());
      _orders.add(order);
      await saveOrders();
      notifyListeners();
    } catch (e) {
      print('Error adding order to Firestore: $e');
    }
  }

  // Mark an order as completed
  Future<void> markOrderAsCompleted(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Cannot mark order as completed: No user logged in');
      return;
    }

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      double co2Saved = order.calculateCO2Saved();
      // Use the existing moneySaved value if it's already calculated correctly
      double moneySaved = order.moneySaved != 0.0
          ? order.moneySaved
          : order.calculateMoneySaved();

      final updatedOrder = order.copyWith(
        isCompleted: true,
        co2Saved: co2Saved,
        moneySaved: moneySaved,
      );

      try {
        await FirebaseFirestore.instance
            .collection('detailed_orders')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({
          'isCompleted': true,
          'co2Saved': co2Saved,
          'moneySaved': moneySaved,
        });

        _orders[index] = updatedOrder;
        await saveOrders();
        notifyListeners();
      } catch (e) {
        print('Error marking order as completed in Firestore: $e');
      }
    }
  }

  // Mark an order as rated
  Future<void> markOrderAsRated(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Cannot mark order as rated: No user logged in');
      return;
    }

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      final updatedOrder = _orders[index].copyWith(isRated: true);

      try {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('detailed_orders')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({'isRated': true});

        // Update local list
        _orders[index] = updatedOrder;
        await saveOrders();
        notifyListeners();
      } catch (e) {
        print('Error marking order as rated in Firestore: $e');
      }
    }
  }

  Future<void> loadOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _orders = [];
      notifyListeners();
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('detailed_orders')
          .doc(user.uid)
          .collection('orders')
          .get();

      _orders = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Order ${doc.id}: isCompleted = ${data['isCompleted']}'); // Debug
        return order_model.Order(
          id: doc.id,
          productName: data['productName'] ?? '',
          storeName: data['storeName'] ?? '',
          price: (data['price'] ?? 0.0).toString(),
          originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
          quantity: data['quantity'] ?? 1,
          date: data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date']),
          pickUpTime: data['pickUpTime'] ?? '',
          imagePath: data['imagePath'] ?? '',
          transactionId: data['transactionId'] ?? '',
          totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
          isCompleted: data['isCompleted'] ?? false,
          co2Saved: (data['co2Saved'] ?? 0.0).toDouble(),
          moneySaved: (data['moneySaved'] ?? 0.0).toDouble(),
          paymentMethod: data['paymentMethod'] ?? '',
          isRated: data['isRated'] ?? false,
          businessId: data['businessId'] ?? '', // Added
          rating: data['rating']?.toDouble(), // Added
          userId: data['userId'] ?? user.uid, // Added
        );
      }).toList();

      print('Loaded ${_orders.length} orders'); // Debug
      notifyListeners();
    } catch (e) {
      print('Error loading orders from Firestore: $e');
      _orders = [];
      notifyListeners();
    }
  }

  // Get order by ID
  order_model.Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Get total environmental impact
  Map<String, dynamic> getTotalImpact() {
    double totalCO2Saved = 0.0;
    double totalMoneySaved = 0.0;

    for (var order in _orders) {
      totalCO2Saved += order.co2Saved;
      totalMoneySaved += order.moneySaved;
    }

    return {
      'co2Saved': totalCO2Saved,
      'moneySaved': totalMoneySaved,
    };
  }

  // Update expired orders
  Future<void> updateExpiredOrders() async {
    final now = DateTime.now();
    List<order_model.Order> newExpiredOrders = [];

    // Check active orders for expiration
    for (var order in activeOrders) {
      if (order.date.isBefore(now) && !order.isCompleted) {
        newExpiredOrders.add(order);
      }
    }

    // Move expired orders from active to expired list
    if (newExpiredOrders.isNotEmpty) {
      activeOrders.removeWhere((order) =>
          newExpiredOrders.any((expiredOrder) => expiredOrder.id == order.id));
      _expiredOrders.addAll(newExpiredOrders);
      notifyListeners();
    }
  }

  // Archive an expired order
  void archiveExpiredOrder(String orderId) {
    _expiredOrders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  Future<void> completeOrder(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Cannot complete order: No user logged in');
      return;
    }

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      final updatedOrder = order.copyWith(
        isCompleted: true, // Only update isCompleted
      );

      try {
        await FirebaseFirestore.instance
            .collection('detailed_orders')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({
          'isCompleted': true,
          // Do not update co2Saved or moneySaved here
        });

        _orders[index] = updatedOrder;
        await saveOrders();
        notifyListeners();
      } catch (e) {
        print('Error completing order in Firestore: $e');
        throw e;
      }
    } else {
      print('Order with ID $orderId not found');
      throw Exception('Order not found');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Cannot update order status: No user logged in');
      return;
    }

    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      bool isCompleted = status == 'Collected';

      // Calculate impact metrics if the order is being completed
      double co2Saved = order.co2Saved;
      double moneySaved = order.moneySaved;

      if (isCompleted && !order.isCompleted) {
        co2Saved = order.calculateCO2Saved();
        moneySaved = order.calculateMoneySaved();
      }

      // Update the order with new status and impact metrics
      final updatedOrder = order.copyWith(
        isCompleted: isCompleted,
        co2Saved: co2Saved,
        moneySaved: moneySaved,
      );

      try {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('detailed_orders')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({
          'isCompleted': isCompleted,
          'co2Saved': co2Saved,
          'moneySaved': moneySaved,
        });

        // Update local list
        _orders[index] = updatedOrder;
        await saveOrders();
        notifyListeners();
      } catch (e) {
        print('Error updating order status in Firestore: $e');
        throw e; // Rethrow the error so the UI can handle it
      }
    } else {
      print('Order with ID $orderId not found');
      throw Exception('Order not found');
    }
  }

  void updateOrder(order_model.Order updatedOrder) {}
}
