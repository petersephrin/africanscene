import 'package:cloud_firestore/cloud_firestore.dart';

enum DeletionStatus {
  pending,
  approved,
  rejected;

  static DeletionStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'approved':
        return DeletionStatus.approved;
      case 'rejected':
        return DeletionStatus.rejected;
      case 'pending':
      default:
        return DeletionStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case DeletionStatus.approved:
        return 'approved';
      case DeletionStatus.rejected:
        return 'rejected';
      case DeletionStatus.pending:
        return 'pending';
    }
  }

  String get displayName {
    switch (this) {
      case DeletionStatus.approved:
        return 'Approved';
      case DeletionStatus.rejected:
        return 'Rejected';
      case DeletionStatus.pending:
        return 'Pending';
    }
  }
}

class DeletionRequestModel {
  final String id;
  final String recordId;
  final String requestedBy;
  final String? requesterName;
  final String reason;
  final DeletionStatus status;
  final String? reviewedBy;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeletionRequestModel({
    required this.id,
    required this.recordId,
    required this.requestedBy,
    this.requesterName,
    required this.reason,
    this.status = DeletionStatus.pending,
    this.reviewedBy,
    this.reviewerName,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory DeletionRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DeletionRequestModel.fromMap(data, doc.id);
  }

  factory DeletionRequestModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return DeletionRequestModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      recordId: (data['record_id'] ?? data['recordId'] ?? '').toString(),
      requestedBy: (data['requested_by'] ?? data['requestedBy'] ?? '').toString(),
      requesterName: data['requester_name']?.toString() ?? data['requesterName']?.toString(),
      reason: (data['reason'] ?? '').toString(),
      status: DeletionStatus.fromString(data['status']?.toString()),
      reviewedBy: data['reviewed_by']?.toString() ?? data['reviewedBy']?.toString(),
      reviewerName: data['reviewer_name']?.toString() ?? data['reviewerName']?.toString(),
      reviewedAt: parseDate(data['reviewed_at'] ?? data['reviewedAt']),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'requested_by': requestedBy,
      'requester_name': requesterName,
      'reason': reason,
      'status': status.toDbString(),
      'reviewed_by': reviewedBy,
      'reviewer_name': reviewerName,
      'reviewed_at': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      '_id': id,
      'record_id': recordId,
      'recordId': recordId,
      'requested_by': requestedBy,
      'requestedBy': requestedBy,
      'requester_name': requesterName,
      'requesterName': requesterName,
      'reason': reason,
      'status': status.toDbString(),
      'reviewed_by': reviewedBy,
      'reviewedBy': reviewedBy,
      'reviewer_name': reviewerName,
      'reviewerName': reviewerName,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toLocalJson();

  DeletionRequestModel copyWith({
    String? recordId,
    String? requestedBy,
    String? requesterName,
    String? reason,
    DeletionStatus? status,
    String? reviewedBy,
    String? reviewerName,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeletionRequestModel(
      id: id,
      recordId: recordId ?? this.recordId,
      requestedBy: requestedBy ?? this.requestedBy,
      requesterName: requesterName ?? this.requesterName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
