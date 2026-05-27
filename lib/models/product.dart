import 'package:intl/intl.dart';

final kwacha = NumberFormat.currency(symbol: 'K', decimalDigits: 2);

const productCategories = <String>[
  'Food',
  'Groceries',
  'Stationery',
  'Electronics',
  'Clothes',
  'Services',
  'Other',
];

class Product {
  final String id;
  final String sellerId;
  final String sellerName;
  final String name;
  final String description;
  final String category;
  final double price;
  final bool available;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.available,
    this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id:          j['id'] as String,
        sellerId:    j['sellerId'] as String,
        sellerName:  j['sellerName'] as String,
        name:        j['name'] as String,
        description: j['description'] as String? ?? '',
        category:    j['category'] as String,
        price:       (j['price'] as num).toDouble(),
        available:   j['available'] as bool? ?? true,
        imageUrl:    j['imageUrl'] as String?,
        createdAt:   j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'name':        name,
        'description': description,
        'category':    category,
        'price':       price,
        'available':   available,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
