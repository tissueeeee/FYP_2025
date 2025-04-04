class Business {
  final String id;
  final String email;
  final String name;
  final StoreDetails? storeDetails;

  Business({
    required this.id,
    required this.email,
    required this.name,
    this.storeDetails,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'storeDetails': storeDetails?.toJson(),
      };

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'],
        email: json['email'],
        name: json['name'],
        storeDetails: json['storeDetails'] != null
            ? StoreDetails.fromJson(json['storeDetails'])
            : null,
      );
}

class StoreDetails {
  final String storeName;
  final String address;
  final String location;
  final String contact;
  final String? description;
  final String? website;
  final String? businessLicenseUrl;
  final String? healthLicenseUrl;
  final String? profileImageUrl;

  StoreDetails({
    required this.storeName,
    required this.address,
    required this.location,
    required this.contact,
    this.description,
    this.website,
    this.businessLicenseUrl,
    this.healthLicenseUrl,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'address': address,
        'location': location,
        'contact': contact,
        'description': description,
        'website': website,
        'businessLicenseUrl': businessLicenseUrl,
        'healthLicenseUrl': healthLicenseUrl,
        'profileImageUrl': profileImageUrl,
      };

  factory StoreDetails.fromJson(Map<String, dynamic> json) => StoreDetails(
        storeName: json['storeName'] ?? '',
        address: json['address'] ?? '',
        location: json['location'] ?? '',
        contact: json['contact'] ?? '',
        description: json['description'],
        website: json['website'],
        businessLicenseUrl: json['businessLicenseUrl'],
        healthLicenseUrl: json['healthLicenseUrl'],
        profileImageUrl: json['profileImageUrl'],
      );
}
