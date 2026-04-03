/// 用户模型
class User {
  final int id;
  final String phone;
  final String nickname;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 公司模型
class Company {
  final int id;
  final int userId;
  final String name;
  final String taxNo;
  final String address;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.userId,
    required this.name,
    required this.taxNo,
    required this.address,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      taxNo: json['tax_no'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'tax_no': taxNo,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
