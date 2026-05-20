import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      sellerId: d['sellerId'] ?? '',
      sellerName: d['sellerName'] ?? '',
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'Other',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      available: d['available'] ?? true,
      imageUrl: d['imageUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'available': available,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

const productCategories = <String>[
  'Food',
  'Groceries',
  'Stationery',
  'Electronics',
  'Clothes',
  'Services',
  'Other',
];
