class Category {
  final String id;
  final String name;
  final String? iconEmoji;
  final String? imagePath;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.iconEmoji,
    this.imagePath,
    this.sortOrder = 0,
  });

  Category copyWith({
    String? id,
    String? name,
    String? iconEmoji,
    String? imagePath,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      imagePath: imagePath ?? this.imagePath,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconEmoji: json['icon_emoji'] as String?,
      imagePath: json['image_path'] as String?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon_emoji': iconEmoji,
        'image_path': imagePath,
        'sort_order': sortOrder,
      };
}
