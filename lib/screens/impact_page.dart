import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp_project/providers/user_provider.dart';
import 'package:fyp_project/providers/order_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:percent_indicator/circular_percent_indicator.dart';

class ImpactPage extends StatefulWidget {
  const ImpactPage({Key? key}) : super(key: key);

  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkLoginStatusAndLoadData();
  }

  Future<void> _checkLoginStatusAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    _isLoggedIn = currentUser != null;

    if (_isLoggedIn) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);

        await userProvider.loadUserData();
        await orderProvider.loadOrders();
        await _syncImpactMetrics(userProvider, orderProvider);

        _animationController
            .forward(); // Start the animation after data is loaded
      } catch (e) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
        });
        print('Error in ImpactPage: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncImpactMetrics(
      UserProvider userProvider, OrderProvider orderProvider) async {
    double totalCO2Saved = 0;
    double totalMoneySaved = 0;
    Map<String, double> foodTypesSaved = {};

    for (var order in orderProvider.completedOrders) {
      totalCO2Saved += order.co2Saved; // Uses pre-calculated value
      totalMoneySaved += order.moneySaved.abs(); // Uses pre-calculated value
      String foodType = 'Other';
      if (order.productName.toLowerCase().contains('bread')) {
        foodType = 'Bakery';
      } else if (order.productName.toLowerCase().contains('sandwich')) {
        foodType = 'Prepared';
      }
      foodTypesSaved[foodType] = (foodTypesSaved[foodType] ?? 0) + 1;
    }

    if (userProvider.user != null) {
      if (userProvider.user!.co2Saved != totalCO2Saved ||
          userProvider.user!.moneySaved != totalMoneySaved ||
          userProvider.user!.totalOrders !=
              orderProvider.completedOrders.length) {
        await userProvider.updateUserImpactMetrics(
            totalCO2Saved,
            totalMoneySaved,
            orderProvider.completedOrders.length,
            foodTypesSaved);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Environmental Impact'),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
        body:
            const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Environmental Impact'),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view your impact',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    const Text('Go to Login', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = userProvider.user;

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Environmental Impact'),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkLoginStatusAndLoadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Environmental Impact'),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'User data not found. Please log out and log in again.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Provider.of<UserProvider>(context, listen: false)
                      .logout()
                      .then((_) {
                    Navigator.pushReplacementNamed(context, '/login');
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log Out', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate additional CO2 equivalencies
    final double treesEquivalent =
        user.co2Saved / 21; // 1 tree absorbs ~21 kg CO2 per year
    final double carKmEquivalent =
        user.co2Saved / 0.25; // 0.25 kg CO2 per km driven
    final double phoneChargesEquivalent =
        user.co2Saved / 0.0005; // ~0.5 g CO2 per phone charge

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Environmental Impact'),
        backgroundColor: Colors.green,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.greenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _checkLoginStatusAndLoadData,
        color: Colors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Circular Progress Indicator
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.greenAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Green Impact',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'See how you’re helping the planet!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularPercentIndicator(
                        radius: 50.0,
                        lineWidth: 8.0,
                        percent: (user.co2Saved / 100)
                            .clamp(0, 1), // Scale CO2 saved to a percentage
                        center: Icon(
                          Icons.eco,
                          color: Colors.white.withOpacity(0.8),
                          size: 30,
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),

              // CO2 Avoided Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade100, Colors.green.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.eco,
                                    color: Colors.green.shade700, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'CO₂ Avoided',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${user.co2Saved.toStringAsFixed(2)} kg',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Equivalent to:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildEquivalencyRow(
                              icon: Icons.directions_car,
                              text:
                                  '${(user.co2Saved * 2.5).round()} minutes of driving',
                            ),
                            _buildEquivalencyRow(
                              icon: Icons.local_florist,
                              text:
                                  '${treesEquivalent.toStringAsFixed(1)} trees planted',
                            ),
                            _buildEquivalencyRow(
                              icon: Icons.directions,
                              text:
                                  '${carKmEquivalent.toStringAsFixed(1)} km not driven',
                            ),
                            _buildEquivalencyRow(
                              icon: Icons.phone_iphone,
                              text:
                                  '${phoneChargesEquivalent.round()} phone charges',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Money Saved Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade100, Colors.amber.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.savings,
                                    color: Colors.amber.shade700, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Money Saved',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'RM ${user.moneySaved.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saved from discounted products',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Order Statistics Section
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Text(
                  'Order Statistics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),

              // Total Orders
              _buildStatCard(
                icon: Icons.shopping_bag,
                title: 'Total Orders',
                value: '${user.totalOrders}',
                color: Colors.green.shade600,
              ),

              // Completed Orders
              _buildStatCard(
                icon: Icons.check_circle,
                title: 'Completed Orders',
                value: '${orderProvider.completedOrders.length}',
                color: Colors.green.shade600,
              ),

              // Active Orders
              _buildStatCard(
                icon: Icons.pending_actions,
                title: 'Active Orders',
                value: '${orderProvider.activeOrders.length}',
                color: Colors.green.shade600,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquivalencyRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(icon, color: color, size: 28),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            trailing: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
