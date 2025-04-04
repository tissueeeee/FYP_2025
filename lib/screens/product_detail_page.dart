import 'package:flutter/material.dart';
import 'package:fyp_project/screens/cart_page.dart';
//import 'package:share/share.dart';
import 'package:fyp_project/models/favorites.dart';
import 'package:fyp_project/screens/favorite_page.dart' as favoritePage;
import 'package:fyp_project/screens/payment_page.dart';
import 'package:fyp_project/models/cart_model.dart';
import 'package:fyp_project/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String productName;
  final String storeName;
  final String price;
  final String pickUpTime;
  final double rating;
  final double distance;
  final String imagePath;
  final String description;
  final int availableQuantity;
  final String productId;
  final String? originalPrice; // Add this to accept original price

  ProductDetailPage({
    Key? key,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.pickUpTime,
    required this.rating,
    required this.distance,
    required this.imagePath,
    this.description = "Save this food from going to waste!.",
    this.availableQuantity = 3,
    String? productId,
    this.originalPrice, // Add to constructor
  })  : productId = productId ??
            '${productName}_${storeName}_${DateTime.now().millisecondsSinceEpoch}',
        super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool isFavorite = false;
  int quantity = 1;
  bool _isProcessing = false; // Add this to prevent multiple button presses

  @override
  void initState() {
    super.initState();
    isFavorite = favoritePage.favoriteItems
        .any((item) => item.productName == widget.productName);

    // Ensure the cart is loaded
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  void _toggleFavorite() {
    setState(() {
      if (isFavorite) {
        favoritePage.favoriteItems
            .removeWhere((item) => item.productName == widget.productName);
      } else {
        favoritePage.favoriteItems.add(FavoriteItem(
          productName: widget.productName,
          imagePath: widget.imagePath,
          price: widget.price,
          pickUpTime: widget.pickUpTime,
          storeName: widget.storeName,
          rating: widget.rating,
          distance: widget.distance,
        ));
      }
      isFavorite = !isFavorite;
    });
  }

  // void _shareProduct() {
  //   Share.share(
  //       'Check out this discounted food at ${widget.storeName}: ${widget.productName} for only RM${widget.price}. Help reduce food waste!');
  // }

  void _showComments() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("User Reviews"),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildReviewItem("Sarah L.", 5.0,
                  "Great value! The food was still fresh and delicious."),
              _buildReviewItem(
                  "Mike T.", 4.5, "Amazing deal. Store staff was friendly."),
              _buildReviewItem(
                  "Lisa K.", 4.0, "Good variety of items in my surprise bag."),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, double rating, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(rating.toString()),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment),
          const Divider(),
        ],
      ),
    );
  }

  void _navigateToGoogleMaps() {
    // Show a snackbar for now, but you can implement actual map navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigating to store location...")),
    );
  }

  // Fixed method to add to cart and navigate to payment page
  Future<void> _navigateToPaymentPage() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      CartItem cartItem = CartItem(
        productId: widget.productId,
        productName: widget.productName,
        storeName: widget.storeName,
        price: widget.price,
        imagePath: widget.imagePath,
        quantity: quantity,
      );

      cartProvider.addItem(cartItem);
      await cartProvider.saveCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added ${widget.productName} to cart"),
          duration: Duration(seconds: 1),
        ),
      );

      // Calculate prices
      double discountedPrice = double.tryParse(widget.price) ?? 0.0;
      double originalPrice = widget.originalPrice != null
          ? double.parse(widget.originalPrice!)
          : discountedPrice / 0.35; // Assuming 65% discount
      double totalPrice = discountedPrice * quantity;

      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            productName: widget.productName,
            storeName: widget.storeName,
            price: widget.price, // Pass the original discounted price
            originalPrice: originalPrice.toStringAsFixed(2),
            pickUpTime: widget.pickUpTime,
            imagePath: widget.imagePath,
            quantity: quantity,
            totalPrice: totalPrice,
            businessId:
                'business_id_placeholder', // Replace with actual businessId if available
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _addToCartOnly() {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Use the unique product ID
      CartItem cartItem = CartItem(
        productId: widget.productId,
        productName: widget.productName,
        storeName: widget.storeName,
        price: widget.price,
        imagePath: widget.imagePath,
        quantity: quantity,
      );

      // Add item to cart
      cartProvider.addItem(cartItem);

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added ${widget.productName} to cart"),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => CartPage()));
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQuantitySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Quantity",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Available: ${widget.availableQuantity}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: quantity > 1
                          ? () {
                              setState(() {
                                quantity--;
                              });
                              this.setState(() {});
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Colors.green[100],
                      ),
                      child: const Icon(Icons.remove, color: Colors.green),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$quantity",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: quantity < widget.availableQuantity
                          ? () {
                              setState(() {
                                quantity++;
                              });
                              this.setState(() {});
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Colors.green,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double parsedPrice = double.tryParse(widget.price) ?? 0.0;
    // Compute original price if not provided
    final double originalPrice = widget.originalPrice != null
        ? double.parse(widget.originalPrice!)
        : parsedPrice / 0.35; // Assuming 65% discount
    final int discountPercent =
        ((1 - (parsedPrice / originalPrice)) * 100).round();
    final double totalPrice = parsedPrice * quantity;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // _shareProduct(); // Uncomment when share functionality is implemented
            },
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    widget.imagePath,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${widget.availableQuantity} left",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.storeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            Text(
                              "RM${parsedPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 56, 142, 60),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "RM${originalPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$discountPercent%",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text("${widget.rating} / 5.0",
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text("${widget.distance.toStringAsFixed(1)} km",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Pick up time: ${widget.pickUpTime} Today",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quantity: $quantity",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "Tap to change",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _showQuantitySelector,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text("Select"),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "RM${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  GestureDetector(
                    onTap: _navigateToGoogleMaps,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "123 Main Street, City",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Tap to get directions",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "What you could get",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: const Text("Baked Goods"),
                        backgroundColor: Colors.green[50],
                      ),
                      Chip(
                        label: const Text("Surprise Bag"),
                        backgroundColor: Colors.green[50],
                      ),
                      Chip(
                        label: const Text("Eco-friendly"),
                        backgroundColor: Colors.green[50],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "User Reviews",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _showComments,
                        child: const Text(
                          "See All",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showComments,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text("${widget.rating} / 5.0",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Top Highlights",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Great value for money"),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Friendly staff"),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Good quality"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[100]!),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.eco, color: Colors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "By reserving this food, you're helping reduce food waste and greenhouse gas emissions. Thank you for making a difference!",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "The store will provide packaging for your food, but we encourage you to bring your own bag to reduce plastic waste.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
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
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _addToCartOnly,
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isProcessing ? null : _navigateToPaymentPage,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Reserve Now",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
