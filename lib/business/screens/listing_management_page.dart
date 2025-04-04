import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../providers/listing_provider.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

class ListingManagementPage extends StatefulWidget {
  @override
  _ListingManagementPageState createState() => _ListingManagementPageState();
}

class _ListingManagementPageState extends State<ListingManagementPage> {
  final ListingService _listingService = ListingService();
  String? _businessId;
  List<Listing> _businessListings = [];
  bool _isLoading = true;
  bool _isCreatingNew = false;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _pickupStartController;
  late TextEditingController _pickupEndController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'Meal'; // Default category
  bool _isHalal = true; // Default to halal

  // List of categories
  final List<String> _categories = [
    'Meal',
    'Drink',
    'Bakery',
    'Groceries',
    'Snack',
    'Other'
  ];

  // Selected listing for editing
  Listing? _selectedListing;

  // Discount percentage
  int _discountPercentage = 50; // Default 50% discount

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _originalPriceController = TextEditingController();
    _discountedPriceController = TextEditingController();
    _quantityController = TextEditingController();
    _pickupStartController = TextEditingController();
    _pickupEndController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _businessId = FirebaseAuth.instance.currentUser?.uid;

    _loadBusinessListings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    _pickupStartController.dispose();
    _pickupEndController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessListings() async {
    if (_businessId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final listings =
          await _listingService.getListingsByBusinessId(_businessId!);

      setState(() {
        _businessListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading listings: ${e.toString()}')),
      );
    }
  }

  Future<void> _selectPickupStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _pickupStartController.text = _formatTimeOfDay(picked);
      });
    }
  }

  Future<void> _selectPickupEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1),
    );
    if (picked != null) {
      setState(() {
        _pickupEndController.text = _formatTimeOfDay(picked);
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat.jm().format(dateTime); // Format: 7:30 PM
  }

  void _calculateDiscountedPrice() {
    if (_originalPriceController.text.isNotEmpty) {
      try {
        double originalPrice = double.parse(_originalPriceController.text);
        double discountedPrice =
            originalPrice * (1 - _discountPercentage / 100);
        _discountedPriceController.text = discountedPrice.toStringAsFixed(2);
      } catch (e) {
        _discountedPriceController.text = '';
      }
    } else {
      _discountedPriceController.text = '';
    }
  }

  void _resetForm() {
    _titleController.clear();
    _originalPriceController.clear();
    _discountedPriceController.clear();
    _quantityController.clear();
    _pickupStartController.clear();
    _pickupEndController.clear();
    _locationController.text =
        ''; // This might be pre-filled from business profile
    _descriptionController.clear();
    _selectedCategory = 'Meal';
    _isHalal = true;
    _discountPercentage = 50;
    _selectedListing = null;
  }

  void _prepareFormForEdit(Listing listing) {
    _selectedListing = listing;
    _titleController.text = listing.title ?? '';

    // Handle pricing - assuming we need to reverse-calculate original price
    _discountedPriceController.text = listing.price.toString();
    if (listing.originalPrice != null) {
      _originalPriceController.text = listing.originalPrice.toString();
      // Calculate discount percentage
      _discountPercentage =
          ((1 - listing.price / listing.originalPrice!) * 100).round();
    } else {
      // If no original price stored, assume current discount
      double originalPrice = listing.price / (1 - _discountPercentage / 100);
      _originalPriceController.text = originalPrice.toStringAsFixed(2);
    }

    _quantityController.text = listing.quantity.toString();
    _pickupStartController.text = listing.pickupStart ?? '';
    _pickupEndController.text = listing.pickupEnd ?? '';
    _locationController.text = listing.location;
    _descriptionController.text = listing.description;

    // Set category and halal status if available
    _selectedCategory = listing.category ?? 'Meal';
    _isHalal = listing.isHalal ?? true;
  }

  bool _validateForm() {
    // Check required fields - make title optional
    if (_discountedPriceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _pickupStartController.text.isEmpty ||
        _pickupEndController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please fill all required fields (Price, Quantity, Pickup Times)')),
      );
      return false;
    }

    // Validate if numbers are valid
    try {
      double.parse(_discountedPriceController.text);
      int.parse(_quantityController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid numbers for price and quantity')),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveListing() async {
    if (_businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business ID not found')),
      );
      return;
    }

    // Validate form fields
    if (!_validateForm()) {
      return;
    }

    try {
      // Parse values
      final double discountedPrice =
          double.parse(_discountedPriceController.text);
      final double originalPrice = _originalPriceController.text.isNotEmpty
          ? double.parse(_originalPriceController.text)
          : discountedPrice * (100 / (100 - _discountPercentage));
      final int quantity = int.parse(_quantityController.text);

      // Assuming business location is already stored somewhere
      // We'll use a placeholder location here
      String location =
          "Business Location"; // Use business's registered location

      if (_selectedListing == null) {
        // Creating new listing
        final newListing = Listing(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          businessId: _businessId!,
          title: _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Surprise Bag',
          price: discountedPrice,
          originalPrice: originalPrice,
          quantity: quantity,
          pickupStart: _pickupStartController.text,
          pickupEnd: _pickupEndController.text,
          location: location,
          description: _descriptionController.text,
          category: _selectedCategory,
          isHalal: _isHalal,
          createdAt: DateTime.now(),
        );

        await _listingService.createListing(newListing);

        setState(() {
          _businessListings.add(newListing);
          _isCreatingNew = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created successfully')),
        );
      } else {
        // Updating existing listing
        final updatedListing = Listing(
          id: _selectedListing!.id,
          businessId: _businessId!,
          title: _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Surprise Bag',
          price: discountedPrice,
          originalPrice: originalPrice,
          quantity: quantity,
          pickupStart: _pickupStartController.text,
          pickupEnd: _pickupEndController.text,
          location: location,
          description: _descriptionController.text,
          category: _selectedCategory,
          isHalal: _isHalal,
          createdAt: _selectedListing!.createdAt,
        );

        await _listingService.updateListing(updatedListing);

        setState(() {
          final index = _businessListings
              .indexWhere((listing) => listing.id == updatedListing.id);
          if (index != -1) {
            _businessListings[index] = updatedListing;
          }
          _isCreatingNew = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated successfully')),
        );
      }

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving listing: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteListing(String listingId) async {
    try {
      await _listingService.deleteListing(listingId);
      setState(() {
        _businessListings.removeWhere((listing) => listing.id == listingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting listing: ${e.toString()}')),
      );
    }
  }

  Widget _buildListingItem(Listing listing) {
    // Calculate savings percentage if original price exists
    String savingsText = '';
    if (listing.originalPrice != null && listing.originalPrice! > 0) {
      int savingsPercent =
          ((1 - listing.price / listing.originalPrice!) * 100).round();
      savingsText = 'Save $savingsPercent%';
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title ?? 'Surprise Bag',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: listing.isHalal == true
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    listing.isHalal == true ? 'Halal' : 'Non-Halal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: listing.isHalal == true
                          ? Colors.green[800]
                          : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    listing.category ?? 'Meal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 16, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  '${listing.pickupStart ?? ''} - ${listing.pickupEnd ?? ''}',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    listing.location,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${listing.quantity} remaining',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (listing.description.isNotEmpty)
                      Text(
                        listing.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (listing.originalPrice != null)
                          Text(
                            '\RM${listing.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          '\RM${listing.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (savingsText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          savingsText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              setState(() {
                _isCreatingNew = true;
                _prepareFormForEdit(listing);
              });
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Listing'),
                  content: const Text(
                      'Are you sure you want to delete this listing?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteListing(listing.id);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_businessListings.isEmpty) {
      return const Center(
        child: Text('No listings found. Create your first listing!'),
      );
    }

    return ListView.builder(
      itemCount: _businessListings.length,
      itemBuilder: (context, index) {
        return _buildListingItem(_businessListings[index]);
      },
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field - Optional
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Food Bag Title (Optional)',
              hintText: 'Leave blank for "Surprise Bag"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Food Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Halal switch
          SwitchListTile(
            title: const Text('Is Halal',
                style: TextStyle(fontWeight: FontWeight.bold)),
            value: _isHalal,
            onChanged: (value) {
              setState(() {
                _isHalal = value;
              });
            },
            activeColor: Colors.purple,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          const SizedBox(height: 16),

          // Original Price field
          TextField(
            controller: _originalPriceController,
            decoration: InputDecoration(
              labelText: 'Original Price (\RM)*',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixText: '\RM ',
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateDiscountedPrice(),
          ),
          const SizedBox(height: 16),

          // Discount slider
          Row(
            children: [
              const Text('Discount: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _discountPercentage.toDouble(),
                  min: 30,
                  max: 80,
                  divisions: 10,
                  label: '$_discountPercentage%',
                  activeColor: Colors.purple,
                  onChanged: (value) {
                    setState(() {
                      _discountPercentage = value.round();
                      _calculateDiscountedPrice();
                    });
                  },
                ),
              ),
              Text('$_discountPercentage%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Discounted Price field
          TextField(
            controller: _discountedPriceController,
            decoration: InputDecoration(
              labelText: 'Discounted Price (\RM)*',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixText: '\RM ',
              filled: true,
              fillColor: Colors.white,
              // Add a visual indicator that this field is read-only
              suffixIcon:
                  const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            ),
            keyboardType: TextInputType.number,
            readOnly: true, // Set to true to make it read-only
            enabled: false, // Visually indicate it's disabled
          ),
          const SizedBox(height: 16),

          // Quantity field
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity Available*',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Pickup Time fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pickupStartController,
                  decoration: InputDecoration(
                    labelText: 'Pickup Start Time*',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.access_time),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  readOnly: true,
                  onTap: _selectPickupStartTime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _pickupEndController,
                  decoration: InputDecoration(
                    labelText: 'Pickup End Time*',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.access_time),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  readOnly: true,
                  onTap: _selectPickupEndTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Describe what might be included in this food bag...',
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isCreatingNew = false;
                    _resetForm();
                  });
                },
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.purple)),
              ),
              ElevatedButton(
                onPressed: _saveListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _selectedListing == null
                      ? 'Create Listing'
                      : 'Update Listing',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '* Required fields',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingNew
            ? (_selectedListing == null ? 'Create New Listing' : 'Edit Listing')
            : 'Manage Listings'),
        actions: [
          if (!_isCreatingNew)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBusinessListings,
              tooltip: 'Refresh Listings',
            ),
        ],
      ),
      body: _isCreatingNew ? _buildFormView() : _buildListingsView(),
      floatingActionButton: _isCreatingNew
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isCreatingNew = true;
                  _resetForm();
                });
              },
              child: const Icon(Icons.add),
              tooltip: 'Create New Listing',
            ),
    );
  }
}
