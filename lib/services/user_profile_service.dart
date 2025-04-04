import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fetch user details from Firestore
  Future<Map<String, dynamic>?> getUserDetails() async {
    final user = getCurrentUser();
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data();
    }
    return null;
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = getCurrentUser();
    if (user != null) {
      // Update Firebase Auth display name
      await user.updateDisplayName(displayName);

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });
    }
  }

  // Get active orders
  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    final user = getCurrentUser();
    if (user != null) {
      // Placeholder for actual order fetching logic
      // This would typically involve querying an 'orders' collection
      return [
        {
          'orderId': 'ORD001',
          'storeName': 'Cafe Green',
          'pickupTime': DateTime.now().add(Duration(hours: 2)),
          'status': 'Confirmed'
        }
      ];
    }
    return [];
  }
}
