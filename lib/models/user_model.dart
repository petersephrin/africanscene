import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  superAdmin,
  admin,
  staffAdmin,
  staff,
  researcher,
  teacher;

  static UserRole fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'staff_admin':
      case 'staffadmin':
        return UserRole.staffAdmin;
      case 'staff':
      case 'hr':
        return UserRole.staff;
      case 'teacher':
        return UserRole.teacher;
      case 'researcher':
      default:
        return UserRole.researcher;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.staffAdmin:
        return 'staff_admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.researcher:
        return 'researcher';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.staffAdmin:
        return 'Staff Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.researcher:
        return 'Researcher';
    }
  }

  bool get isAdmin =>
      this == UserRole.superAdmin ||
      this == UserRole.admin ||
      this == UserRole.staffAdmin;
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String name;
  final String? phone;
  final UserRole role;
  final String userType;
  final String status;
  final String? department;
  final String? specialization;
  final List<String> schoolIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.name,
    this.phone,
    required this.role,
    required this.userType,
    this.status = 'active',
    this.department,
    this.specialization,
    this.schoolIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role.isAdmin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final fName = (data['first_name'] ?? data['firstName'] ?? '').toString();
    final lName = (data['last_name'] ?? data['lastName'] ?? '').toString();
    final fullName = (data['name'] ?? '').toString().isNotEmpty
        ? data['name'].toString()
        : '$fName $lName'.trim();

    final roleStr = (data['role'] ?? data['user_type'] ?? 'researcher').toString();
    final userTypeStr = (data['user_type'] ?? data['userType'] ?? roleStr).toString();

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      firstName: fName,
      lastName: lName,
      name: fullName.isNotEmpty ? fullName : (data['email'] ?? '').toString(),
      phone: data['phone']?.toString(),
      role: UserRole.fromString(roleStr),
      userType: userTypeStr,
      status: (data['status'] ?? 'active').toString(),
      department: data['department']?.toString(),
      specialization: data['specialization']?.toString(),
      schoolIds: List<String>.from(data['schoolIds'] ?? data['school_ids'] ?? []),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'name': name,
      'phone': phone,
      'role': role.toDbString(),
      'user_type': userType,
      'status': status,
      'department': department,
      'specialization': specialization,
      'schoolIds': schoolIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? name,
    String? phone,
    UserRole? role,
    String? userType,
    String? status,
    String? department,
    String? specialization,
    List<String>? schoolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      department: department ?? this.department,
      specialization: specialization ?? this.specialization,
      schoolIds: schoolIds ?? this.schoolIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
