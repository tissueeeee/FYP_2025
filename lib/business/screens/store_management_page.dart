import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/business_provider.dart';
import '../models/business_model.dart';
import '../services/business_service.dart';
import 'package:flutter/foundation.dart';

class StoreManagementPage extends StatefulWidget {
  @override
  _StoreManagementPageState createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  late TextEditingController _storeNameController;
  late TextEditingController _addressController;
  late TextEditingController _locationController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  final BusinessService _businessService = BusinessService();
  String? _businessId;
  File? _businessLicenseImage;
  File? _healthSanitationLicenseImage;
  File? _storeProfileImage;
  latlong.LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _locationPermissionGranted = false;

  final ImagePicker _picker = ImagePicker();

  // Form validation key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _businessId = FirebaseAuth.instance.currentUser?.uid;
    final business =
        Provider.of<BusinessProvider>(context, listen: false).business;

    _storeNameController =
        TextEditingController(text: business?.storeDetails?.storeName ?? '');
    _addressController =
        TextEditingController(text: business?.storeDetails?.address ?? '');
    _locationController =
        TextEditingController(text: business?.storeDetails?.location ?? '');
    _contactController =
        TextEditingController(text: business?.storeDetails?.contact ?? '');
    _descriptionController =
        TextEditingController(text: business?.storeDetails?.description ?? '');
    _websiteController =
        TextEditingController(text: business?.storeDetails?.website ?? '');

    // Request location permission
    _checkLocationPermission();

