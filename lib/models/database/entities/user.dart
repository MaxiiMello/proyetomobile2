class User {
  final int? id;
  final String email;
  final String passwordHash;
  final String name;
  final String? phone;
  final bool isActive;
  final String? preferredCityCode;
  final String subscriptionPlan;
  final DateTime? subscriptionEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.phone,
    this.isActive = true,
    this.preferredCityCode,
    this.subscriptionPlan = 'essential',
    this.subscriptionEndDate,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'phone': phone,
      'is_active': isActive ? 1 : 0,
      'preferred_city_code': preferredCityCode,
      'subscription_plan': subscriptionPlan,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      isActive: (map['is_active'] as int) == 1,
      preferredCityCode: map['preferred_city_code'] as String?,
      subscriptionPlan: map['subscription_plan'] as String,
      subscriptionEndDate: map['subscription_end_date'] != null
          ? DateTime.parse(map['subscription_end_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
    );
  }
}