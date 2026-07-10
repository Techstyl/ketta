class AppUser {
  final String id;
  final String username;
  final String? fullName;
  final String? phone;
  final String? location;
  final String userType;
  final String? profileImage;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.username,
    this.fullName,
    this.phone,
    this.location,
    required this.userType,
    this.profileImage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    String? val(String key, [String? alt]) => (json[key] ?? json[alt]) as String?;
    return AppUser(
      id: val('id') ?? '',
      username: val('username') ?? '',
      fullName: val('full_name', 'fullName'),
      phone: val('phone'),
      location: val('location'),
      userType: val('user_type', 'userType') ?? 'buyer',
      profileImage: val('profile_image', 'profileImage'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isFarmer => userType == 'farmer';
  bool get isAdmin => userType == 'admin';
}
