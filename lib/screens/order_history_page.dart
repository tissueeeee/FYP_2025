import 'package:flutter/material.dart';
import 'package:fyp_project/screens/order_detail_page.dart';
import 'package:fyp_project/screens/rating_page.dart';
import 'package:fyp_project/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fyp_project/models/order_model.dart';
import 'package:fyp_project/providers/order_provider.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();

    // Listen for changes to the order provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .addListener(_onOrdersChanged);
    });
  }

  void _onOrdersChanged() {
    if (mounted) {
      setState(() {}); // Refresh UI when orders change
    }
  }

  @override
  void dispose() {
    Provider.of<OrderProvider>(context, listen: false)
        .removeListener(_onOrdersChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Completed Orders'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOrdersList(),
                _buildCompletedOrdersList(),
              ],
            ),
    );
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await Provider.of<OrderProvider>(context, listen: false).loadOrders();
    setState(() => _isLoading = false);
  }

  Widget _buildActiveOrdersList() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final activeOrders = orderProvider.activeOrders;
    print('Active orders: ${activeOrders.length}'); // Debug
    if (activeOrders.isEmpty) {
      return _buildEmptyState(
          icon: Icons.shopping_bag_outlined,
          message: 'No active orders',
          subMessage: 'Your active orders will appear here');
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          return _buildActiveOrderCard(context, activeOrders[index]);
        },
      ),
    );
  }

  Widget _buildCompletedOrdersList() {
    final orderProvider = Provider.of<OrderProvider>(context);
    final completedOrders = orderProvider.completedOrders;
    print('Completed orders: ${completedOrders.length}'); // Debug
    if (completedOrders.isEmpty) {
      return _buildEmptyState(
          icon: Icons.check_circle_outline,
          message: 'No completed orders',
          subMessage: 'Complete an order to see it here');
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: completedOrders.length,
        itemBuilder: (context, index) {
          return _buildCompletedOrderCard(context, completedOrders[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required String subMessage}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, Order order) {
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

    return Dismissible(
      key: Key(order.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.green,
        child: const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 36,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Collection"),
              content:
                  const Text("Have you collected this order from the store?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(true);
                    final orderProvider =
                        Provider.of<OrderProvider>(context, listen: false);
                    try {
                      await orderProvider.completeOrder(order.id);
                      await _loadOrders(); // Refresh the UI
                      if (!mounted) return; // Check if widget is still mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Order from ${order.storeName} marked as collected'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return; // Check if widget is still mounted
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to confirm collection: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Yes, I've collected it",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        try {
          await orderProvider.completeOrder(order.id);
          await _loadOrders(); // Refresh the UI
          if (!mounted) return; // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Order from ${order.storeName} marked as collected'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () {
                  // Undo logic can be implemented here if needed
                },
              ),
            ),
          );
        } catch (e) {
          if (!mounted) return; // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to confirm collection: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      order.imagePath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.productName,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: timeColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                timeRemainingText,
                                style: TextStyle(
                                  color: timeColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'x${order.quantity}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isToday
                                ? 'Today, ${order.pickUpTime}'
                                : '${DateFormat('MMM d').format(order.date)}, ${order.pickUpTime}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to details page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(order: order),
                        ),
                      ).then((value) {
                        if (value == true) {
                          // Order was marked as picked up, refresh the list
                          _loadOrders();
                        }
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedOrderCard(BuildContext context, Order order) {
    final dateFormatter = DateFormat('MMM d, yyyy');

    return InkWell(
      onTap: () {
        // Navigate to rating page for completed orders
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RatingPage(order: order),
          ),
        ).then((value) {
          // Refresh the list after returning from RatingPage
          _loadOrders();
        });
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.productName,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(order.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'RM ${order.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: order.isRated
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  order.isRated
                                      ? Icons.check_circle
                                      : Icons.rate_review,
                                  size: 12,
                                  color: order.isRated
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  order.isRated ? 'Completed' : 'Needs Rating',
                                  style: TextStyle(
                                    color: order.isRated
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          order.isRated
                              ? Icon(Icons.star, size: 14, color: Colors.amber)
                              : Icon(Icons.star_border,
                                  size: 14, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (order.co2Saved > 0 || order.moneySaved > 0) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImpactIndicator(
                      icon: Icons.eco,
                      color: Colors.green,
                      value: '${order.co2Saved.toStringAsFixed(1)} kg',
                      label: 'CO₂ Saved',
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildImpactIndicator(
                      icon: Icons.savings,
                      color: Colors.amber[700]!,
                      value: 'RM ${order.moneySaved.toStringAsFixed(2)}',
                      label: 'Money Saved',
                    ),
                  ],
                ),
              ],
              // Rating invitation at bottom
              if (!order.isRated) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(
                      'Tap to rate your experience',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactIndicator({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
