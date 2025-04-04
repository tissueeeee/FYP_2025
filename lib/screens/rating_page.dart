import 'package:flutter/material.dart';
import 'package:fyp_project/models/order_model.dart' as order_model;
import 'package:fyp_project/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingPage extends StatefulWidget {
  final order_model.Order order;

  const RatingPage({Key? key, required this.order}) : super(key: key);

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _rating = 0;
  String _comment = '';
  bool _isSubmitting = false;
  bool _hasRated = false;
  final _formKey = GlobalKey<FormState>();

  // Food quality indicators
  bool _freshness = false;
  bool _value = false;
  bool _portion = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRating();
  }

  Future<void> _checkExistingRating() async {
    setState(() => _hasRated = widget.order.isRated);

    if (_hasRated) {
      // Fetch existing rating data
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('ratings')
            .where('orderId', isEqualTo: widget.order.id)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          setState(() {
            _rating = data['rating'];
            _comment = data['comment'] ?? '';
            _freshness = data['indicators']?['freshness'] ?? false;
            _value = data['indicators']?['value'] ?? false;
            _portion = data['indicators']?['portion'] ?? false;
          });
        }
      } catch (e) {
        print('Error fetching rating: $e');
      }
    }
  }

  Future<void> _submitRating() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to rate')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create indicators map
      final indicators = {
        'freshness': _freshness,
        'value': _value,
        'portion': _portion,
      };

      // Submit to Firestore
      await FirebaseFirestore.instance.collection('ratings').add({
        'userId': userId,
        'orderId': widget.order.id,
        //'storeId': widget.order.storeId ?? '', // Handle potentially missing storeId
        'rating': _rating,
        'comment': _comment,
        'indicators': indicators,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update order to be marked as rated
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.loadOrders();
      final updatedOrder = widget.order.copyWith(isRated: true);

      // Update the Firestore document directly since there's no markOrderAsRated method
      await FirebaseFirestore.instance
          .collection('detailed_orders')
          .doc(userId)
          .collection('orders')
          .doc(widget.order.id)
          .update({'isRated': true});

      setState(() {
        _hasRated = true;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details & Rating'),
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order details card
              _buildOrderDetailsCard(),

              const SizedBox(height: 24),

              // Impact summary
              _buildImpactSummary(),

              const SizedBox(height: 24),

              // Rating section
              _buildRatingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    widget.order.imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.order.productName,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          'RM ${widget.order.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Collection date',
                '${widget.order.date.day}/${widget.order.date.month}/${widget.order.date.year}'),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.access_time, 'Collection time', widget.order.pickUpTime),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.shopping_bag, 'Quantity', 'x${widget.order.quantity}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactSummary() {
    return Card(
      elevation: 3,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Impact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImpactIndicator(
                  icon: Icons.eco,
                  color: Colors.green,
                  value: '${widget.order.co2Saved.toStringAsFixed(1)} kg',
                  label: 'CO₂ Saved',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),
                _buildImpactIndicator(
                  icon: Icons.savings,
                  color: Colors.amber[700]!,
                  value: 'RM ${widget.order.moneySaved.toStringAsFixed(2)}',
                  label: 'Money Saved',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for helping reduce food waste! By collecting this order, you prevented perfectly good food from being thrown away.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ],
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
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    if (_hasRated && !_isSubmitting) {
      return _buildSubmittedRatingView();
    }

    return Form(
      key: _formKey,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How was your order?',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What was good about it?',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildIndicatorChip('Great value', _freshness, (val) {
                    setState(() => _freshness = val);
                  }),
                  _buildIndicatorChip('Friendly staff', _value, (val) {
                    setState(() => _value = val);
                  }),
                  _buildIndicatorChip('Good quality', _portion, (val) {
                    setState(() => _portion = val);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Add a comment (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                enabled: !_isSubmitting,
                initialValue: _comment,
                onChanged: (value) {
                  setState(() {
                    _comment = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting || _rating == 0 ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildIndicatorChip(
      String label, bool selected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: _isSubmitting ? null : onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green,
      labelStyle: TextStyle(
        color: selected ? Colors.green[800] : Colors.grey[800],
      ),
    );
  }

  Widget _buildSubmittedRatingView() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Rating',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
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
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Submitted',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _rating.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_freshness || _value || _portion) ...[
              const Text(
                'What was good:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (_freshness)
                    Chip(
                      label: const Text('Freshness'),
                      backgroundColor: Colors.green[100],
                      labelStyle: TextStyle(color: Colors.green[800]),
                    ),
                  if (_value)
                    Chip(
                      label: const Text('Good value'),
                      backgroundColor: Colors.green[100],
                      labelStyle: TextStyle(color: Colors.green[800]),
                    ),
                  if (_portion)
                    Chip(
                      label: const Text('Good portion'),
                      backgroundColor: Colors.green[100],
                      labelStyle: TextStyle(color: Colors.green[800]),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_comment.isNotEmpty) ...[
              const Text(
                'Your comment:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _comment,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Thank you for your feedback! It helps us and our partners improve our service.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
