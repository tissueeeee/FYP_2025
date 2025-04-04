import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createListing(Listing listing) async {
    await _firestore
        .collection('listings')
        .doc(listing.id)
        .set(listing.toJson());
  }

  Future<void> updateListing(Listing listing) async {
    await _firestore
        .collection('listings')
        .doc(listing.id)
        .update(listing.toJson());
  }

  Future<void> deleteListing(String id) async {
    await _firestore.collection('listings').doc(id).delete();
  }

  Future<List<Listing>> getListingsByBusinessId(String businessId) async {
    final querySnapshot = await _firestore
        .collection('listings')
        .where('businessId', isEqualTo: businessId)
        .get();
    return querySnapshot.docs
        .map((doc) => Listing.fromJson(doc.data()))
        .toList();
  }

  Future<List<Listing>> getAllListings() async {
    try {
      final querySnapshot = await _firestore.collection('listings').get();
      return querySnapshot.docs
          .map((doc) => Listing.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching all listings: $e');
      return [];
    }
  }
}
