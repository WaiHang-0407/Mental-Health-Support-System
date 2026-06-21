class SponsorshipProduct {
  final String? id;
  final String sponsorshipId;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isDeleted;
  final bool isArchived;
  final DateTime? createdAt;

  SponsorshipProduct({
    this.id,
    required this.sponsorshipId,
    required this.name,
    this.description,
    this.imageUrl,
    this.isDeleted = false,
    this.isArchived = false,
    this.createdAt,
  });

  factory SponsorshipProduct.fromMap(Map<String, dynamic> map) {
    return SponsorshipProduct(
      id: map['id'],
      sponsorshipId: map['sponsorship_id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['image_url'],
      isDeleted: map['is_deleted'] ?? false,
      isArchived: map['is_archived'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sponsorship_id': sponsorshipId,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_deleted': isDeleted,
      'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
