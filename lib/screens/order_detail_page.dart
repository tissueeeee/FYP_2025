import 'package:flutter/material.dart';
import 'package:fyp_project/models/order_model.dart';
import 'package:fyp_project/providers/order_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
//import 'package:flutter_vibrate/flutter_vibrate.dart';

class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  double _sliderValue = 0.0;
  String _friendCollectionCode = '';
  bool _isGeneratingCode = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pickupDate = widget.order.date;
    final isToday = now.year == pickupDate.year &&
        now.month == pickupDate.month &&
        now.day == pickupDate.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color.fromARGB(255, 56, 142, 60),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Header
            Container(
              color: Colors.green[50],
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.order.productName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Text(
                                'RM ${widget.order.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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

            // Order Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        "Pickup Date",
                        isToday
                            ? 'Today'
                            : DateFormat('MMMM dd, yyyy').format(pickupDate),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Pickup Time", widget.order.pickUpTime),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          "Quantity", widget.order.quantity.toString()),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          "Order ID", widget.order.id.substring(0, 8)),
                    ],
                  ),
                ),
              ),
            ),

            // Pickup Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                color: Colors.amber[50],
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
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Pickup Instructions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "1. Show your order details to the store staff",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "2. Confirm pickup by sliding the bar below",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "3. Don't forget to bring your own bag!",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Slide to Confirm
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green[100]!, width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Confirm Pickup",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color.fromARGB(255, 56, 142, 60),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Slide the button to confirm your pickup!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background track
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[50]!,
                                    Colors.green[100]!,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            // Dynamic gradient overlay based on slider value
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 70,
                              width: (MediaQuery.of(context).size.width - 160) *
                                  _sliderValue,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[400]!,
                                    Colors.green[700]!,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                            // Background text or hint
                            Center(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _sliderValue < 0.9 ? 1.0 : 0.0,
                                child: Text(
                                  "Slide to Confirm",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _sliderValue >= 0.9 ? 1.0 : 0.0,
                                child: Text(
                                  "Release to Confirm",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            // Slider (hidden track, only for interaction)
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 0, // Hide the default track
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                                thumbColor:
                                    Colors.transparent, // Hide default thumb
                                overlayColor: Colors.transparent,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 0),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 0),
                              ),
                              child: Slider(
                                value: _sliderValue,
                                onChanged: (value) {
                                  setState(() {
                                    _sliderValue = value;
                                  });
                                },
                                onChangeEnd: (value) async {
                                  if (value >= 0.9) {
                                    final orderProvider =
                                        Provider.of<OrderProvider>(context,
                                            listen: false);
                                    try {
                                      await orderProvider
                                          .completeOrder(widget.order.id);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Order from ${widget.order.storeName} picked up successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.of(context).pop(true);
                                    } catch (e) {
                                      setState(() {
                                        _sliderValue = 0;
                                      });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to confirm pickup: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      _sliderValue = 0;
                                    });
                                  }
                                },
                              ),
                            ),
                            // Custom thumb with arrow
                            Positioned(
                              left: _sliderValue *
                                  (MediaQuery.of(context).size.width - 160),
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    _sliderValue = (_sliderValue +
                                            details.delta.dx /
                                                (MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    160))
                                        .clamp(0.0, 1.0);
                                  });
                                },
                                onHorizontalDragEnd: (details) async {
                                  if (_sliderValue >= 0.9) {
                                    final orderProvider =
                                        Provider.of<OrderProvider>(context,
                                            listen: false);
                                    try {
                                      await orderProvider
                                          .completeOrder(widget.order.id);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Order from ${widget.order.storeName} picked up successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.of(context).pop(true);
                                    } catch (e) {
                                      setState(() {
                                        _sliderValue = 0;
                                      });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to confirm pickup: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      _sliderValue = 0;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green[400]!,
                                        Colors.green[700]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Friend Collection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
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
                        "Can't make it? Ask a friend to help",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_friendCollectionCode.isEmpty)
                        ElevatedButton.icon(
                          onPressed: _isGeneratingCode
                              ? null
                              : () {
                                  setState(() {
                                    _isGeneratingCode = true;
                                  });
                                  // Generate a random 6-digit code
                                  final rng = Random();
                                  final code =
                                      List.generate(6, (_) => rng.nextInt(10))
                                          .join();
                                  Future.delayed(
                                      const Duration(milliseconds: 800), () {
                                    setState(() {
                                      _friendCollectionCode = code;
                                      _isGeneratingCode = false;
                                    });
                                  });
                                },
                          icon: Icon(_isGeneratingCode
                              ? Icons.hourglass_empty
                              : Icons.people),
                          label: Text(_isGeneratingCode
                              ? "Generating code..."
                              : "Generate Friend Collection Code"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _friendCollectionCode,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      // Copy to clipboard logic would go here
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copied!'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Share.share(
                                    'Hey, can you pick up my order at ${widget.order.storeName}? Use this code: $_friendCollectionCode');
                              },
                              icon: const Icon(Icons.share),
                              label: const Text("Share with Friend"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "This code will expire in 24 hours. Your friend must show this code to the store staff to collect your order.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
