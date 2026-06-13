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

  /// All image paths for this product (host-relative). The first entry is the
  /// primary image shown in lists and cards. May be empty.
  final List<String> imageUrls;
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
    List<String>? imageUrls,
    required this.createdAt,
  }) : imageUrls = imageUrls ?? const [];

  /// Primary image (first in the gallery), or null if there are none. Kept for
  /// the many call sites that only need a single thumbnail.
  String? get imageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  factory Product.fromJson(Map<String, dynamic> j) {
    // Accept both the new `imageUrls` list and the legacy single `imageUrl`,
    // so the app keeps working against an older backend or older rows.
    final list = <String>[];
    final raw = j['imageUrls'];
    if (raw is List) {
      list.addAll(raw.whereType<String>());
    }
    final single = j['imageUrl'] as String?;
    if (list.isEmpty && single != null && single.isNotEmpty) {
      list.add(single);
    }
    return Product(
      id:          j['id'] as String,
      sellerId:    j['sellerId'] as String,
      sellerName:  j['sellerName'] as String,
      name:        j['name'] as String,
      description: j['description'] as String? ?? '',
      category:    j['category'] as String,
      price:       (j['price'] as num).toDouble(),
      available:   j['available'] as bool? ?? true,
      imageUrls:   list,
      createdAt:   j['createdAt'] != null
          ? DateTime.parse(j['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name':        name,
        'description': description,
        'category':    category,
        'price':       price,
        'available':   available,
        'imageUrls':   imageUrls,
        // Keep sending `imageUrl` (first image) for backward compatibility.
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
