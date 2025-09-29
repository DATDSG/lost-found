enum ItemType { lost, found }

enum ItemStatus { active, claimed, resolved, expired }

class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;

  const Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
  });
}

class ItemImage {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final bool isPrimary;

  const ItemImage({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.isPrimary = false,
  });
}

class Item {
  final String id;
  final ItemType type;
  final ItemStatus status;
  final String title;
  final String description;
  final String category;
  final String? subcategory;
  final String? brand;
  final String? color;
  final String? model;
  final Location location;
  final DateTime dateLostFound;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? userName;
  final List<ItemImage> images;
  final String language;
  final Map<String, dynamic>? contactInfo;
  final double? rewardOffered;

  const Item({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.category,
    this.subcategory,
    this.brand,
    this.color,
    this.model,
    required this.location,
    required this.dateLostFound,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.userName,
    this.images = const [],
    this.language = 'en',
    this.contactInfo,
    this.rewardOffered,
  });

  Item copyWith({
    String? id,
    ItemType? type,
    ItemStatus? status,
    String? title,
    String? description,
    String? category,
    String? subcategory,
    String? brand,
    String? color,
    String? model,
    Location? location,
    DateTime? dateLostFound,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? userName,
    List<ItemImage>? images,
    String? language,
    Map<String, dynamic>? contactInfo,
    double? rewardOffered,
  }) {
    return Item(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      model: model ?? this.model,
      location: location ?? this.location,
      dateLostFound: dateLostFound ?? this.dateLostFound,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      images: images ?? this.images,
      language: language ?? this.language,
      contactInfo: contactInfo ?? this.contactInfo,
      rewardOffered: rewardOffered ?? this.rewardOffered,
    );
  }
}
