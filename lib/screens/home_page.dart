import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fyp_project/screens/location_selection.dart';
import 'package:fyp_project/screens/favorite_page.dart' as favoritePage;
import 'package:fyp_project/models/favorites.dart';
import 'package:fyp_project/screens/product_detail_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fyp_project/business/services/listing_service.dart';
import 'package:fyp_project/business/models/listing_model.dart';
import 'package:fyp_project/business/services/business_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentAddress = 'UCSI University';
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  final PageController _pageController = PageController();
  final ListingService _listingService = ListingService();
  final BusinessService _businessService = BusinessService();
  List<Listing> _newestListings = [];
  Map<String, String> _businessNames = {}; // Cache business names
  Map<String, String?> _businessProfileImages = {};

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
    _fetchNewestListings();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentCarouselIndex < 3) {
        _currentCarouselIndex++;
      } else {
        _currentCarouselIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _fetchNewestListings() async {
    try {
      final listings = await _listingService.getAllListings();
      setState(() {
        _newestListings = listings
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (_newestListings.length > 3) {
          _newestListings = _newestListings.sublist(0, 3);
        }
      });

      // Fetch store names for each listing
      for (var listing in _newestListings) {
        if (!_businessNames.containsKey(listing.businessId)) {
          final business =
              await _businessService.getBusiness(listing.businessId);
          _businessNames[listing.businessId] =
              business?.storeDetails?.storeName ?? "Unknown Store";
          _businessProfileImages[listing.businessId] =
              business?.storeDetails?.profileImageUrl;
        }
      }
    } catch (e) {
      print('Error fetching listings: $e');
    }
  }

  double _calculateOriginalPrice(double discountedPrice) {
    return double.parse((discountedPrice / 0.35).toStringAsFixed(2));
  }

  int _calculateDiscountPercent(double discountedPrice, double originalPrice) {
    return ((1 - (discountedPrice / originalPrice)) * 100).round();
  }

  void _selectLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location services are disabled. Please enable location services.'),
          duration: Duration(seconds: 3),
        ),
      );
      final selectedAddress = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LocationSelectionPage()),
      );
      if (selectedAddress != null) {
        setState(() {
          _currentAddress = selectedAddress;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission denied. You can still select manually.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
              'Location permissions are permanently denied. Please enable them in settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        ),
      );
    }

    final selectedAddress = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSelectionPage()),
    );
    if (selectedAddress != null) {
      setState(() {
        _currentAddress = selectedAddress;
      });
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.pushReplacementNamed(context, '/home');
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: _selectLocation,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
        elevation: 0,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 56, 142, 60),
              Color.fromARGB(255, 215, 249, 217),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickCategoryButton(
                      icon: Icons.restaurant_menu,
                      label: "All Dishes",
                      onTap: () {},
                    ),
                    _buildQuickCategoryButton(
                      icon: Icons.local_offer,
                      label: "Special Offer",
                      onTap: () {},
                    ),
                    _buildQuickCategoryButton(
                      icon: Icons.trending_up,
                      label: "Best Seller",
                      onTap: () {},
                    ),
                    _buildQuickCategoryButton(
                      icon: Icons.volunteer_activism,
                      label: "Donate",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageCarousel(),
                            const SizedBox(height: 0),
                            _buildNewestFoodSection(context),
                            _buildCategorySection(
                                context, "Save Before It's Too Late", [
                              _buildProductTile(
                                  context,
                                  "Surprise Meal Bag",
                                  "assets/images/homestore1.png",
                                  "3.49",
                                  "09:30 PM - 10:00 PM",
                                  "Chapathi Recipes",
                                  4.3,
                                  0.1),
                              _buildProductTile(
                                  context,
                                  "Surprise Tea Bag",
                                  "assets/images/homestore2.png",
                                  "3.99",
                                  "09:00 PM - 10:00 PM",
                                  "Tealive Taman Connaught",
                                  4.7,
                                  0.2),
                              _buildProductTile(
                                  context,
                                  "Surprise Meal Bag",
                                  "assets/images/homestore3.png",
                                  "5.99",
                                  "09:00 PM - 09:30 PM",
                                  "Restoran Makanan Laut Lau Heong",
                                  4.8,
                                  0.6),
                            ]),
                            _buildCategorySection(
                                context, "New Surprise Bags", [
                              _buildProductTile(
                                  context,
                                  "Budget Surprise Meal Bag",
                                  "assets/images/homestore4.png",
                                  "1.99",
                                  "09:00 PM - 10:00 PM",
                                  "Big Tree Lin Kee Steam Fish Head",
                                  4.1,
                                  0.5),
                              _buildProductTile(
                                  context,
                                  "Surprise Tea Bag",
                                  "assets/images/homestore5.png",
                                  "2.99",
                                  "09:30 PM - 10:00 PM",
                                  "The Alley Cheras",
                                  4.4,
                                  1.0),
                              _buildProductTile(
                                  context,
                                  "Surprise Meal Bag",
                                  "assets/images/homestore6.png",
                                  "3.49",
                                  "08:30 PM - 09:00 PM",
                                  "Ah Gong House",
                                  4.6,
                                  0.6),
                            ]),
                            _buildCategorySection(context, "Supermarkets", [
                              _buildSupermarketTile(
                                  context,
                                  "99 Speedmart",
                                  "assets/images/homestore7.png",
                                  "assets/images/homestore7_logo.png",
                                  4.1,
                                  1.0),
                              _buildSupermarketTile(
                                  context,
                                  "NSK Trade City Cheras",
                                  "assets/images/homestore8.png",
                                  "assets/images/homestore8_logo.png",
                                  4.4,
                                  1.3),
                              _buildSupermarketTile(
                                  context,
                                  "AEON Big Cheras",
                                  "assets/images/homestore9.png",
                                  "assets/images/homestore9_logo.png",
                                  4.3,
                                  1.4),
                            ]),
                            _buildCategorySection(context, "Local Bakeries", [
                              _buildProductTile(
                                  context,
                                  "Premium Pastry Bag",
                                  "assets/images/homestore10.png",
                                  "4.99",
                                  "07:00 PM - 08:00 PM",
                                  "The Baker’s Cottage",
                                  4.9,
                                  2.1),
                              _buildProductTile(
                                  context,
                                  "Fresh Bread Surprise",
                                  "assets/images/homestore11.png",
                                  "2.49",
                                  "06:30 PM - 07:00 PM",
                                  "Kings Confectionery",
                                  4.3,
                                  1.4),
                              _buildProductTile(
                                  context,
                                  "Sweet Treats Bag",
                                  "assets/images/homestore12.png",
                                  "3.79",
                                  "06:00 PM - 06:30 PM",
                                  "Tong Kee Bakery",
                                  4.5,
                                  1.9),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewestFoodSection(BuildContext context) {
    if (_newestListings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "Newest Food - Loading...",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 56, 142, 60),
          ),
        ),
      );
    }

    return _buildCategorySection(
      context,
      "Newest Food",
      _newestListings.map((listing) {
        final storeName = _businessNames[listing.businessId] ?? "Unknown Store";
        final profileImageUrl = _businessProfileImages[listing.businessId];
        final discountedPrice = listing.price;
        final originalPrice = listing.originalPrice ?? discountedPrice;
        final discountPercent = originalPrice > discountedPrice
            ? ((1 - (discountedPrice / originalPrice)) * 100).round()
            : 0;

        return _buildProductTile(
          context,
          listing.title ?? "Surprise Bag",
          profileImageUrl ?? "assets/images/bread.png",
          discountedPrice.toStringAsFixed(2),
          "${listing.pickupStart} - ${listing.pickupEnd}",
          storeName,
          4.5, // Hardcoded rating
          1.2, // Hardcoded distance
          originalPrice: originalPrice,
          discountPercent: discountPercent,
          profileImageUrl: profileImageUrl,
        );
      }).toList(),
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    String productName,
    String imagePath,
    String price,
    String pickUpTime,
    String storeName,
    double rating,
    double distance, {
    double? originalPrice,
    int? discountPercent,
    String? profileImageUrl,
  }) {
    bool isFavorite = favoritePage.favoriteItems
        .any((item) => item.productName == productName);

    final displayOriginalPrice =
        originalPrice ?? _calculateOriginalPrice(double.parse(price));
    final displayDiscountPercent = discountPercent ??
        _calculateDiscountPercent(double.parse(price), displayOriginalPrice);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productName: productName,
              storeName: storeName,
              price: price,
              pickUpTime: pickUpTime,
              rating: rating,
              distance: distance,
              imagePath: imagePath ?? "assets/images/bread.png",
              originalPrice: displayOriginalPrice.toStringAsFixed(2),
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Container(
                    height: 140,
                    width: 180,
                    child: profileImageUrl != null
                        ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: const Color.fromARGB(255, 56, 142, 60),
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (BuildContext context, Object error,
                                StackTrace? stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Store image unavailable',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            imagePath ?? "assets/images/bread.png",
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFavorite) {
                            favoritePage.favoriteItems.removeWhere(
                                (item) => item.productName == productName);
                          } else {
                            favoritePage.favoriteItems.add(FavoriteItem(
                              productName: productName,
                              imagePath: imagePath ?? "assets/images/bread.png",
                              price: price,
                              pickUpTime: pickUpTime,
                              storeName: storeName,
                              rating: rating,
                              distance: distance,
                            ));
                          }
                        });
                      },
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        minWidth: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 56, 142, 60),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 215, 249, 217),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                "RM$price",
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 56, 142, 60),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (displayOriginalPrice > double.parse(price)) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "RM${displayOriginalPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "$displayDiscountPercent%",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pickUpTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${distance.toString()} km",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final List<String> carouselImages = [
      'assets/images/home_1.png',
      'assets/images/home_2.png',
      'assets/images/home_3.png',
      'assets/images/home_4.png',
    ];

    return Column(
      children: [
        Container(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 215, 249, 217),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    carouselImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselImages.length,
            (index) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentCarouselIndex == index
                    ? const Color.fromARGB(255, 56, 142, 60)
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCategoryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 56, 142, 60),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context, String title, List<Widget> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 56, 142, 60),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "See all",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: products,
          ),
        ),
      ],
    );
  }

  Widget _buildSupermarketTile(BuildContext context, String storeName,
      String imagePath, String logoPath, double rating, double distance) {
    bool isFavorite =
        favoritePage.favoriteItems.any((item) => item.productName == storeName);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productName: storeName,
              storeName: storeName,
              price: (rating * 10).toStringAsFixed(2),
              pickUpTime: "N/A",
              rating: rating,
              distance: distance,
              imagePath: imagePath,
              // businessId: '',
            ),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Image.asset(
                    imagePath,
                    height: 140,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFavorite) {
                            favoritePage.favoriteItems.removeWhere(
                                (item) => item.productName == storeName);
                          } else {
                            favoritePage.favoriteItems.add(FavoriteItem(
                              productName: storeName,
                              imagePath: imagePath,
                              price: (rating * 10).toStringAsFixed(2),
                              pickUpTime: "N/A",
                              storeName: storeName,
                              rating: rating,
                              distance: distance,
                            ));
                          }
                        });
                      },
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        minWidth: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 56, 142, 60),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      "RM${(rating * 10).toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(logoPath),
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${distance.toString()} km",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
