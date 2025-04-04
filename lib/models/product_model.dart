class Product {
  final String id;
  final String productName;
  final String storeName;
  final String price;
  final String originalPrice;
  final String pickUpTime;
  final double rating;
  final double distance;
  final String imagePath;
  final String description;
  final int availableQuantity;
  final String category;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final double co2Saved;
  final String storeAddress;

  Product({
    required this.id,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.originalPrice,
    required this.pickUpTime,
    required this.rating,
    required this.distance,
    required this.imagePath,
    required this.description,
    required this.availableQuantity,
    required this.category,
    required this.tags,
    required this.latitude,
    required this.longitude,
    required this.co2Saved,
    required this.storeAddress,
  });

  // Convert Product to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'storeName': storeName,
      'price': price,
      'originalPrice': originalPrice,
      'pickUpTime': pickUpTime,
      'rating': rating,
      'distance': distance,
      'imagePath': imagePath,
      'description': description,
      'availableQuantity': availableQuantity,
      'category': category,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
      'co2Saved': co2Saved,
      'storeAddress': storeAddress,
    };
  }

  // Create Product from Map (JSON deserialization)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      productName: map['productName'],
      storeName: map['storeName'],
      price: map['price'],
      originalPrice: map['originalPrice'],
      pickUpTime: map['pickUpTime'],
      rating: map['rating'].toDouble(),
      distance: map['distance'].toDouble(),
      imagePath: map['imagePath'],
      description: map['description'],
      availableQuantity: map['availableQuantity'],
      category: map['category'],
      tags: List<String>.from(map['tags']),
      latitude: map['latitude'].toDouble(),
      longitude: map['longitude'].toDouble(),
      co2Saved: map['co2Saved'].toDouble(),
      storeAddress: map['storeAddress'],
    );
  }

  // Create a copy of Product with modified fields
  Product copyWith({
    String? id,
    String? productName,
    String? storeName,
    String? price,
    String? originalPrice,
    String? pickUpTime,
    double? rating,
    double? distance,
    String? imagePath,
    String? description,
    int? availableQuantity,
    String? category,
    List<String>? tags,
    double? latitude,
    double? longitude,
    double? co2Saved,
    String? storeAddress,
  }) {
    return Product(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      pickUpTime: pickUpTime ?? this.pickUpTime,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      co2Saved: co2Saved ?? this.co2Saved,
      storeAddress: storeAddress ?? this.storeAddress,
    );
  }
}
