class UserModel {
  int? id;
  String username;
  String password;
  String role; // admin, staff
  int? employeeId;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.employeeId,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'employeeId': employeeId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      employeeId: map['employeeId'],
    );
  }
}
