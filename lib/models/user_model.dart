class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final String avatarUrl;
  final double co2Saved;
  final double moneySaved;
  final int totalOrders;
  final Map<String, double> foodTypesSaved;
  final bool hasBusiness;

  User(
      {required this.id,
      required this.name,
      required this.email,
      required this.phoneNumber,
      required this.address,
      required this.avatarUrl,
      required this.co2Saved,
      required this.moneySaved,
      required this.totalOrders,
      this.foodTypesSaved = const {},
      this.hasBusiness = false});

  // Convert User to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'avatarUrl': avatarUrl,
      'co2Saved': co2Saved,
      'moneySaved': moneySaved,
      'totalOrders': totalOrders,
      'hasBusiness': hasBusiness,
    };
  }

  // Create User from Map (JSON deserialization)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? 'User',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      avatarUrl: map['avatarUrl'] ?? 'assets/avatar.png',
      co2Saved: (map['co2Saved'] ?? 0).toDouble(),
      moneySaved: (map['moneySaved'] ?? 0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      foodTypesSaved: (map['foodTypesSaved'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      hasBusiness: map['hasBusiness'] ?? false,
    );
  }
}
