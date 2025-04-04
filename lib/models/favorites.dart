import 'package:flutter/material.dart';

class FavoriteItem {
  final String productName;
  final String imagePath;
  final String price;
  final String pickUpTime;
  final String storeName;
  final double rating;
  final double distance;

  FavoriteItem({
    required this.productName,
    required this.imagePath,
    required this.price,
    required this.pickUpTime,
    required this.storeName,
    required this.rating,
    required this.distance,
  });
}

List<FavoriteItem> favoriteItems = [];
