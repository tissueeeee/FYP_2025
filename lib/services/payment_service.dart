import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double calculateInitialMoneySaved(Map<String, dynamic> orderData) {
    double originalPrice =
        orderData['originalPrice'] ?? (orderData['price'] ?? 0.0);
    int quantity = orderData['quantity'] ?? 1;
    double totalAmount = orderData['amount'] ?? 0.0;
    return (originalPrice * quantity) - totalAmount;
  }

  Future<void> saveDetailedOrderInformation(
      Map<String, dynamic> orderData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');

      final completeOrderData = {
        'id': orderData['transactionId'] ??
            'txn_${DateTime.now().millisecondsSinceEpoch}',
        'productName': orderData['productName'] ?? '',
        'storeName': orderData['storeName'] ?? '',
        'price': orderData['price'] ?? 0.0,
        'originalPrice':
            orderData['originalPrice'] ?? (orderData['price'] ?? 0.0),
        'quantity': orderData['quantity'] ?? 1,
        'date': orderData['orderDate'] ?? DateTime.now(),
        'pickUpTime': orderData['pickUpTime'] ?? '',
        'imagePath': orderData['imagePath'] ?? '',
        'transactionId': orderData['transactionId'] ?? '',
        'totalAmount': orderData['amount'] ?? 0.0,
        'isCompleted': false,
        'co2Saved': orderData['co2Saved'] ?? 0.0,
        'moneySaved': orderData['moneySaved'] ?? 0.0,
        'paymentMethod': orderData['paymentMethod'] ?? '',
        'timestamp': orderData['timestamp'] ?? FieldValue.serverTimestamp(),

        // OPTIONAL: Add additional fields from payment processing
        'paymentDetails': {
          'cardType': orderData['cardType'],
          'lastFourDigits': orderData.containsKey('cardNumber')
              ? orderData['cardNumber']
                  .toString()
                  .substring(orderData['cardNumber'].toString().length - 4)
              : null,
          'eWalletProvider': orderData['eWalletProvider'],
        },

        // OPTIONAL: Add environmental impact tracking
        'environmentalImpact': {
          'co2Saved': _estimateCO2Savings(orderData['productName'] ?? ''),
          'wasteReduced':
              _estimateWasteReduction(orderData['productName'] ?? ''),
        },
      };

      // Save to Firestore with userId as part of the document
      await _firestore
          .collection('detailed_orders')
          .doc(userId)
          .collection('orders')
          .doc(completeOrderData['transactionId'])
          .set(completeOrderData);
    } catch (e) {
      print('Error saving detailed order information: $e');
    }
  }

  // MODIFICATION: Enhanced CO2 savings estimation
  double _estimateCO2Savings(String productName) {
    Map<String, double> carbonSavingsMap = {
      'Bread': 0.5,
      'Pastry': 0.3,
      'Sandwich': 0.4,
      'Product A': 0.2,
      // Expand with more product types and their estimated CO2 savings
    };

    return carbonSavingsMap[productName] ?? 0.1;
  }

  // NEW: Method to estimate waste reduction
  double _estimateWasteReduction(String productName) {
    Map<String, double> wasteReductionMap = {
      'Bread': 0.75, // 75% waste reduction
      'Pastry': 0.6, // 60% waste reduction
      'Sandwich': 0.65, // 65% waste reduction
      'Product A': 0.5, // 50% waste reduction
    };

    return wasteReductionMap[productName] ?? 0.4;
  }

  // Mock payment methods stored for the user
  List<PaymentMethod> _savedPaymentMethods = [];

  Future<void> initialize() async {
    // More comprehensive mock payment methods
    _savedPaymentMethods = [
      PaymentMethod(
        id: '1',
        type: PaymentMethodType.creditCard,
        cardDetails: CardDetails(
          cardNumber: '4242 4242 4242 4242',
          expiryDate: '12/25',
          cardHolderName: 'Bryan Bun',
          cardType: 'Visa',
          cvv: '123',
        ),
      ),
      PaymentMethod(
        id: '2',
        type: PaymentMethodType.creditCard,
        cardDetails: CardDetails(
          cardNumber: '5555 5555 5555 4444',
          expiryDate: '06/24',
          cardHolderName: 'Jane Smith',
          cardType: 'Mastercard',
          cvv: '456',
        ),
      ),
      PaymentMethod(
        id: '3',
        type: PaymentMethodType.eWallet,
        walletDetails: WalletDetails(
          provider: 'Touch n Go eWallet',
          accountNumber: '0123456789',
          email: 'user@example.com',
        ),
      ),
      PaymentMethod(
        id: '4',
        type: PaymentMethodType.eWallet,
        walletDetails: WalletDetails(
          provider: 'Grab Pay',
          accountNumber: '9876543210',
          email: 'user2@example.com',
        ),
      ),
    ];
  }

  // Get saved payment methods for display
  List<PaymentMethod> getSavedPaymentMethods() {
    return _savedPaymentMethods;
  }

  // Enhanced payment processing with more realistic validation
  Future<PaymentResult> makePayment({
    required double amount,
    required PaymentMethodType paymentMethodType,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      // Enhanced validation based on payment method
      if (paymentMethodType == PaymentMethodType.creditCard) {
        if (!_validateCreditCardDetails(paymentDetails)) {
          return PaymentResult(
            success: false,
            message: 'Invalid credit card details',
          );
        }
      } else if (paymentMethodType == PaymentMethodType.eWallet) {
        if (!_validateEWalletDetails(paymentDetails)) {
          return PaymentResult(
            success: false,
            message: 'Invalid e-wallet details',
          );
        }
      }

      // Simulate more realistic payment processing
      bool isSuccessful = _simulatePaymentProcessing(paymentMethodType, amount);

      if (isSuccessful) {
        // Generate a unique transaction ID
        String transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';

        // Prepare order data with all necessary fields
        final completeOrderData = {
          ...paymentDetails,
          'transactionId': transactionId,
          'paymentMethod': paymentMethodType.toString(),
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'active',
          'userId': _auth.currentUser?.uid,
          'id': transactionId,
          'isCompleted': false,
          'isRated': false,
          'rating': null,
          // Ensure these fields are included from paymentDetails or calculated
          'co2Saved': paymentDetails['co2Saved'] ?? 0.0,
          'quantity': paymentDetails['quantity'] ?? 1,
          'businessId': paymentDetails['businessId'] ?? '', // Critical field
          'moneySaved': paymentDetails['moneySaved'] ?? 0.0,
          'productName': paymentDetails['productName'] ?? '',
          'storeName': paymentDetails['storeName'] ?? '',
        };

        print('Saving order to Firestore: $completeOrderData'); // Debug log

        // Save to the top-level 'orders' collection
        final docRef = await _firestore
            .collection('orders')
            .doc(transactionId)
            .set(completeOrderData);

        // Save detailed order information
        await saveDetailedOrderInformation({
          ...completeOrderData,
          'amount': amount,
        });

        return PaymentResult(
          success: true,
          transactionId: transactionId,
          message: 'Payment completed successfully',
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment failed. Please try another payment method.',
        );
      }
    } catch (e) {
      print('Payment error: $e'); // Debug log
      return PaymentResult(
        success: false,
        message: 'Payment error: ${e.toString()}',
      );
    }
  }

  // Enhanced credit card validation
  bool _validateCreditCardDetails(Map<String, dynamic> details) {
    final cardNumber = details['cardNumber']?.replaceAll(' ', '') ?? '';
    final expiry = details['expiry'] ?? '';
    final cvv = details['cvv'] ?? '';
    final cardHolderName = details['cardHolderName'] ?? '';

    bool isCardNumberValid = cardNumber.length >= 12 &&
        cardNumber.length <= 19 &&
        _luhnAlgorithmValidation(cardNumber);
    bool isExpiryValid = _validateExpiryDate(expiry);
    bool isCvvValid = cvv.length == 3 || cvv.length == 4;
    bool isNameValid =
        cardHolderName.trim().isNotEmpty && cardHolderName.contains(' ');

    // Debugging statements
    print('DEBUG: cardNumber: $cardNumber, valid: $isCardNumberValid');
    if (!isCardNumberValid) print('Invalid card number: $cardNumber');
    print('DEBUG: expiry: $expiry, valid: $isExpiryValid');
    if (!isExpiryValid) print('Invalid expiry date: $expiry');
    print('DEBUG: cvv: $cvv, valid: $isCvvValid');
    if (!isCvvValid) print('Invalid CVV: $cvv');
    print('DEBUG: cardHolderName: $cardHolderName, valid: $isNameValid');
    if (!isNameValid) print('Invalid card holder name: $cardHolderName');

    return isCardNumberValid && isExpiryValid && isCvvValid && isNameValid;
  }

  // Validate e-wallet details
  bool _validateEWalletDetails(Map<String, dynamic> details) {
    final accountNumber = details['accountNumber'] ?? '';
    final email = details['email'] ?? '';
    final provider = details['provider'] ?? '';

    return accountNumber.isNotEmpty &&
        email.contains('@') &&
        provider.isNotEmpty;
  }

  // Luhn algorithm for credit card number validation
  bool _luhnAlgorithmValidation(String cardNumber) {
    int sum = 0;
    bool isEven = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  // Validate expiry date
  bool _validateExpiryDate(String expiry) {
    if (expiry.length != 5 || !expiry.contains('/')) return false;

    try {
      final parts = expiry.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      final now = DateTime.now();
      // Set to the first day of the next month
      final expiryDate = DateTime(2000 + year, month + 1, 1);
      return now.isBefore(expiryDate);
    } catch (e) {
      return false;
    }
  }

  // Simulate payment processing with more realistic scenarios
  bool _simulatePaymentProcessing(PaymentMethodType type, double amount) {
    // Different success rates and conditions for different payment methods
    switch (type) {
      case PaymentMethodType.creditCard:
        // 95% success rate for credit cards
        return Random().nextInt(100) < 95;
      case PaymentMethodType.eWallet:
        // 90% success rate for e-wallets
        return Random().nextInt(100) < 90;
      default:
        // Fallback
        return Random().nextInt(100) < 80;
    }
  }

  // Validate card details
  bool _validateCardDetails(Map<String, dynamic> details) {
    final cardNumber = details['cardNumber'];
    final expiry = details['expiry'];
    final cvv = details['cvv'];

    return cardNumber.length == 16 && expiry.length == 5 && cvv.length == 3;
  }

  // Save transaction to history for order tracking
  Future<void> _saveTransactionToHistory(
      double amount, PaymentMethodType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('transaction_history') ?? [];

      // Create a simple transaction record
      Map<String, dynamic> transaction = {
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'method': type.toString(),
        'id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      };

      history.add(transaction.toString());
      await prefs.setStringList('transaction_history', history);
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Add a new payment method
  Future<bool> addPaymentMethod(PaymentMethod method) async {
    // In a real app, you would validate and securely store the payment info
    _savedPaymentMethods.add(method);
    return true;
  }

  // Remove a payment method
  Future<bool> removePaymentMethod(String id) async {
    _savedPaymentMethods.removeWhere((method) => method.id == id);
    return true;
  }

  // Fetch user's active orders
  Stream<List<Map<String, dynamic>>> getActiveOrders() {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Mark order as completed
  Future<void> completeOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // New method to fetch detailed order history
  Future<List<Map<String, dynamic>>> getDetailedOrderHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching detailed order history: $e');
      return [];
    }
  }

  // Calculate total environmental impact
  Future<Map<String, dynamic>> calculateEnvironmentalImpact() async {
    try {
      final orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'active')
          .get();

      double totalCO2Saved = 0.0;
      double totalMoneySaved = 0.0;
      int totalItemsRescued = 0;

      for (var doc in orders.docs) {
        final data = doc.data();
        totalCO2Saved += (data['co2Saved'] ?? 0.0);
        totalMoneySaved += (data['moneySaved'] ?? 0.0);
        totalItemsRescued += (data['quantity'] ?? 0) as int;
      }

      return {
        'totalCO2Saved': totalCO2Saved,
        'totalMoneySaved': totalMoneySaved,
        'totalItemsRescued': totalItemsRescued,
      };
    } catch (e) {
      print('Error calculating environmental impact: $e');
      return {
        'totalCO2Saved': 0.0,
        'totalMoneySaved': 0.0,
        'totalItemsRescued': 0,
      };
    }
  }

  // Analyze payment methods used
  Future<Map<String, int>> analyzePaymentMethods() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .get();

      Map<String, int> paymentMethodCount = {};

      for (var doc in querySnapshot.docs) {
        final paymentMethod = doc.data()['paymentMethod'] as String?;
        if (paymentMethod != null) {
          paymentMethodCount[paymentMethod] =
              (paymentMethodCount[paymentMethod] ?? 0) + 1;
        }
      }

      return paymentMethodCount;
    } catch (e) {
      print('Error analyzing payment methods: $e');
      return {};
    }
  }

  // Get stores frequently ordered from
  Future<List<Map<String, dynamic>>> getFrequentStores() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .get();

      Map<String, int> storeFrequency = {};
      Map<String, double> storeTotalSpent = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final storeName = data['storeName'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        if (storeName != null) {
          storeFrequency[storeName] = (storeFrequency[storeName] ?? 0) + 1;
          storeTotalSpent[storeName] =
              (storeTotalSpent[storeName] ?? 0) + amount;
        }
      }

      return storeFrequency.keys
          .map((storeName) => {
                'storeName': storeName,
                'frequency': storeFrequency[storeName],
                'totalSpent': storeTotalSpent[storeName],
              })
          .toList()
        ..sort(
            (a, b) => (b['frequency'] as int).compareTo(a['frequency'] as int));
    } catch (e) {
      print('Error getting frequent stores: $e');
      return [];
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return {...doc.data()!, 'id': doc.id};
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Get user's completed orders
  Stream<List<Map<String, dynamic>>> getCompletedOrders() {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Mark expired orders as expired
  Future<void> updateExpiredOrders() async {
    final now = DateTime.now();
    final querySnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('pickupTime')) {
        final pickupTime = (data['pickupTime'] as Timestamp).toDate();
        if (now.isAfter(pickupTime)) {
          await _firestore.collection('orders').doc(doc.id).update({
            'status': 'expired',
            'expiredAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // Get user's total impact statistics
  Future<Map<String, dynamic>> getUserImpactStatistics() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalCO2Saved = 0.0;
      double totalMoneySaved = 0.0;
      int totalMealsRescued = 0;
      double totalWasteReduced = 0.0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalCO2Saved += (data['co2Saved'] ?? 0.0);
        totalMoneySaved += (data['moneySaved'] ?? 0.0);
        totalMealsRescued += (data['quantity'] ?? 0) as int;
        totalWasteReduced +=
            ((data['quantity'] ?? 0) as int) * 0.3; // Estimate 0.3kg per item
      }

      return {
        'totalCO2Saved': totalCO2Saved,
        'totalMoneySaved': totalMoneySaved,
        'totalMealsRescued': totalMealsRescued,
        'totalWasteReduced': totalWasteReduced,
        'treesEquivalent':
            totalCO2Saved / 21, // Average tree absorbs ~21kg CO2 per year
        'carKilometersEquivalent': totalCO2Saved * 4, // ~250g CO2 per km
      };
    } catch (e) {
      print('Error calculating user impact statistics: $e');
      return {
        'totalCO2Saved': 0.0,
        'totalMoneySaved': 0.0,
        'totalMealsRescued': 0,
        'totalWasteReduced': 0.0,
        'treesEquivalent': 0.0,
        'carKilometersEquivalent': 0.0,
      };
    }
  }

  // Generate receipt data for an order
  Future<Map<String, dynamic>> generateReceiptData(String orderId) async {
    try {
      final orderData = await getOrderById(orderId);
      if (orderData == null) {
        throw Exception('Order not found');
      }

      return {
        'receiptId': 'RCP${DateTime.now().millisecondsSinceEpoch}',
        'orderId': orderId,
        'orderDate': orderData['timestamp'] ?? DateTime.now(),
        'storeName': orderData['storeName'] ?? 'Unknown Store',
        'items': [
          {
            'name': orderData['productName'] ?? 'Unknown Product',
            'quantity': orderData['quantity'] ?? 1,
            'originalPrice': orderData['price'] ?? 0.0,
            'discountedPrice': orderData['amount'] ?? 0.0,
          }
        ],
        'totalOriginal':
            orderData['price'] != null && orderData['quantity'] != null
                ? (orderData['price'] as num) * (orderData['quantity'] as num)
                : 0.0,
        'totalDiscounted': orderData['amount'] ?? 0.0,
        'totalSaved': orderData['moneySaved'] ?? 0.0,
        'co2Saved': orderData['co2Saved'] ?? 0.0,
        'paymentMethod': orderData['paymentMethod'] ?? 'Unknown',
        'receiptGenerated': DateTime.now(),
      };
    } catch (e) {
      print('Error generating receipt: $e');
      return {};
    }
  }

  // double _estimateCO2Savings(String productName) {
  //   // Placeholder method - replace with actual scientific calculations
  //   Map<String, double> carbonSavingsMap = {
  //     'Bread': 0.5,
  //     'Pastry': 0.3,
  //     'Sandwich': 0.4,
  //     'Product A': 0.2,
  //     // Add more products as needed
  //   };

  //   return carbonSavingsMap[productName] ?? 0.1;
  // }

  // For confirm order collection
  Future<void> confirmOrderCollection(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update the order status in the correct Firestore collection
      await _firestore
          .collection('detailed_orders')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Get the order details to calculate impact (optional, as in your original code)
      final orderData = await getOrderById(orderId);
      if (orderData != null) {
        await _updateUserImpactStatistics(
          co2Saved: orderData['co2Saved'] ?? 0.0,
          moneySaved: orderData['moneySaved'] ?? 0.0,
          quantity: orderData['quantity'] ?? 1,
        );
      }

      print('Order $orderId confirmed as collected');
    } catch (e) {
      print('Error confirming order collection: $e');
      throw e;
    }
  }

// Helper method to update user impact statistics
  Future<void> _updateUserImpactStatistics({
    required double co2Saved,
    required double moneySaved,
    required int quantity,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get existing stats
      final userStatsDoc =
          await _firestore.collection('user_stats').doc(userId).get();

      if (userStatsDoc.exists) {
        // Update existing stats
        final currentStats = userStatsDoc.data() ?? {};
        await _firestore.collection('user_stats').doc(userId).update({
          'totalCO2Saved': (currentStats['totalCO2Saved'] ?? 0.0) + co2Saved,
          'totalMoneySaved':
              (currentStats['totalMoneySaved'] ?? 0.0) + moneySaved,
          'totalItemsRescued':
              (currentStats['totalItemsRescued'] ?? 0) + quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new stats document
        await _firestore.collection('user_stats').doc(userId).set({
          'totalCO2Saved': co2Saved,
          'totalMoneySaved': moneySaved,
          'totalItemsRescued': quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
      }
    } catch (e) {
      print('Error updating user statistics: $e');
    }
  }
}

// Payment method types
enum PaymentMethodType {
  creditCard,
  eWallet,
  cashOnPickup,
}

// Payment method model
class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final CardDetails? cardDetails;
  final WalletDetails? walletDetails;

  PaymentMethod({
    required this.id,
    required this.type,
    this.cardDetails,
    this.walletDetails,
  });
}

// Card details model
class CardDetails {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String cardType;
  final String cvv;

  CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.cardType,
    required this.cvv,
  });
}

// E-wallet details model
class WalletDetails {
  final String provider;
  final String accountNumber;
  final String? email;

  WalletDetails({
    required this.provider,
    required this.accountNumber,
    this.email,
  });
}

// Payment result model
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
  });
}
