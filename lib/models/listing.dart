class Listing {
  final String id;
  final String name;
  final String description;
  final String category;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? website;
  final List<String> imageUrls;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Listing({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.website,
    this.imageUrls = const [],
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Listing] from a Firestore document map.
  factory Listing.fromMap(String id, Map<String, dynamic> map) {
    return Listing(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      phoneNumber: map['phoneNumber'] as String?,
      website: map['website'] as String?,
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
      ownerId: map['ownerId'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? 0,
      ),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  /// Converts this [Listing] to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'website': website,
      'imageUrls': imageUrls,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  Listing copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? website,
    List<String>? imageUrls,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      imageUrls: imageUrls ?? this.imageUrls,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Listing && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Listing(id: $id, name: $name, category: $category)';
}
