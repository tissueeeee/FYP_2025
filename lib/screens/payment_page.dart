import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_project/providers/order_provider.dart';
import 'package:fyp_project/services/payment_service.dart';
import 'package:fyp_project/screens/order_confirmation_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final newText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        newText.write('/');
      }
      newText.write(text[i]);
    }
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final newText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) {
        newText.write(' ');
      }
      newText.write(text[i]);
    }
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final String productName;
  final String storeName;
  final String price;
  final String? originalPrice;
  final String pickUpTime;
  final String imagePath;
  final int quantity;
  final double totalPrice;
  final String? businessId;

  const PaymentPage({
    Key? key,
    required this.productName,
    required this.storeName,
    required this.price,
    this.originalPrice,
    required this.pickUpTime,
    required this.imagePath,
    this.quantity = 1,
    required this.totalPrice,
    this.businessId,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final PaymentService _paymentService = PaymentService();
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.creditCard;
  bool _isProcessing = false;
  String _promoCode = '';
  double _discount = 0.0;
  int _quantity = 1;

  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _eWalletAccountController = TextEditingController();
  final _eWalletEmailController = TextEditingController();
  final _promoCodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Bank selection for credit/debit card
  String? _selectedBank;
  final List<String> _banks = [
    'Maybank',
    'CIMB Bank',
    'Public Bank',
    'RHB Bank',
    'Hong Leong Bank',
    'AmBank',
    'Bank Islam',
    'HSBC Bank',
    'Standard Chartered',
    'OCBC Bank',
  ];

  // Voucher selection
  String? _selectedVoucher;
  final List<Map<String, String>> _vouchers = [
    {'name': 'None', 'condition': ''},
    {'name': 'RM5 Off (Min. RM20)', 'condition': 'Minimum spend RM20'},
    {'name': '10% Off (Min. RM30)', 'condition': 'Minimum spend RM30'},
    {'name': 'Free Delivery (Min. RM50)', 'condition': 'Minimum spend RM50'},
  ];

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
    _quantity = widget.quantity;
    _selectedVoucher = _vouchers[0]['name']; // Default to "None"
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _eWalletAccountController.dispose();
    _eWalletEmailController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    setState(() {
      _promoCode = _promoCodeController.text.trim();
    });
    if (_promoCode.toLowerCase() == 'save10') {
      setState(() {
        _discount = 0.1; // 10% discount
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code applied: 10% discount')),
      );
    } else if (_promoCode.toLowerCase() == 'save20') {
      setState(() {
        _discount = 0.2; // 20% discount
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code applied: 20% discount')),
      );
    } else {
      setState(() {
        _discount = 0.0; // Reset discount if invalid
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid promo code')),
      );
    }
  }

  void _applyVoucher() {
    if (_selectedVoucher == 'RM5 Off (Min. RM20)') {
      final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
      final double subtotal = parsedPrice * _quantity;
      if (subtotal >= 20) {
        setState(() {
          _discount = 5 / subtotal; // RM5 off as a percentage of subtotal
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher applied: RM5 off')),
        );
      } else {
        setState(() {
          _discount = 0.0;
          _selectedVoucher = 'None';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum spend of RM20 required')),
        );
      }
    } else if (_selectedVoucher == '10% Off (Min. RM30)') {
      final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
      final double subtotal = parsedPrice * _quantity;
      if (subtotal >= 30) {
        setState(() {
          _discount = 0.1; // 10% off
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher applied: 10% off')),
        );
      } else {
        setState(() {
          _discount = 0.0;
          _selectedVoucher = 'None';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum spend of RM30 required')),
        );
      }
    } else if (_selectedVoucher == 'Free Delivery (Min. RM50)') {
      final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
      final double subtotal = parsedPrice * _quantity;
      if (subtotal >= 50) {
        // Assuming free delivery doesn't affect the price directly in this context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher applied: Free delivery')),
        );
      } else {
        setState(() {
          _selectedVoucher = 'None';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum spend of RM50 required')),
        );
      }
    } else {
      setState(() {
        _discount = 0.0; // Reset discount if "None" is selected
      });
    }
  }

  void _increaseQuantity() {
    setState(() {
      if (_quantity < 10) {
        _quantity++;
        _applyVoucher(); // Reapply voucher to check minimum spend
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 items per order')),
        );
      }
    });
  }

  void _decreaseQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
        _applyVoucher(); // Reapply voucher to check minimum spend
      }
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
      final double originalPrice = widget.originalPrice != null
          ? double.parse(widget.originalPrice!)
          : parsedPrice / 0.35;
      final double subtotal = parsedPrice * _quantity;
      final double discountAmount = subtotal * _discount;
      final double tax = subtotal * 0.06;
      final double total = subtotal - discountAmount + tax;
      final double moneySaved = (originalPrice * _quantity) - subtotal;

      final double co2Saved = _quantity * 0.5;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      Map<String, dynamic> orderData = {
        'productName': widget.productName,
        'storeName': widget.storeName,
        'price': parsedPrice,
        'originalPrice': originalPrice,
        'quantity': _quantity,
        'pickUpTime': widget.pickUpTime,
        'imagePath': widget.imagePath,
        'moneySaved': moneySaved.abs(),
        'co2Saved': co2Saved,
        'amount': total,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'tax': tax,
        'paymentMethod': _selectedPaymentMethod.toString(),
        'status': 'active',
        'userId': userId,
        'transactionId': '',
        'orderDate': DateTime.now(),
        'isRated': false,
        'isCompleted': false,
        'voucher': _selectedVoucher,
        'promoCode': _promoCode,
        ...(_selectedPaymentMethod == PaymentMethodType.creditCard
            ? {
                'cardNumber': _cardNumberController.text,
                'cardHolderName': _cardHolderNameController.text,
                'expiry': _expiryDateController.text,
                'cvv': _cvvController.text,
                'bank': _selectedBank,
              }
            : {}),
      };

      print('Order Data: $orderData');

      final result = await _paymentService.makePayment(
        amount: total,
        paymentMethodType: _selectedPaymentMethod,
        paymentDetails: orderData,
      );

      if (result.success) {
        orderData['transactionId'] = result.transactionId ?? '';

        await FirebaseFirestore.instance
            .collection('detailed_orders')
            .doc(userId)
            .collection('orders')
            .doc(result.transactionId ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .set(orderData);

        await _paymentService.saveDetailedOrderInformation({
          ...orderData,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _awardLoyaltyPoints(userId, 15, 'Payment completed');

        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.loadOrders();
        await Future.delayed(Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(
              productName: widget.productName,
              storeName: widget.storeName,
              price: widget.price,
              quantity: _quantity,
              pickUpTime: widget.pickUpTime,
              imagePath: widget.imagePath,
              transactionId: result.transactionId ?? '',
              total: total,
              originalPrice: originalPrice.toStringAsFixed(2),
              moneySaved: moneySaved.abs(),
              co2Saved: co2Saved,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _awardLoyaltyPoints(
      String userId, int points, String description) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'loyaltyPoints': FieldValue.increment(points),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pointsActivity')
          .add({
        'points': points,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You earned $points loyalty points!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error awarding loyalty points: $e');
    }
  }

  // Validation methods
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    final cleanedValue = value.replaceAll(' ', '');
    if (cleanedValue.length < 12 || cleanedValue.length > 19) {
      return 'Invalid card number';
    }
    return null;
  }

  String? _validateCardHolderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card holder name is required';
    }
    if (!value.contains(' ')) {
      return 'Please enter full name';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    final RegExp regex = RegExp(r'^\d{2}/\d{2}$');
    if (!regex.hasMatch(value)) {
      return 'Invalid format. Use MM/YY';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    if (value.length < 3 || value.length > 4) {
      return 'Invalid CVV';
    }
    return null;
  }

  String? _validateEWalletAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Account number is required';
    }
    return null;
  }

  String? _validateEWalletEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validateBank(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a bank';
    }
    return null;
  }

  // Show voucher selection dialog
  Future<void> _showVoucherDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a Voucher',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ..._vouchers.map((voucher) {
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.local_offer,
                          color: _selectedVoucher == voucher['name']
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(
                          voucher['name']!,
                          style: TextStyle(
                            fontWeight: _selectedVoucher == voucher['name']
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          voucher['condition']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, voucher['name']);
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedVoucher = selected;
        _applyVoucher();
      });
    }
  }

  // Payment method input form
  Widget _buildPaymentMethodForm() {
    switch (_selectedPaymentMethod) {
      case PaymentMethodType.creditCard:
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Select Bank',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                items: _banks.map((String bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(bank),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBank = newValue;
                  });
                },
                validator: _validateBank,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'xxxx xxxx xxxx xxxx',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                validator: _validateCardNumber,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardHolderNameController,
                decoration: const InputDecoration(
                  labelText: 'Card Holder Name',
                  hintText: 'Card Holder Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateCardHolderName,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryDateFormatter(),
                      ],
                      validator: _validateExpiryDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '***',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: _validateCVV,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case PaymentMethodType.eWallet:
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _eWalletAccountController,
                decoration: const InputDecoration(
                  labelText: 'E-Wallet Account Number',
                  hintText: '0123456789',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.number,
                validator: _validateEWalletAccount,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      case PaymentMethodType.cashOnPickup:
        return Form(
          key: _formKey,
          child: Text(
            'Pay with cash when picking up your order. No additional details required.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
    final double originalPrice = widget.originalPrice != null
        ? double.parse(widget.originalPrice!)
        : parsedPrice / 0.35;
    final double subtotal = parsedPrice * _quantity;
    final double discountAmount = subtotal * _discount;
    final double tax = subtotal * 0.06;
    final double total = subtotal - discountAmount + tax;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout for Food Waste Reduction"),
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  const Text("Processing payment..."),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Order Summary",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    widget.imagePath,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.productName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.store,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.storeName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "Pick up: ${widget.pickUpTime}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: _decreaseQuantity,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "$_quantity",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _increaseQuantity,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 215, 249, 217),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "RM${parsedPrice.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 56, 142, 60),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            "RM${originalPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${((1 - (parsedPrice / originalPrice)) * 100).round()}%",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Voucher and Promo Code Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Vouchers & Promo Codes",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _showVoucherDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_offer,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _selectedVoucher ?? 'Select Voucher',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _selectedVoucher == 'None'
                                                ? Colors.grey[600]
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _promoCodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter Promo Code',
                                      prefixIcon: Icon(Icons.discount),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _applyPromoCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  child: const Text('Apply'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: const Text(
                                "Payment Method",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPaymentMethodItem(
                                PaymentMethodType.creditCard,
                                Icons.credit_card,
                                "Credit/Debit Card"),
                            const Divider(height: 1),
                            _buildPaymentMethodItem(PaymentMethodType.eWallet,
                                Icons.account_balance_wallet, "E-wallet"),
                            const Divider(height: 1),
                            _buildPaymentMethodItem(
                                PaymentMethodType.cashOnPickup,
                                Icons.money,
                                "Cash on Pickup"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Details Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Payment Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentMethodForm(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Price Breakdown Section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildPriceBreakdown(
                            subtotal, discountAmount, tax, total),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildPaymentButton(total),
    );
  }

  // Build payment method item
  Widget _buildPaymentMethodItem(
      PaymentMethodType type, IconData icon, String label) {
    return RadioListTile<PaymentMethodType>(
      value: type,
      groupValue: _selectedPaymentMethod,
      onChanged: (PaymentMethodType? value) {
        setState(() {
          _selectedPaymentMethod = value!;
        });
      },
      title: Text(label),
      secondary: Icon(icon),
    );
  }

  // Build price breakdown
  Widget _buildPriceBreakdown(
      double subtotal, double discountAmount, double tax, double total) {
    final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
    final double originalPrice = widget.originalPrice != null
        ? double.parse(widget.originalPrice!)
        : parsedPrice / 0.35;
    final double originalSubtotal = originalPrice * _quantity;
    final double totalSavings = originalSubtotal - subtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Price Breakdown",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Original Price",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              "RM${originalSubtotal.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Subtotal (Discounted)",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "RM${subtotal.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_discount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Promo Discount",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              Text(
                "-RM${discountAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Tax (6%)",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "RM${tax.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total Savings",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            Text(
              "RM${totalSavings.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total to Pay",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "RM${total.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 56, 142, 60)),
            ),
          ],
        ),
      ],
    );
  }

  // Build payment button
  Widget _buildPaymentButton(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _isProcessing ? null : () => _processPayment(),
        child: Text(
          _isProcessing ? "Processing..." : "Confirm Payment",
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
