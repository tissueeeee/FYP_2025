import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_project/business/models/business_model.dart';
import 'package:fyp_project/screens/manage_account_page.dart';
//import 'package:share/share.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../business/screens/business_dashboard_page.dart';
import '../business/providers/business_provider.dart';
import '../screens/order_history_page.dart';
import '../services/user_profile_service.dart';
import '../screens/impact_page.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart' as order_model;

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileService _userProfileService = UserProfileService();
  User? _currentUser;
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;
  double _totalCO2Saved = 0;
  double _totalMoneySaved = 0;
  bool _hasBusiness = false; // New state variable for hasBusiness

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _userProfileService.getCurrentUser();
      if (user != null) {
        // Fetch user details including hasBusiness from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Check if still mounted after async operation
        if (!mounted) return;

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _hasBusiness = userData['hasBusiness'] ?? false;
          _userDetails = userData;
        }

        // Fetch business data if it exists
        final businessDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(user.uid)
            .get();

        // Check if still mounted after async operation
        if (!mounted) return;

        final businessProvider =
            Provider.of<BusinessProvider>(context, listen: false);
        if (businessDoc.exists) {
          businessProvider.setBusiness(Business.fromJson(businessDoc.data()!));
        }
      }

      await Provider.of<OrderProvider>(context, listen: false).loadOrders();

      // Check if still mounted after async operation
      if (!mounted) return;

      _calculateImpactStatistics();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return; // Add this check
      setState(() => _isLoading = false);
    }
  }

  void _calculateImpactStatistics() {
    if (!mounted) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final allOrders = [
      ...orderProvider.completedOrders,
      ...orderProvider.activeOrders
    ];

    double co2Total = 0;
    double moneyTotal = 0;

    for (var order in allOrders) {
      co2Total += order.co2Saved;
      moneyTotal += order.moneySaved;
    }

    if (!mounted) return;
    setState(() {
      _totalCO2Saved = co2Total;
      _totalMoneySaved = moneyTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 56, 142, 60),
                                Color.fromARGB(255, 76, 175, 80),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: _currentUser?.photoURL != null
                                    ? CachedNetworkImageProvider(
                                        _currentUser!.photoURL!)
                                    : null,
                                child: _currentUser?.photoURL == null
                                    ? Icon(Icons.person,
                                        size: 50, color: Colors.grey[400])
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _currentUser?.displayName ?? 'Guest User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_currentUser?.email != null)
                                Text(
                                  _currentUser!.email!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ManageAccountPage()),
                        ).then((_) => _loadUserData());
                      },
                    ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildActiveOrderSection(),
                    _buildImpactStatisticsSection(),
                    _buildOrderHistorySection(),
                    _buildInviteFriendsSection(),
                    if (_hasBusiness) ...[
                      // Changed condition to _hasBusiness
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BusinessDashboardPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text('Switch to Business Account'),
                        ),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Version 1.0.0",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildActiveOrderSection() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final activeOrders = orderProvider.activeOrders;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.green, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activeOrders.isEmpty
                              ? 'No active orders'
                              : '${activeOrders.length} order(s) waiting for pickup',
                          style: TextStyle(
                            color: activeOrders.isEmpty
                                ? Colors.grey
                                : Colors.green,
                            fontWeight: activeOrders.isEmpty
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderHistoryPage()),
                      ).then((_) =>
                          _loadUserData()); // Refresh data after returning
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),

              // Show next upcoming order if there are any active orders
              if (activeOrders.isNotEmpty) ...[
                const Divider(height: 24),
                _buildNextActiveOrder(activeOrders.first),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextActiveOrder(order_model.Order order) {
    final now = DateTime.now();
    final pickupDate = order.date;
    final isToday = now.year == pickupDate.year &&
        now.month == pickupDate.month &&
        now.day == pickupDate.day;

    final timeRemaining = order.date.difference(now);
    final hoursRemaining = timeRemaining.inHours;
    final minutesRemaining = timeRemaining.inMinutes % 60;

    String timeRemainingText;
    Color timeColor;

    if (timeRemaining.isNegative) {
      timeRemainingText = 'Pickup time has passed';
      timeColor = Colors.red;
    } else if (hoursRemaining > 0) {
      timeRemainingText = '$hoursRemaining h $minutesRemaining min left';
      timeColor = Colors.green;
    } else {
      timeRemainingText = '$minutesRemaining min left';
      timeColor = minutesRemaining < 30 ? Colors.orange : Colors.green;
    }

    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0), // Add padding for better spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              order.imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // Order Details (Flexible to prevent overflow)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Reduced font size for better fit
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Handle long store names
                ),
                Text(
                  order.productName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12, // Reduced font size for better fit
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Handle long product names
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: timeColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      // Wrap time text to prevent overflow
                      child: Text(
                        timeRemainingText,
                        style: TextStyle(
                          color: timeColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12), // Add spacing before price
          // Price and Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  'RM ${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isToday
                    ? 'Today, ${order.pickUpTime}'
                    : '${order.date.day}/${order.date.month}, ${order.pickUpTime}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildImpactCard(
            icon: Icons.eco,
            title: 'CO₂ Avoided',
            value: '${_totalCO2Saved.toStringAsFixed(1)} kg',
            description:
                'Equivalent to ${(_totalCO2Saved / 0.12).toStringAsFixed(0)} min of driving',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImpactPage()),
              ).then((_) => _loadUserData()); // Refresh data after returning
            },
          ),
          const SizedBox(width: 16),
          _buildImpactCard(
            icon: Icons.savings,
            title: 'Money Saved',
            value: 'RM ${_totalMoneySaved.toStringAsFixed(2)}',
            description:
                '${(_totalMoneySaved > 0 ? (_totalMoneySaved / _calculateAverageOrderValue() * 100).toStringAsFixed(0) : "0")}% off normal price',
            color: Colors.amber[700]!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImpactPage()),
              ).then((_) => _loadUserData()); // Refresh data after returning
            },
          ),
        ],
      ),
    );
  }

  // Calculate average order value for percentage saved
  double _calculateAverageOrderValue() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final allOrders = [
      ...orderProvider.completedOrders,
      ...orderProvider.activeOrders
    ];

    if (allOrders.isEmpty) return 100; // Default to avoid division by zero

    double totalValue = 0;
    for (var order in allOrders) {
      totalValue += order.totalAmount;
    }

    return totalValue / allOrders.length;
  }

  Widget _buildImpactCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHistorySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: const Icon(Icons.history, color: Colors.green),
          title: const Text('Order History'),
          subtitle: Text(
            'View all your past orders',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryPage()),
            ).then((_) => _loadUserData()); // Refresh data after returning
          },
        ),
      ),
    );
  }

  Widget _buildInviteFriendsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Invite Friends',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Spread the word and help reduce food waste! Invite your friends and earn rewards.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Share.share(
                        //   'Check out Grab and Go - an app that helps reduce food waste and save money! Download now: [App Link]',
                        // );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Get RM5 credit for each friend who signs up!',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 4, // Assuming Profile is the 5th tab
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/browse');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/delivery');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/favorite');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Browse"),
        BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining), label: "Delivery"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
      selectedItemColor: const Color.fromARGB(255, 56, 142, 60),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    );
  }
}
