import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';
import 'package:fyp_project/models/user_model.dart' as user_model;

class BusinessSignUpPage extends StatefulWidget {
  const BusinessSignUpPage({Key? key}) : super(key: key);

  @override
  _BusinessSignUpPageState createState() => _BusinessSignUpPageState();
}

class _BusinessSignUpPageState extends State<BusinessSignUpPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentStep = 0;

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Check if a user is already logged in
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to register your business.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Check if the user already has a business
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = user_model.User.fromMap(userDoc.data()!);
          if (userData.hasBusiness) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already registered a business.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        // If a user is logged in, use their existing UID and email
        final business = Business(
          id: currentUser.uid, // Use the existing user's UID
          email: currentUser.email ??
              _emailController.text.trim(), // Use the existing email
          name: _businessNameController.text,
          storeDetails: StoreDetails(
            storeName: _storeNameController.text,
            address: _addressController.text,
            location: _locationController.text,
            contact: _contactController.text,
          ),
        );

        // Save the business data to Firestore
        await _firestore
            .collection('businesses')
            .doc(currentUser.uid)
            .set(business.toJson());

        // Update the user's hasBusiness field to true
        await _firestore.collection('users').doc(currentUser.uid).update({
          'hasBusiness': true,
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text(
                'Your business has been registered successfully. You can now start adding surplus food items.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to ManageAccountPage
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Business registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Business'),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _signUp();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentStep == 2 ? 'Register' : 'Continue',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_currentStep > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text(
                          'Back',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Account'),
              content: _buildAccountStep(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Business'),
              content: _buildBusinessStep(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Location'),
              content: _buildLocationStep(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
    return Column(
      children: [
        _buildHeader('Create your account',
            'We\'ll use this information to set up your business account'),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'At least 6 characters',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy.',
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      children: [
        _buildHeader('Business Details', 'Tell us about your business'),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name',
          icon: Icons.business,
          validator: (value) =>
              value!.isEmpty ? 'Business name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _storeNameController,
          label: 'Store Name',
          icon: Icons.store,
          validator: (value) =>
              value!.isEmpty ? 'Store name is required' : null,
          hint: 'Name displayed to customers',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _contactController,
          label: 'Contact Phone',
          icon: Icons.phone,
          validator: (value) =>
              value!.isEmpty ? 'Contact number is required' : null,
          hint: 'Store contact number',
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        _buildHeader('Store Location', 'Where are you located?'),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          label: 'Street Address',
          icon: Icons.location_on_outlined,
          validator: (value) => value!.isEmpty ? 'Address is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: 'City/Area',
          icon: Icons.location_city,
          validator: (value) => value!.isEmpty ? 'City/Area is required' : null,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[800]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Make sure your location is accurate as customers will use this to find your store.',
                  style: TextStyle(color: Colors.orange[800], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
