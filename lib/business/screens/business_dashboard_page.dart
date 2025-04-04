import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp_project/business/screens/listing_management_page.dart';
import 'package:fyp_project/business/screens/store_management_page.dart';
import 'package:fyp_project/business/providers/business_provider.dart';
import 'package:fyp_project/business/models/business_model.dart';
import 'package:fyp_project/business/providers/listing_provider.dart';
import 'package:fyp_project/business/models/listing_model.dart';
import 'package:fyp_project/screens/profile_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class BusinessDashboardPage extends StatefulWidget {
  @override
  _BusinessDashboardPageState createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  int mealsSaved = 0;
  double co2Saved = 0.0;
  double earnedAmount = 0.0;
  double averageRating = 0.0;
  int totalReviews = 0;
  bool isLoading = true;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    final businessId = FirebaseAuth.instance.currentUser?.uid;
    if (businessId != null) {
      Provider.of<BusinessProvider>(context, listen: false)
          .fetchBusiness(businessId);
      Provider.of<ListingProvider>(context, listen: false)
          .fetchListings(businessId);
      _subscribeToOrders(businessId);
    }
  }

  void _subscribeToOrders(String businessId) {
    setState(() {
      isLoading = true;
    });

    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      print(
          'Stream triggered with ${snapshot.docs.length} completed orders'); // Debug log
      _loadImpactStatistics(businessId);
    }, onError: (e) {
      print('Error subscribing to orders: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading impact statistics: $e')),
      );
    });
  }

  Future<void> _loadImpactStatistics(String businessId) async {
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: 'completed')
          .get();

      print(
          'Loading impact statistics for businessId: $businessId'); // Debug log
      int totalMeals = 5;
      double totalCo2 = 3.0;
      double totalEarned = 60;
      double totalRating = 22.5;
      int reviewCount = 5;

      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data();
        print('Processing order: ${doc.id}, data: $orderData'); // Debug log
        totalMeals += (orderData['quantity'] as int? ?? 0);
        totalCo2 += (orderData['co2Saved'] as num? ?? 0.0).toDouble();
        totalEarned += (orderData['amount'] as num? ?? 0.0).toDouble();
        final rating = (orderData['rating'] as num?)?.toDouble();
        if (rating != null && (orderData['isRated'] as bool? ?? false)) {
          totalRating += rating;
          reviewCount++;
        }
      }

      setState(() {
        mealsSaved = totalMeals;
        co2Saved = totalCo2;
        earnedAmount = totalEarned;
        totalReviews = reviewCount;
        averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading impact statistics: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading impact statistics: $e')),
      );
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = Provider.of<BusinessProvider>(context);
    final listingProvider = Provider.of<ListingProvider>(context);
    final business = businessProvider.business;
    final storeDetails = business?.storeDetails;
    final listings = listingProvider.listings;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Business Dashboard',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              );
            },
            tooltip: 'Switch to Customer Profile',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Handle notifications
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              color: Color(0xFF4CAF50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeDetails?.storeName ?? 'test3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfilePage()),
                      );
                    },
                    child: Text(
                      'Switch to Customer Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.list, 'Listings', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.settings, 'Store Settings', () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StoreManagementPage()),
              );
            }),
            _buildDrawerItem(Icons.show_chart, 'Performance', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.account_balance_wallet, 'Financials', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.star, 'Milestones', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.settings, 'Settings', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.support, 'Support', () {
              Navigator.pop(context); // Close the drawer
              // Add navigation logic if needed
            }),
            _buildDrawerItem(Icons.logout, 'Sign Out', () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              // Navigate to login page or handle logout logic
            }),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final businessId = FirebaseAuth.instance.currentUser?.uid;
                if (businessId != null) {
                  await _loadImpactStatistics(businessId);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.green[100],
                                child: Icon(
                                  Icons.store,
                                  size: 24,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storeDetails?.storeName ?? 'Store Name',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${averageRating.toStringAsFixed(1)} ($totalReviews reviews)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: Colors.green[700]),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => StoreManagementPage()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Impact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImpactCard(
                              'Meals Saved',
                              mealsSaved.toString(),
                              Icons.fastfood,
                              Colors.orange[400]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildImpactCard(
                              'CO₂ Saved',
                              '${co2Saved.toStringAsFixed(1)} kg',
                              Icons.eco,
                              Colors.green[400]!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildImpactCard(
                              'Earned',
                              'RM${earnedAmount.toStringAsFixed(2)}',
                              Icons.paid,
                              Colors.blue[400]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Current Listings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      listings.isEmpty
                          ? const Center(child: Text('No listings available'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: listings.length,
                              itemBuilder: (context, index) =>
                                  _buildListingCard(listings[index], context),
                            ),
                      const SizedBox(height: 20),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Add New Listing',
                              Icons.add_circle_outline,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ListingManagementPage()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Edit Store',
                              Icons.edit,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => StoreManagementPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sales Performance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPerformanceIndicator(
                                      'This Week', 68, Colors.green),
                                  _buildPerformanceIndicator(
                                      'Last Week', 54, Colors.blue),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    // Navigate to detailed performance page
                                  },
                                  child: Text(
                                    'View Detailed Performance',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tips & Guides',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTipItem(
                                'Optimize Your Listings',
                                'Learn how to create effective listings that sell quickly.',
                                Icons.lightbulb_outline,
                              ),
                              const Divider(),
                              _buildTipItem(
                                'Reduce Food Waste',
                                'Best practices for minimizing food waste in your business.',
                                Icons.eco,
                              ),
                              const Divider(),
                              _buildTipItem(
                                'Connect With Customers',
                                'Tips for building loyalty and getting repeat business.',
                                Icons.people_outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ListingManagementPage()),
          );
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add New Listing',
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700], size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  Widget _buildImpactCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(Listing listing, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fastfood,
                      size: 40,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surprise Bag',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'RM ${listing.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${listing.quantity} available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatPickupInfo(listing),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Edit listing
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ListingManagementPage()),
                        );
                      },
                      child: Text(
                        'Edit',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // View listing details
                      },
                      child: Text(
                        'Details',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPickupInfo(Listing listing) {
    if (listing.pickupStart != null && listing.pickupEnd != null) {
      return 'Pickup: ${listing.pickupStart} - ${listing.pickupEnd}';
    } else {
      return 'Pickup: Not specified';
    }
  }

  Widget _buildActionButton(
      String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.green[700],
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green[200]!),
        ),
        elevation: 2,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
      String title, int percentage, MaterialColor color) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 50.0,
          lineWidth: 8.0,
          percent: percentage / 100,
          center: Text(
            '$percentage%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          progressColor: color,
          backgroundColor: Colors.grey[200]!,
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animationDuration: 1500,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String title, String description, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(icon, color: Colors.green[700], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () {
        // Navigate to tip details
      },
    );
  }
}
