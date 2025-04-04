class CartItem {
  final String productId;
  final String productName;
  final String storeName;
  final String price;
  final String imagePath;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.imagePath,
    this.quantity = 1,
  });

  // Add this factory method
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      productName: map['productName'],
      storeName: map['storeName'],
      price: map['price'],
      imagePath: map['imagePath'],
      quantity: map['quantity'],
    );
  }

  // Add this method
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'storeName': storeName,
      'price': price,
      'imagePath': imagePath,
      'quantity': quantity,
    };
  }
}
