class Order {
  final String id;
  final String productName;
  final String storeName;
  final String price; // price per unit
  final double originalPrice;
  final int quantity;
  final DateTime date; // Order date, used for pickup time tracking
  final String pickUpTime; // Specific pickup time (e.g., "14:00-15:00")
  final String imagePath;
  final String transactionId;
  final double totalAmount; // Final amount paid
  final bool isCompleted;
  final double co2Saved;
  final double moneySaved;
  final String paymentMethod;
  final bool isRated;
  final String businessId;
  final double? rating;
  final String? userId; // Added to filter orders by user

  Order copyWith({
    String? id,
    String? productName,
    String? storeName,
    String? price,
    double? originalPrice,
    int? quantity,
    DateTime? date,
    String? pickUpTime,
    String? imagePath,
    String? transactionId,
    double? totalAmount,
    bool? isCompleted,
    double? co2Saved,
    double? moneySaved,
    String? paymentMethod,
    bool? isRated,
    String? businessId,
    double? rating,
    String? userId,
  }) {
    return Order(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      pickUpTime: pickUpTime ?? this.pickUpTime,
      imagePath: imagePath ?? this.imagePath,
      transactionId: transactionId ?? this.transactionId,
      totalAmount: totalAmount ?? this.totalAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      co2Saved: co2Saved ?? this.co2Saved,
      moneySaved: moneySaved ?? this.moneySaved,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRated: isRated ?? this.isRated,
      businessId: businessId ?? this.businessId,
      rating: rating ?? this.rating,
      userId: userId ?? this.userId,
    );
  }

  Order({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.originalPrice,
    required this.quantity,
    required this.date,
    required this.pickUpTime,
    required this.imagePath,
    required this.transactionId,
    required this.totalAmount,
    this.isCompleted = false,
    required this.co2Saved,
    required this.moneySaved,
    required this.paymentMethod,
    this.isRated = false,
    required this.businessId,
    this.rating,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'storeName': storeName,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'pickUpTime': pickUpTime,
      'imagePath': imagePath,
      'transactionId': transactionId,
      'totalAmount': totalAmount,
      'isCompleted': isCompleted,
      'co2Saved': co2Saved,
      'moneySaved': moneySaved,
      'paymentMethod': paymentMethod,
      'isRated': isRated,
      'businessId': businessId,
      'rating': rating,
      'userId': userId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      productName: map['productName'] ?? '',
      storeName: map['storeName'] ?? '',
      price: map['price']?.toString() ?? '0',
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      date: DateTime.parse(map['date']),
      pickUpTime: map['pickUpTime'] ?? '',
      imagePath: map['imagePath'] ?? '',
      transactionId: map['transactionId'] ?? '',
      totalAmount: (map['amount'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      co2Saved: (map['co2Saved'] ?? 0.0).toDouble(),
      moneySaved: (map['moneySaved'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      isRated: map['isRated'] ?? false,
      businessId: map['businessId'] ?? '',
      rating: map['rating']?.toDouble(),
      userId: map['userId'],
    );
  }

  String? get status => null;

  get hasRated => null;
  // Calculate CO2 savings based on product type and quantity
  double calculateCO2Saved() {
    Map<String, double> co2PerUnit = {
      'Bread': 0.5,
      'Pastry': 0.3,
      'Sandwich': 0.4,
    };
    double co2PerItem = co2PerUnit[productName.split(' ')[0]] ?? 0.2;
    return co2PerItem * quantity;
  }

  // Calculate money saved (original price vs. paid amount)
  double calculateMoneySaved() {
    double originalPrice = double.parse(price) * quantity;
    return originalPrice - totalAmount;
  }

  // Check if order is expired but not completed
  bool isExpired() {
    return DateTime.now().isAfter(date) && !isCompleted;
  }

  // Get the order status as a string
  String getOrderStatus() {
    if (isCompleted) return 'Completed';
    if (isExpired()) return 'Expired';
    return 'Active';
  }

  // Get remaining time until pickup in hours
  int getRemainingHours() {
    final now = DateTime.now();
    if (now.isAfter(date)) return 0;
    return date.difference(now).inHours;
  }

  // Get formatted pickup date and time
  String getFormattedPickupDateTime() {
    return '${date.day}/${date.month} at $pickUpTime';
  }

  // Get total environmental impact
  Map<String, double> getEnvironmentalImpact() {
    return {
      'co2Saved': co2Saved,
      'moneySaved': moneySaved,
      'foodWastePrevented': quantity * 0.3,
    };
  }
}
