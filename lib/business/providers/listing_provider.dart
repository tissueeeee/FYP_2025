import 'package:flutter/cupertino.dart';
import 'package:fyp_project/business/services/listing_service.dart';
import '../models/listing_model.dart';

class ListingProvider with ChangeNotifier {
  List<Listing> _listings = [];

  List<Listing> get listings => _listings;

  void addListing(Listing listing) {
    _listings.add(listing);
    notifyListeners();
  }

  void updateListing(Listing listing) {
    final index = _listings.indexWhere((l) => l.id == listing.id);
    if (index != -1) {
      _listings[index] = listing;
      notifyListeners();
    }
  }

  void deleteListing(String id) {
    _listings.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> fetchListings(String businessId) async {
    final listingService = ListingService();
    final listingsData =
        await listingService.getListingsByBusinessId(businessId);
    _listings = listingsData;
    notifyListeners();
  }
}
