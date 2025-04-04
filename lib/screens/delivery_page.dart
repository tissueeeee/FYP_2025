import 'package:flutter/material.dart';
import 'delivery_product_page.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  _DeliveryPageState createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final List<String> filters = [
    'Delivery',
    'Special offers',
    'Halal',
    'Non-Halal',
    'Vegetarian',
    'Snacks',
    'Drinks'
  ];
  Set<String> selectedFilters = {'Delivery', 'Special offers'};

  final List<Category> categories = [
    Category(
      name: "Supermarket",
      icon: Icons.local_grocery_store,
      stores: [
        Store(
          name: "Lotus's Cheras",
          image: 'assets/images/deliverystore1.png',
          description: "Save on groceries and daily essentials",
          address: "Jalan Cheras, Kuala Lumpur",
          rating: 4.6,
          products: List.generate(
            5,
            (i) => Product(
              name: "Grocery Surplus Pack ${i + 1}",
              originalPrice: 45.00,
              discountPrice: 22.50,
              isNew: i == 0,
              image: 'assets/images/grocery.png',
              description: "Surplus food of the day",
            ),
          ),
        ),
        Store(
          name: "TF Value Mart Cheras",
          image: 'assets/images/deliverystore2.png',
          description: "Quality products at value prices",
          address: "Taman Connaught, Cheras",
          rating: 4.4,
          products: List.generate(
            4,
            (i) => Product(
              name: "Value Surplus Pack ${i + 1}",
              originalPrice: 35.00,
              discountPrice: 15.99,
              isNew: i == 1,
              image: 'assets/images/grocery.png',
              description: "Best before in a few days",
            ),
          ),
        ),
        Store(
          name: "99 Speedmart Taman Midah",
          image: 'assets/images/deliverystore3.png',
          description: "Quick grocery shopping with great deals",
          address: "Taman Midah, Cheras",
          rating: 4.2,
          products: List.generate(
            3,
            (i) => Product(
              name: "Daily Essentials Surplus ${i + 1}",
              originalPrice: 25.00,
              discountPrice: 12.50,
              image: 'assets/images/grocery.png',
              description: "Surplus food of the day",
            ),
          ),
        ),
      ],
    ),
    Category(
      name: "Bakery",
      icon: Icons.bakery_dining,
      stores: [
        Store(
          name: "Berry's Cake House Cheras",
          image: 'assets/images/deliverystore4.png',
          description: "Freshly baked cakes and pastries",
          address: "Taman Segar, Cheras",
          rating: 4.7,
          products: List.generate(
            4,
            (i) => Product(
              name: "Pastry Surplus Box ${i + 1}",
              originalPrice: 28.00,
              discountPrice: 13.99,
              isNew: i == 0,
              image: 'assets/images/bakery.png',
              description: "Best before in a few days",
            ),
          ),
        ),
        Store(
          name: "Lavender Bakery Cheras Selatan",
          image: 'assets/images/deliverystore5.png',
          description: "Delightful bread and pastries",
          address: "Cheras Selatan, Kuala Lumpur",
          rating: 4.5,
          products: List.generate(
            3,
            (i) => Product(
              name: "Bread Surplus Selection ${i + 1}",
              originalPrice: 22.00,
              discountPrice: 10.99,
              image: 'assets/images/bakery.png',
              description: "Surplus food of the day",
            ),
          ),
        ),
      ],
    ),
    Category(
      name: "Convenience Store",
      icon: Icons.storefront,
      stores: [
        Store(
          name: "7-Eleven Taman Connaught",
          image: 'assets/images/deliverystore6.png',
          description: "24/7 convenience store",
          address: "Taman Connaught, Cheras",
          rating: 4.3,
          products: List.generate(
            4,
            (i) => Product(
              name: "Snack Surplus Box ${i + 1}",
              originalPrice: 18.00,
              discountPrice: 8.99,
              isNew: i == 2,
              image: 'assets/images/convenience.png',
              description: "Best before in a few days",
            ),
          ),
        ),
        Store(
          name: "KK Mart Taman Midah",
          image: 'assets/images/deliverystore7.png',
          description: "Local convenience store with great deals",
          address: "Taman Midah, Cheras",
          rating: 4.1,
          products: List.generate(
            3,
            (i) => Product(
              name: "Ready Meal Surplus ${i + 1}",
              originalPrice: 15.00,
              discountPrice: 7.50,
              image: 'assets/images/convenience.png',
              description: "Surplus food of the day",
            ),
          ),
        ),
      ],
    ),
    Category(
      name: "Groceries",
      icon: Icons.shopping_basket,
      stores: [
        Store(
          name: "Jaya Grocer Cheras",
          image: 'assets/images/deliverystore9.png',
          description: "Premium grocery shopping experience",
          address: "Cheras Sentral, Kuala Lumpur",
          rating: 4.8,
          products: List.generate(
            5,
            (i) => Product(
              name: "Premium Veggie Surplus ${i + 1}",
              originalPrice: 40.00,
              discountPrice: 20.00,
              isNew: i == 0,
              image: 'assets/images/vegetables.png',
              description: "Best before in a few days",
            ),
          ),
        ),
        Store(
          name: "Village Grocer Cheras",
          image: 'assets/images/deliverystore10.png',
          description: "Quality groceries and fresh produce",
          address: "Eko Cheras Mall, Kuala Lumpur",
          rating: 4.6,
          products: List.generate(
            4,
            (i) => Product(
              name: "Fruit Surplus Selection ${i + 1}",
              originalPrice: 35.00,
              discountPrice: 17.50,
              isNew: i == 1,
              image: 'assets/images/vegetables.png',
              description: "Surplus food of the day",
            ),
          ),
        ),
      ],
    ),
  ];

  void _showHowToUsePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Use"),
        content: const Text("1. Select your preferred filters\n"
            "2. Browse through available stores by category\n"
            "3. Select a store to view available surplus products\n"
            "4. Reserve your food package\n"
            "5. Pick up during designated time"),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/home')
          Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/browse');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/delivery');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/favorite');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _navigateToStoreProducts(Store store) {
    Navigator.pushNamed(
      context,
      '/delivery_product',
      arguments: store,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.delivery_dining),
            SizedBox(width: 8),
            Text("Delivery"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters
                      .map((filter) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: selectedFilters.contains(filter),
                              selectedColor: Colors.green[100],
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  selectedFilters.add(filter);
                                } else {
                                  selectedFilters.remove(filter);
                                }
                              }),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: InkWell(
                onTap: _showHowToUsePopup,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.eco,
                            color: Colors.green, size: 30),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Save Food, Save Planet",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Learn more about food rescue and how you can make a difference",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Categories",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return CategoryCard(
                    category: categories[index],
                    onStoreSelected: _navigateToStoreProducts);
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Recently Sold Out",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => const SoldOutCard(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Browse"),
          BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining), label: "Delivery"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorite"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        selectedItemColor: const Color.fromARGB(255, 56, 142, 60),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final Category category;
  final Function(Store) onStoreSelected;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onStoreSelected,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.category.icon,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.category.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      "${widget.category.stores.length} Stores",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.category.stores.length,
              itemBuilder: (context, index) {
                return StoreListItem(
                  store: widget.category.stores[index],
                  onTap: () =>
                      widget.onStoreSelected(widget.category.stores[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}

class StoreListItem extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreListItem({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(store.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 12, color: Colors.green[700]),
                            const SizedBox(width: 4),
                            Text(
                              "${store.products.length} Available",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              image: DecorationImage(
                image: AssetImage(product.image),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.favorite_border, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "RM${product.discountPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "RM${product.originalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "-${((1 - product.discountPrice / product.originalPrice) * 100).toStringAsFixed(0)}%",
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (product.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      const Text(
                        "Limited • Add to cart",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoldOutCard extends StatelessWidget {
  const SoldOutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: const AssetImage('assets/images/bread.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bakery House",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Fresh Bread Surplus",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "RM7.99",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Sold out at 15:30",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "SOLD OUT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Category {
  final String name;
  final IconData icon;
  final List<Store> stores;

  Category({
    required this.name,
    required this.icon,
    required this.stores,
  });
}

class Store {
  final String name;
  final String image;
  final String description;
  final String address;
  final double rating;
  final List<Product> products;

  Store({
    required this.name,
    required this.products,
    this.image = 'assets/images/bread.png',
    this.description = '',
    this.address = '',
    this.rating = 4.0,
  });
}

class Product {
  final String name;
  final double originalPrice;
  final double discountPrice;
  final bool isNew;
  final String image;
  final String description;

  Product({
    required this.name,
    required this.originalPrice,
    required this.discountPrice,
    this.isNew = false,
    this.image = 'assets/images/bread.png',
    this.description = '',
  });
}
