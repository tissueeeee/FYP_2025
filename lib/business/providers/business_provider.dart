import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp_project/business/services/business_service.dart';
import '../models/business_model.dart';

class BusinessProvider with ChangeNotifier {
  Business? _business;
  StoreDetails? _storeDetails;
  final BusinessService _businessService = BusinessService();

  Business? get business => _business;
  StoreDetails? get storeDetails => _storeDetails;

  void setBusiness(Business business) {
    _business = business;
    _storeDetails = business.storeDetails;
    if (kDebugMode) {
      print('Business updated in provider: ${business.name}');
      print('Store details updated: ${business.storeDetails?.storeName}');
      print('Profile image URL: ${business.storeDetails?.profileImageUrl}');
    }
    notifyListeners();
  }

  void updateStoreDetails(StoreDetails storeDetails) {
    _storeDetails = storeDetails;
    if (_business != null) {
      _business = Business(
        id: _business!.id,
        email: _business!.email,
        name: _business!.name,
        storeDetails: storeDetails,
      );
    }
    if (kDebugMode) {
      print('Store details updated separately: ${storeDetails.storeName}');
      print('Profile image URL: ${storeDetails.profileImageUrl}');
    }
    notifyListeners();
  }

  Future<void> fetchBusiness(String businessId) async {
    try {
      final businessData = await _businessService.getBusiness(businessId);
      if (businessData != null) {
        setBusiness(businessData);
        if (kDebugMode) {
          print('Business fetched successfully: ${businessData.name}');
          print(
              'Profile image URL: ${businessData.storeDetails?.profileImageUrl}');
        }
      } else {
        if (kDebugMode) {
          print('No business data found for ID: $businessId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching business: $e');
      }
    }
  }
}
