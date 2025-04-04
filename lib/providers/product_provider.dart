import 'package:flutter/foundation.dart';
import 'package:fyp_project/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  Map<String, List<Product>> _productsByCategory = {};

  List<Product> get products => [..._products];
  List<Product> get featuredProducts => [..._featuredProducts];
  Map<String, List<Product>> get productsByCategory => {..._productsByCategory};

  Future<void> loadProducts() async {
    // In a real app, this would be fetched from an API or database
    // For now, we'll use mock data
    _products = generateMockProducts();

    // Create featured products (top-rated or special deals)
    _featuredProducts =
        _products.where((product) => product.rating >= 4.5).toList();

    // Group products by category
    _productsByCategory = {};
    for (var product in _products) {
      if (!_productsByCategory.containsKey(product.category)) {
        _productsByCategory[product.category] = [];
      }
      _productsByCategory[product.category]!.add(product);
    }

    notifyListeners();
  }

  // Get products near user based on distance
  List<Product> getNearbyProducts(
      double userLat, double userLng, double maxDistance) {
    return _products.where((product) {
      // Simple distance calculation (in a real app, use proper geolocation)
      return product.distance <= maxDistance;
    }).toList();
  }

  // Search products by name or store
  List<Product> searchProducts(String query) {
    final lowerCaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.productName.toLowerCase().contains(lowerCaseQuery) ||
          product.storeName.toLowerCase().contains(lowerCaseQuery);
    }).toList();
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    return _productsByCategory[category] ?? [];
  }

  // Generate mock products for testing
  List<Product> generateMockProducts() {
    return [
      Product(
        id: '1',
        productName: 'Surprise Bag',
        storeName: 'Bakery Delight',
        price: '12.90',
        originalPrice: '38.00',
        pickUpTime: '5:00 PM - 6:00 PM',
        rating: 4.7,
        distance: 0.8,
        imagePath: 'assets/images/bakery_bag.png',
        description:
            'Get a surprise selection of our day\'s fresh pastries and bread that would otherwise go to waste. May include croissants, bread, and pastries.',
        availableQuantity: 5,
        category: 'Bakery',
        tags: ['Pastry', 'Bread', 'Vegetarian'],
        latitude: 3.1390,
        longitude: 101.6869,
        co2Saved: 0.5,
        storeAddress: '123 Baker Street, Kuala Lumpur',
      ),
      Product(
        id: '2',
        productName: 'Lunch Box',
        storeName: 'Green Cuisine',
        price: '9.90',
        originalPrice: '25.00',
        pickUpTime: '2:30 PM - 3:30 PM',
        rating: 4.5,
        distance: 1.2,
        imagePath: 'assets/images/lunch_box.png',
        description:
            'Delicious lunch set that may include rice, vegetables, and a protein option. Menu varies daily based on what\'s fresh.',
        availableQuantity: 3,
        category: 'Meals',
        tags: ['Lunch', 'Asian', 'Healthy'],
        latitude: 3.1392,
        longitude: 101.6871,
        co2Saved: 0.8,
        storeAddress: '45 Green Lane, Kuala Lumpur',
      ),
      Product(
        id: '3',
        productName: 'Fruit & Veg Box',
        storeName: 'Fresh Market',
        price: '15.90',
        originalPrice: '35.00',
        pickUpTime: '6:00 PM - 7:00 PM',
        rating: 4.3,
        distance: 2.0,
        imagePath: 'assets/images/veggie_box.png',
        description:
            'A box of mixed fruits and vegetables that are still fresh but would otherwise be discarded. Great for home cooking.',
        availableQuantity: 8,
        category: 'Grocery',
        tags: ['Fruit', 'Vegetables', 'Organic'],
        latitude: 3.1396,
        longitude: 101.6879,
        co2Saved: 1.2,
        storeAddress: '78 Market Street, Kuala Lumpur',
      ),
      Product(
        id: '4',
        productName: 'Sushi Pack',
        storeName: 'Sakura Japanese',
        price: '18.90',
        originalPrice: '45.00',
        pickUpTime: '8:30 PM - 9:30 PM',
        rating: 4.8,
        distance: 1.5,
        imagePath: 'assets/images/sushi_pack.png',
        description:
            'Assorted sushi rolls and nigiri prepared fresh today. May include maki, nigiri, and sashimi varieties.',
        availableQuantity: 2,
        category: 'Japanese',
        tags: ['Sushi', 'Seafood', 'Asian'],
        latitude: 3.1399,
        longitude: 101.6885,
        co2Saved: 0.7,
        storeAddress: '12 Sakura Road, Kuala Lumpur',
      ),
      Product(
        id: '5',
        productName: 'Sandwich Pack',
        storeName: 'Deli Corner',
        price: '11.90',
        originalPrice: '28.00',
        pickUpTime: '4:00 PM - 5:00 PM',
        rating: 4.2,
        distance: 0.6,
        imagePath: 'assets/images/sandwich_pack.png',
        description:
            'A selection of our fresh sandwiches made today. Various fillings possible including chicken, tuna, and vegetarian options.',
        availableQuantity: 4,
        category: 'Deli',
        tags: ['Sandwich', 'Lunch', 'Quick Meal'],
        latitude: 3.1380,
        longitude: 101.6867,
        co2Saved: 0.4,
        storeAddress: '34 Deli Street, Kuala Lumpur',
      ),
      Product(
        id: '6',
        productName: 'Pizza Slices',
        storeName: 'Mama\'s Pizza',
        price: '8.90',
        originalPrice: '22.00',
        pickUpTime: '9:00 PM - 10:00 PM',
        rating: 4.6,
        distance: 1.8,
        imagePath: 'assets/images/pizza_slices.png',
        description:
            'Mix of pizza slices from today\'s menu. May include classic margherita, pepperoni, and vegetarian options.',
        availableQuantity: 6,
        category: 'Italian',
        tags: ['Pizza', 'Italian', 'Fast Food'],
        latitude: 3.1385,
        longitude: 101.6875,
        co2Saved: 0.6,
        storeAddress: '56 Pizza Avenue, Kuala Lumpur',
      ),
      Product(
        id: '7',
        productName: 'Coffee Shop Box',
        storeName: 'Bean There',
        price: '13.90',
        originalPrice: '32.00',
        pickUpTime: '7:00 PM - 8:00 PM',
        rating: 4.4,
        distance: 0.9,
        imagePath: 'assets/images/coffee_shop_box.png',
        description:
            'Assortment of our day\'s pastries, cakes and sandwiches that pair perfectly with coffee.',
        availableQuantity: 3,
        category: 'Cafe',
        tags: ['Pastry', 'Cake', 'Coffee Shop'],
        latitude: 3.1394,
        longitude: 101.6873,
        co2Saved: 0.5,
        storeAddress: '23 Coffee Lane, Kuala Lumpur',
      ),
      Product(
        id: '8',
        productName: 'Dessert Box',
        storeName: 'Sweet Treats',
        price: '10.90',
        originalPrice: '26.00',
        pickUpTime: '8:00 PM - 9:00 PM',
        rating: 4.9,
        distance: 1.3,
        imagePath: 'assets/images/dessert_box.png',
        description:
            'A selection of our premium desserts including cakes, pastries, and confections from today\'s fresh batch.',
        availableQuantity: 4,
        category: 'Dessert',
        tags: ['Cake', 'Sweet', 'Dessert'],
        latitude: 3.1398,
        longitude: 101.6880,
        co2Saved: 0.3,
        storeAddress: '89 Dessert Road, Kuala Lumpur',
      ),
    ];
  }
}
