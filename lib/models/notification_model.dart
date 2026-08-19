import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String? relatedRecordId;
  final String? relatedSchoolId;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.read = false,
    this.relatedRecordId,
    this.relatedSchoolId,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return NotificationModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      userId: (data['user_id'] ?? data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      type: (data['type'] ?? 'info').toString(),
      read: data['read'] == true,
      relatedRecordId: data['related_record_id']?.toString() ?? data['relatedRecordId']?.toString(),
      relatedSchoolId: data['related_school_id']?.toString() ?? data['relatedSchoolId']?.toString(),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'related_record_id': relatedRecordId,
      'related_school_id': relatedSchoolId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  NotificationModel copyWith({
    String? title,
    String? message,
    String? type,
    bool? read,
    String? relatedRecordId,
    String? relatedSchoolId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      relatedRecordId: relatedRecordId ?? this.relatedRecordId,
      relatedSchoolId: relatedSchoolId ?? this.relatedSchoolId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
