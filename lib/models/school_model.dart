import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String id;
  final String name;
  final String location;
  final String type;
  final int students;
  final String? motto;
  final String? principal;
  final String? phone;
  final String? email;
  final int established;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolModel({
    required this.id,
    required this.name,
    required this.location,
    this.type = 'Secondary',
    this.students = 0,
    this.motto,
    this.principal,
    this.phone,
    this.email,
    this.established = 2024,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SchoolModel.fromMap(data, doc.id);
  }

  factory SchoolModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    int parseNum(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    return SchoolModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      name: (data['name'] ?? 'Unnamed School').toString(),
      location: (data['location'] ?? 'Unknown').toString(),
      type: (data['type'] ?? 'Secondary').toString(),
      students: parseNum(data['students'], 0),
      motto: data['motto']?.toString(),
      principal: data['principal']?.toString(),
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      established: parseNum(data['established'], 2024),
      description: data['description']?.toString(),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'type': type,
      'students': students,
      'motto': motto,
      'principal': principal,
      'phone': phone,
      'email': email,
      'established': established,
      'description': description,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SchoolModel copyWith({
    String? name,
    String? location,
    String? type,
    int? students,
    String? motto,
    String? principal,
    String? phone,
    String? email,
    int? established,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolModel(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      students: students ?? this.students,
      motto: motto ?? this.motto,
      principal: principal ?? this.principal,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      established: established ?? this.established,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
