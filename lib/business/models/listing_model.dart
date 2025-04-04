class Listing {
  final String id;
  final String businessId;
  final String? title;
  final double price;
  final double? originalPrice;
  final int quantity;
  final String? pickupStart;
  final String? pickupEnd;
  final String location;
  final String description;
  final String? category;
  final bool? isHalal;
  final DateTime createdAt;
  final String? storeName;
  final double? rating;
  final double? distance;
  final String? imagePath;

  Listing({
    required this.id,
    required this.businessId,
    this.title,
    required this.price,
    this.originalPrice,
    required this.quantity,
    this.pickupStart,
    this.pickupEnd,
    required this.location,
    required this.description,
    this.category,
    this.isHalal,
    required this.createdAt,
    this.storeName,
    this.rating,
    this.distance,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'title': title,
        'price': price,
        'originalPrice': originalPrice,
        'quantity': quantity,
        'pickupStart': pickupStart,
        'pickupEnd': pickupEnd,
        'location': location,
        'description': description,
        'category': category,
        'isHalal': isHalal,
        'createdAt': createdAt.toIso8601String(),
        'storeName': storeName,
        'rating': rating,
        'distance': distance,
        'imagePath': imagePath,
      };

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'],
        businessId: json['businessId'],
        title: json['title'],
        price: json['price'].toDouble(),
        originalPrice: json['originalPrice']?.toDouble(),
        quantity: json['quantity'],
        pickupStart: json['pickupStart'],
        pickupEnd: json['pickupEnd'],
        location: json['location'],
        description: json['description'],
        category: json['category'],
        isHalal: json['isHalal'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        storeName: json['storeName'],
        rating: json['rating']?.toDouble(),
        distance: json['distance']?.toDouble(),
        imagePath: json['imagePath'],
      );
}
