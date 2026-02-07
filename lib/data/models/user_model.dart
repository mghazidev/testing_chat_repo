class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? avatar;
  final String? phone;
  final String? bio;
  final String? status;
  final bool? isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.avatar,
    this.phone,
    this.bio,
    this.status,
    this.isOnline,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'] ?? json['userId'];
    return UserModel(
      id: id?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      bio: json['bio']?.toString(),
      status: json['status']?.toString(),
      isOnline: json['isOnline'] as bool?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'phone': phone,
        'bio': bio,
        'status': status,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
      };
}

// class UserModel {
//   final String id;
//   final String? name;
//   final String? email;
//   final String? avatar;
//   final String? phone;
//   final String? bio;
//   final String? status;
//   final bool? isOnline;

//   UserModel({
//     required this.id,
//     this.name,
//     this.email,
//     this.avatar,
//     this.phone,
//     this.bio,
//     this.status,
//     this.isOnline,
//   });

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     final id = json['_id'] ?? json['id'] ?? json['userId'];
//     return UserModel(
//       id: id?.toString() ?? '',
//       name: json['name']?.toString(),
//       email: json['email']?.toString(),
//       avatar: json['avatar']?.toString(),
//       phone: json['phone']?.toString(),
//       bio: json['bio']?.toString(),
//       status: json['status']?.toString(),
//       isOnline: json['isOnline'] as bool?,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'name': name,
//         'email': email,
//         'avatar': avatar,
//         'phone': phone,
//         'bio': bio,
//         'status': status,
//         'isOnline': isOnline,
//       };
// }
