class Category {
  final int id;
  final String nameAm;
  final String nameEn;
  final String icon;
  final int? parentId;

  Category({
    required this.id,
    required this.nameAm,
    required this.nameEn,
    required this.icon,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      nameAm: json['name_am'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      icon: json['icon'] as String? ?? 'grass',
      parentId: json['parent_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_am': nameAm,
    'name_en': nameEn,
    'icon': icon,
    'parent_id': parentId,
  };
}