    // If location is already set in the business data, initialize _selectedLocation
    if (business?.storeDetails?.location != null &&
        business!.storeDetails!.location!.isNotEmpty) {
      final coords = business.storeDetails!.location!.split(',');
      if (coords.length == 2) {
        _selectedLocation = latlong.LatLng(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationPermissionGranted = false;
        });
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationPermissionGranted = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionGranted = false;
        });
        return;
      }

      setState(() {
        _locationPermissionGranted = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
      setState(() {
        _locationPermissionGranted = false;
      });
    }
  }

  Future<void> _pickImage(ImageType type) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case ImageType.businessLicense:
            _businessLicenseImage = File(pickedFile.path);
            break;
          case ImageType.healthLicense:
            _healthSanitationLicenseImage = File(pickedFile.path);
            break;
          case ImageType.profileImage:
            _storeProfileImage = File(pickedFile.path);
            break;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services on your device.'),
          ),
        );
        return;
      }

      // Check permissions
      if (!_locationPermissionGranted) {
        await _checkLocationPermission();
        if (!_locationPermissionGranted) {
          if (await Geolocator.checkPermission() ==
              LocationPermission.deniedForever) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permissions are permanently denied. Please enable them in app settings.'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permission is required to use this feature.'),
              ),
            );
          }
          return;
        }
      }

      // Get current position with a timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add a 10-second timeout
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Failed to get location within 10 seconds.');
      });

      if (position == null) {
        throw Exception('Failed to retrieve location: Position is null.');
      }

      setState(() {
        _selectedLocation =
            latlong.LatLng(position.latitude, position.longitude);
      });

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        _addressController.text = address.trim();
        _locationController.text = '${position.latitude},${position.longitude}';
      } else {
        _addressController.text = 'Address not found';
      }
    } catch (e) {
      String errorMessage;
      if (e is PermissionDeniedException) {
        errorMessage = 'Location permission denied.';
      } else if (e is LocationServiceDisabledException) {
        errorMessage = 'Location services are disabled.';
      } else if (e is TimeoutException) {
        errorMessage = 'Failed to get location: Request timed out.';
      } else {
        errorMessage = 'Error getting location: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateStore() async {
    if (_businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business ID not found')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final businessProvider =
          Provider.of<BusinessProvider>(context, listen: false);

      // Upload license files to storage if they exist
      String? businessLicenseUrl;
      String? healthLicenseUrl;
      String? profileImageUrl;

      if (kDebugMode) {
        print('Uploading store profile image: ${_storeProfileImage != null}');
      }

      if (_storeProfileImage != null) {
        try {
          profileImageUrl = await _businessService.uploadLicenseImage(
              _businessId!, _storeProfileImage!, 'profile_image');

          if (kDebugMode) {
            print('Profile image uploaded successfully: $profileImageUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error uploading profile image: $e');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading profile image: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (_businessLicenseImage != null) {
        businessLicenseUrl = await _businessService.uploadLicenseImage(
            _businessId!, _businessLicenseImage!, 'business_license');
      }

      if (_healthSanitationLicenseImage != null) {
        healthLicenseUrl = await _businessService.uploadLicenseImage(
            _businessId!, _healthSanitationLicenseImage!, 'health_license');
      }

      // Create store details with current values and new image URL if available
      final storeDetails = StoreDetails(
        storeName: _storeNameController.text,
        address: _addressController.text,
        location: _locationController.text,
        contact: _contactController.text,
        description: _descriptionController.text,
        website: _websiteController.text,
        businessLicenseUrl: businessLicenseUrl ??
            businessProvider.business?.storeDetails?.businessLicenseUrl,
        healthLicenseUrl: healthLicenseUrl ??
            businessProvider.business?.storeDetails?.healthLicenseUrl,
        profileImageUrl: profileImageUrl ??
            businessProvider.business?.storeDetails?.profileImageUrl,
      );

      if (kDebugMode) {
        print('Final profile image URL: ${storeDetails.profileImageUrl}');
      }

      final updatedBusiness = Business(
        id: _businessId!,
        email: businessProvider.business?.email ?? '',
        name: businessProvider.business?.name ?? '',
        storeDetails: storeDetails,
      );

      // Register the updated business
      await _businessService.registerBusiness(updatedBusiness);

      // Update the provider
      businessProvider.setBusiness(updatedBusiness);

      // Fetch the updated business to confirm changes are saved
      await businessProvider.fetchBusiness(_businessId!);

      // Update the user's hasBusiness field to true
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_businessId)
          .update({'hasBusiness': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to ProfilePage
      Navigator.pop(context, true);
    } catch (e) {
      if (kDebugMode) {
        print('Error in store update: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating store: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Manage Store'),
        backgroundColor: const Color(0xFF00AA5B),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00AA5B)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 24),
                    _buildStoreDetailsSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildLicensesSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00AA5B),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(ImageType.profileImage),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _storeProfileImage != null
                          ? FileImage(_storeProfileImage!)
                          : Provider.of<BusinessProvider>(context)
                                      .business
                                      ?.storeDetails
                                      ?.profileImageUrl !=
                                  null
                              ? NetworkImage(
                                  Provider.of<BusinessProvider>(context)
                                      .business!
                                      .storeDetails!
                                      .profileImageUrl!)
                              : null,
                      child: _storeProfileImage == null &&
                              Provider.of<BusinessProvider>(context)
                                      .business
                                      ?.storeDetails
                                      ?.profileImageUrl ==
                                  null
                          ? const Icon(Icons.store,
                              size: 60, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00AA5B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _storeNameController,
              decoration: InputDecoration(
                labelText: 'Store Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.store, color: Color(0xFF00AA5B)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter store name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Store Description',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon:
                    const Icon(Icons.description, color: Color(0xFF00AA5B)),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDetailsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00AA5B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF00AA5B)),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: 'Website (Optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.web, color: Color(0xFF00AA5B)),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00AA5B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon:
                    const Icon(Icons.location_on, color: Color(0xFF00AA5B)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter store address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedLocation != null
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: _selectedLocation!,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'No location selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'GPS Coordinates',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon:
                    const Icon(Icons.gps_fixed, color: Color(0xFF00AA5B)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: Color(0xFF00AA5B)),
                  onPressed: _getCurrentLocation,
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.location_searching),
              label: const Text('Get Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AA5B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicensesSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Licenses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00AA5B),
              ),
            ),
            const SizedBox(height: 16),
            _buildLicenseUploadCard(
              title: 'Business License',
              subtitle: 'Upload your business license document',
              icon: Icons.business_center,
              imageFile: _businessLicenseImage,
              imageUrl: Provider.of<BusinessProvider>(context)
                  .business
                  ?.storeDetails
                  ?.businessLicenseUrl,
              onTap: () => _pickImage(ImageType.businessLicense),
            ),
            const SizedBox(height: 16),
            _buildLicenseUploadCard(
              title: 'Health & Sanitation License',
              subtitle: 'Upload your health and sanitation certificate',
              icon: Icons.health_and_safety,
              imageFile: _healthSanitationLicenseImage,
              imageUrl: Provider.of<BusinessProvider>(context)
                  .business
                  ?.storeDetails
                  ?.healthLicenseUrl,
              onTap: () => _pickImage(ImageType.healthLicense),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? imageFile,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00AA5B)),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTap,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                    )
                  : imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF00AA5B),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Failed to load image',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to upload',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateStore,
        child: const Text(
          'Update Store',
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00AA5B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}

enum ImageType {
  businessLicense,
  healthLicense,
  profileImage,
}
