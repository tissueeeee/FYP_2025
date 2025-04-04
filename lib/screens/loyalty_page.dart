import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({Key? key}) : super(key: key);

  @override
  _LoyaltyPageState createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  String _userName = '';
  String _userEmail = '';
  String _membershipLevel = 'Bronze';
  int _currentPoints = 0;
  int _pointsToNextLevel = 100;
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _availableRewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRewards();
    _loadRecentActivity();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            _userName = userData['name'] ?? 'Food Saver';
            _userEmail = currentUser.email ?? '';
            _currentPoints = userData['loyaltyPoints'] ?? 0;
            _membershipLevel = _calculateMembershipLevel(_currentPoints);
            _pointsToNextLevel = _calculatePointsToNextLevel(_currentPoints);
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _calculateMembershipLevel(int points) {
    if (points >= 500) {
      return 'Gold';
    } else if (points >= 200) {
      return 'Silver';
    } else {
      return 'Bronze';
    }
  }

  int _calculatePointsToNextLevel(int points) {
    if (points < 200) {
      return 200 - points; // Points needed to reach Silver
    } else if (points < 500) {
      return 500 - points; // Points needed to reach Gold
    } else {
      return 0; // Already at Gold level
    }
  }

  Color _getMembershipColor() {
    switch (_membershipLevel) {
      case 'Gold':
        return const Color(0xFFFFD700); // Vibrant Gold
      case 'Silver':
        return const Color(0xFFC0C0C0); // Bright Silver
      default:
        return const Color(0xFFCD7F32); // Warm Bronze
    }
  }

  Color _getMembershipBackgroundColor() {
    switch (_membershipLevel) {
      case 'Gold':
        return const Color(0xFFFFF9E6); // Light Gold background
      case 'Silver':
        return const Color(0xFFF5F6FA); // Light Silver background
      default:
        return const Color(0xFFF9EDE5); // Light Bronze background
    }
  }

  Color _getMembershipTextColor() {
    switch (_membershipLevel) {
      case 'Gold':
        return const Color(0xFF8B6914); // Darker Gold for contrast
      case 'Silver':
        return const Color(0xFF4A4E69); // Darker gray for contrast
      default:
        return const Color(0xFF8B4513); // Darker Bronze for contrast
    }
  }

  Future<void> _loadRewards() async {
    try {
      QuerySnapshot rewardsSnapshot = await _firestore
          .collection('rewards')
          .where('minimumLevel', isLessThanOrEqualTo: _membershipLevel)
          .orderBy('minimumLevel')
          .orderBy('pointsCost')
          .get();

      setState(() {
        _availableRewards = rewardsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'title': doc['title'],
                  'description': doc['description'],
                  'pointsCost': doc['pointsCost'],
                  'minimumLevel': doc['minimumLevel'],
                })
            .toList();
      });
    } catch (e) {
      print('Error loading rewards: $e');
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        QuerySnapshot activitySnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('pointsActivity')
            .orderBy('timestamp', descending: true)
            .limit(3)
            .get();

        setState(() {
          _recentActivity = activitySnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'points': doc['points'],
                    'description': doc['description'],
                    'timestamp': (doc['timestamp'] as Timestamp).toDate(),
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error loading recent activity: $e');
    }
  }

  Future<void> _redeemReward(String rewardId, int pointsCost) async {
    if (_currentPoints < pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough points to redeem this reward'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('redemptions')
            .add({
          'rewardId': rewardId,
          'pointsCost': pointsCost,
          'redeemed': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('users').doc(currentUser.uid).update({
          'loyaltyPoints': FieldValue.increment(-pointsCost),
        });

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('pointsActivity')
            .add({
          'points': -pointsCost,
          'description': 'Reward redemption',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _loadUserData();
        await _loadRecentActivity();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward redeemed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error redeeming reward: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to redeem reward. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMembershipCard(),
                    const SizedBox(height: 24),
                    _buildPointsProgress(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                    const SizedBox(height: 24),
                    _buildAvailableRewards(),
                    const SizedBox(height: 24),
                    _buildSubscriptionPlans(),
                    const SizedBox(height: 16),
                    _buildHowItWorks(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMembershipCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: _getMembershipBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getMembershipColor(),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: _getMembershipColor(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_membershipLevel Member',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getMembershipTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Points: $_currentPoints',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_pointsToNextLevel > 0)
                  Text(
                    '${_pointsToNextLevel} pts to next level',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsProgress() {
    double progress = 0.0;
    String nextLevel = 'Silver';
    int levelThreshold = 200;

    if (_currentPoints < 200) {
      progress = _currentPoints / 200;
      nextLevel = 'Silver';
      levelThreshold = 200;
    } else if (_currentPoints < 500) {
      progress = (_currentPoints - 200) / 300;
      nextLevel = 'Gold';
      levelThreshold = 500;
    } else {
      progress = 1.0;
      nextLevel = 'Gold';
      levelThreshold = 500;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Level Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 20.0,
              percent: progress,
              backgroundColor: Colors.grey.shade200,
              progressColor: _getMembershipColor(),
              barRadius: const Radius.circular(10),
              animation: true,
              animationDuration: 1000,
              center: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progress > 0.5 ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _membershipLevel,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getMembershipTextColor(),
                  ),
                ),
                if (_membershipLevel != 'Gold')
                  Text(
                    nextLevel,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getMembershipTextColor(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_membershipLevel != 'Gold')
              Text(
                'Earn $_pointsToNextLevel more points to reach $nextLevel status',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _recentActivity.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No recent activity',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentActivity.length,
                    itemBuilder: (context, index) {
                      final activity = _recentActivity[index];
                      final bool isPositive = activity['points'] > 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPositive
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Icon(
                                  isPositive
                                      ? Icons.add_circle_outline
                                      : Icons.remove_circle_outline,
                                  color: isPositive ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['description'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(activity['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${activity['points']} pts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => ActivityHistoryPage(),
                //   ),
                // );
              },
              child: const Text(
                'View Full History',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAvailableRewards() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Rewards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _availableRewards.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No rewards available',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableRewards.length,
                    itemBuilder: (context, index) {
                      final reward = _availableRewards[index];
                      final bool canRedeem =
                          _currentPoints >= reward['pointsCost'];

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          title: Text(
                            reward['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                reward['description'],
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMembershipColorByLevel(
                                              reward['minimumLevel'])
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${reward['minimumLevel']} Members',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getMembershipTextColorByLevel(
                                            reward['minimumLevel']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${reward['pointsCost']} pts',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: canRedeem
                                    ? () => _redeemReward(
                                        reward['id'], reward['pointsCost'])
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                child: const Text('Redeem'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Navigate to all rewards page
              },
              child: const Text(
                'View All Rewards',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMembershipColorByLevel(String level) {
    switch (level) {
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Color _getMembershipTextColorByLevel(String level) {
    switch (level) {
      case 'Gold':
        return const Color(0xFF8B6914);
      case 'Silver':
        return const Color(0xFF4A4E69);
      default:
        return const Color(0xFF8B4513);
    }
  }

  Widget _buildHowItWorks() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How It Works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildHowItWorksItem(
              icon: Icons.shopping_bag,
              title: 'Save Food',
              description: 'Earn 10 points for each order you place',
            ),
            _buildHowItWorksItem(
              icon: Icons.star,
              title: 'Rate & Review',
              description: 'Earn 5 points when you rate and review a store',
            ),
            _buildHowItWorksItem(
              icon: Icons.person_add,
              title: 'Invite Friends',
              description: 'Earn 20 points for each friend who joins',
            ),
            _buildHowItWorksItem(
              icon: Icons.workspace_premium,
              title: 'Level Up',
              description:
                  'Unlock exclusive rewards as you reach higher levels',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    final List<Map<String, dynamic>> plans = [
      {
        'name': 'Monthly',
        'price': 9.99,
        'description': 'Access to premium features for 30 days',
        'isRecommended': false,
      },
      {
        'name': 'Yearly',
        'price': 99.99,
        'description': 'Save 16% with annual billing (best value)',
        'isRecommended': true,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: plan['isRecommended']
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: plan['isRecommended'] ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      plan['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          plan['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'RM ${plan['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _showSubscriptionConfirmationDialog(plan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                      child: const Text(
                        'Subscribe',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Learn More About Subscriptions',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionConfirmationDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${plan['name']}'),
            const SizedBox(height: 8),
            Text('Price: RM ${plan['price'].toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Description: ${plan['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSubscriptionPayment(plan);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _handleSubscriptionPayment(Map<String, dynamic> plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subscribed to ${plan['name']} plan successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
