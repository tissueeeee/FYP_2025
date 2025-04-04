import 'package:flutter/foundation.dart';
import 'package:fyp_project/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  Future<void> loadUserData() async {
    // First check if user is logged in with Firebase
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Get user data from Firestore
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Handle potentially null numeric values with defaults
          _user = User(
            id: currentUser.uid,
            name: userData['name'] ?? 'User',
            email: userData['email'] ?? currentUser.email ?? '',
            phoneNumber:
                userData['phoneNumber'] ?? currentUser.phoneNumber ?? '',
            address: userData['address'] ?? '',
            avatarUrl: userData['avatarUrl'] ?? 'assets/avatar.png',
            co2Saved: (userData['co2Saved'] ?? 0).toDouble(),
            moneySaved: (userData['moneySaved'] ?? 0).toDouble(),
            totalOrders: userData['totalOrders'] ?? 0,
            foodTypesSaved: {}, // Initialize empty if not provided
          );
          notifyListeners();
          return;
        } else {
          // Create a default user record if it doesn't exist yet
          _user = User(
            id: currentUser.uid,
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            phoneNumber: currentUser.phoneNumber ?? '',
            address: '',
            avatarUrl: currentUser.photoURL ?? 'assets/avatar.png',
            co2Saved: 0.0,
            moneySaved: 0.0,
            totalOrders: 0,
          );

          // Save this default user to Firestore
          await saveUserData();
          notifyListeners();
          return;
        }
      } catch (e) {
        print('Error loading user data from Firestore: $e');
        // Create a default user on error
        _user = User(
          id: currentUser.uid,
          name: currentUser.displayName ?? 'User',
          email: currentUser.email ?? '',
          phoneNumber: currentUser.phoneNumber ?? '',
          address: '',
          avatarUrl: currentUser.photoURL ?? 'assets/avatar.png',
          co2Saved: 0.0,
          moneySaved: 0.0,
          totalOrders: 0,
        );
        notifyListeners();
        return;
      }
    }

    // Fallback to local storage if Firebase retrieval fails
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final decodedData = json.decode(userData);
        _user = User.fromMap(decodedData);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data from local storage: $e');
    }
  }

  Future<void> saveUserData() async {
    if (_user == null) return;

    // Save to Firestore if user is authenticated
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).set(
              _user!.toMap()..remove('id'), // Remove ID as it's the document ID
              SetOptions(merge: true),
            );
      } catch (e) {
        print('Error saving user data to Firestore: $e');
      }
    }

    // Also save locally as backup
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode(_user!.toMap());
    await prefs.setString('user_data', userData);
  }

  Future<bool> login(String email, String password) async {
    try {
      // Authenticate with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      final uid = userCredential.user!.uid;
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _user = User.fromMap({
          'id': uid,
          ...userDoc.data() as Map<String, dynamic>,
        });
      } else {
        // If user exists in Auth but not in Firestore, create a basic profile
        _user = User(
          id: uid,
          name: userCredential.user!.displayName ?? 'User',
          email: email,
          phoneNumber: userCredential.user!.phoneNumber ?? '',
          address: '',
          avatarUrl: userCredential.user!.photoURL ?? 'assets/avatar.png',
          co2Saved: 0.0,
          moneySaved: 0.0,
          totalOrders: 0,
        );
        await saveUserData();
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Firebase login error: $e');

      // For testing/demo purposes, allow a fallback login
      if (email == 'test@example.com' && password == 'password') {
        _user = User(
          id: 'test123',
          name: 'Test User',
          email: email,
          phoneNumber: '+60123456789',
          address: '123 Main Street, Kuala Lumpur',
          avatarUrl: 'assets/avatar.png',
          co2Saved: 12.5,
          moneySaved: 90.0,
          totalOrders: 15,
        );

        await saveUserData();
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String password, String phoneNumber) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      final uid = userCredential.user!.uid;

      // Create user object
      _user = User(
        id: uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: '',
        avatarUrl: 'assets/avatar.png',
        co2Saved: 0.0,
        moneySaved: 0.0,
        totalOrders: 0,
      );

      await saveUserData();
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? avatarUrl,
  }) async {
    if (_user == null) return;

    _user = User(
      id: _user!.id,
      name: name ?? _user!.name,
      email: _user!.email,
      phoneNumber: phoneNumber ?? _user!.phoneNumber,
      address: address ?? _user!.address,
      avatarUrl: avatarUrl ?? _user!.avatarUrl,
      co2Saved: _user!.co2Saved,
      moneySaved: _user!.moneySaved,
      totalOrders: _user!.totalOrders,
    );

    await saveUserData();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }

    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    notifyListeners();
  }

  // Enhanced method to update environmental impact metrics after order
  Future<void> updateImpactMetrics(
      double co2Saved, double moneySaved, Map<String, double> foodTypes) async {
    if (_user == null) return;

    // Update weekly impact
    // final now = DateTime.now();
    // final weekOfYear = '${now.year}-w${(now.day / 7).ceil()}';

    // // Map<String, double> updatedWeeklyImpact = Map.from(_user!.weeklyImpact);
    // // updatedWeeklyImpact[weekOfYear] = (updatedWeeklyImpact[weekOfYear] ?? 0) + co2Saved;

    // // Update monthly trends
    // final monthYear = '${now.month}/${now.year}';

    // Map<String, double> updatedMonthlyCO2 = Map.from(_user!.monthlyCO2Trend);
    // updatedMonthlyCO2[monthYear] = (updatedMonthlyCO2[monthYear] ?? 0) + co2Saved;

    // Map<String, double> updatedMonthlySavings = Map.from(_user!.monthlySavingsTrend);
    // updatedMonthlySavings[monthYear] = (updatedMonthlySavings[monthYear] ?? 0) + moneySaved;

    // Update food types saved
    // Map<String, double> updatedFoodTypes = Map.from(_user!.foodTypesSaved);
    // foodTypes.forEach((type, weight) {
    //   updatedFoodTypes[type] = (updatedFoodTypes[type] ?? 0) + weight;
    // });

    _user = User(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      phoneNumber: _user!.phoneNumber,
      address: _user!.address,
      avatarUrl: _user!.avatarUrl,
      co2Saved: _user!.co2Saved + co2Saved,
      moneySaved: _user!.moneySaved + moneySaved,
      totalOrders: _user!.totalOrders + 1,
    );

    await saveUserData();
    notifyListeners();

    // Record this impact in a separate Firestore collection for analytics
    try {
      await _firestore.collection('impact_metrics').add({
        'userId': _user!.id,
        'timestamp': FieldValue.serverTimestamp(),
        'co2Saved': co2Saved,
        'moneySaved': moneySaved,
        'foodTypes': foodTypes,
      });
    } catch (e) {
      print('Error saving impact metrics to Firestore: $e');
    }
  }

  // Get total CO2 impact by food type for pie chart
  Map<String, double> getFoodTypeImpact() {
    if (_user == null) return {};
    return _user!.foodTypesSaved;
  }

  // Calculate CO2 saved from weight of food
  double calculateCO2FromFoodWeight(double weightInKg, String foodType) {
    // CO2 emission factors based on food type (kg CO2 per kg food)
    final emissionFactors = {
      'Bakery': 1.3,
      'Produce': 0.9,
      'Dairy': 2.4,
      'Meat': 13.5,
      'Prepared': 2.0,
      'Other': 1.5,
    };

    return weightInKg *
        (emissionFactors[foodType] ?? emissionFactors['Other']!);
  }

  // Get user's weekly progress for current month
  Map<String, double> getCurrentMonthWeeklyProgress() {
    if (_user == null) return {};

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    Map<String, double> weeklyProgress = {};

    // _user!.weeklyImpact.forEach((key, value) {
    //   if (key.startsWith('$year-w')) {
    //     // Extract the week number
    //     final weekNum = int.tryParse(key.split('w')[1]) ?? 0;

    //     // Approximately map weeks to months (not perfect but works for visualization)
    //     final weekMonth = ((weekNum - 1) ~/ 4) + 1;

    //     if (weekMonth == month) {
    //       final weekOfMonth = ((weekNum - 1) % 4) + 1;
    //       weeklyProgress['Week $weekOfMonth'] = value;
    //     }
    //   }
    // });

    return weeklyProgress;
  }

  // Calculate projected annual savings based on current trends
  Map<String, double> getProjectedAnnualSavings() {
    if (_user == null || _user!.totalOrders == 0) {
      return {'co2': 0.0, 'money': 0.0};
    }

    // Get user's average impact per order
    final avgCO2PerOrder = _user!.co2Saved / _user!.totalOrders;
    final avgMoneyPerOrder = _user!.moneySaved / _user!.totalOrders;

    // Project based on current activity (assume 2 orders per week)
    final projectedOrdersPerYear = 2 * 52;

    return {
      'co2': avgCO2PerOrder * projectedOrdersPerYear,
      'money': avgMoneyPerOrder * projectedOrdersPerYear
    };
  }

  Future<void> updateUserImpactMetrics(
      double totalCO2Saved,
      double totalMoneySaved,
      int totalCompletedOrders,
      Map<String, double> foodTypesSaved) async {
    if (_user == null) return;

    _user = User(
      id: _user!.id,
      name: _user!.name,
      email: _user!.email,
      phoneNumber: _user!.phoneNumber,
      address: _user!.address,
      avatarUrl: _user!.avatarUrl,
      co2Saved: totalCO2Saved,
      moneySaved: totalMoneySaved,
      totalOrders: totalCompletedOrders,
      foodTypesSaved: foodTypesSaved,
    );

    await saveUserData();
    notifyListeners();
  }
}
