class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final List<String> skills;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.skills = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'name': name, 'email': email, 'role': role, 'skills': skills};
  }

  UserModel copyWith({String? userId, String? name, String? email, String? role, List<String>? skills}) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      skills: skills ?? this.skills,
    );
  }
}
