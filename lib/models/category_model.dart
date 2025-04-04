class Category {
  final String id;
  final String name;
  final String iconPath;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.iconPath,
    this.description = "",
  });

  // For serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'description': description,
    };
  }

  // For deserialization
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconPath: map['iconPath'],
      description: map['description'],
    );
  }
}

// Predefined categories for the app
List<Category> predefinedCategories = [
  Category(
    id: 'bakery',
    name: 'Bakery',
    iconPath: 'assets/icons/bakery.png',
    description: 'Freshly baked bread, pastries, and more',
  ),
  Category(
    id: 'restaurant',
    name: 'Restaurant',
    iconPath: 'assets/icons/restaurant.png',
    description: 'Meals and dishes from your favorite restaurants',
  ),
  Category(
    id: 'cafe',
    name: 'Café',
    iconPath: 'assets/icons/cafe.png',
    description: 'Coffee, snacks, and light meals',
  ),
  Category(
    id: 'grocery',
    name: 'Grocery',
    iconPath: 'assets/icons/grocery.png',
    description: 'Fresh produce and packaged foods',
  ),
  Category(
    id: 'convenience',
    name: 'Convenience',
    iconPath: 'assets/icons/convenience.png',
    description: 'Quick and easy food options',
  ),
];
