enum ServiceCategory {
  tutoring,
  haircut,
  laundry,
  food,
  techHelp,
  photography,
  design,
  other,
}

const serviceCategories = ServiceCategory.values;

String serviceCategoryLabel(ServiceCategory c) {
  switch (c) {
    case ServiceCategory.tutoring:    return 'Tutoring';
    case ServiceCategory.haircut:     return 'Haircut & Grooming';
    case ServiceCategory.laundry:     return 'Laundry';
    case ServiceCategory.food:        return 'Food & Cooking';
    case ServiceCategory.techHelp:    return 'Tech Help';
    case ServiceCategory.photography: return 'Photography';
    case ServiceCategory.design:      return 'Design';
    case ServiceCategory.other:       return 'Other';
  }
}

ServiceCategory serviceCategoryFromString(String? s) {
  switch (s) {
    case 'tutoring':    return ServiceCategory.tutoring;
    case 'haircut':     return ServiceCategory.haircut;
    case 'laundry':     return ServiceCategory.laundry;
    case 'food':        return ServiceCategory.food;
    case 'techHelp':    return ServiceCategory.techHelp;
    case 'photography': return ServiceCategory.photography;
    case 'design':      return ServiceCategory.design;
    default:            return ServiceCategory.other;
  }
}

class ServiceListing {
  final String id;
  final String providerId;
  final String providerName;
  final String? providerPhone;
  final String title;
  final String description;
  final ServiceCategory category;
  final double? price;
  final String? priceNote;
  final bool available;
  final DateTime createdAt;

  const ServiceListing({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.providerPhone,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    this.priceNote,
    required this.available,
    required this.createdAt,
  });

  factory ServiceListing.fromJson(Map<String, dynamic> j) => ServiceListing(
        id:            j['id'] as String,
        providerId:    j['providerId'] as String,
        providerName:  j['providerName'] as String,
        providerPhone: j['providerPhone'] as String?,
        title:         j['title'] as String,
        description:   j['description'] as String,
        category:      serviceCategoryFromString(j['category'] as String?),
        price:         (j['price'] as num?)?.toDouble(),
        priceNote:     j['priceNote'] as String?,
        available:     j['available'] as bool? ?? true,
        createdAt:     DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title':        title,
        'description':  description,
        'category':     category.name,
        if (price != null)     'price':     price,
        if (priceNote != null) 'priceNote': priceNote,
        'available':    available,
      };
}
