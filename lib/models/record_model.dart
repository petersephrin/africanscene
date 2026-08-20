import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_field_model.dart';

class RecordModel {
  final String id;
  final String schoolId;
  final FormType formType;
  final String submittedBy;
  final String? submittedById;
  final Map<String, dynamic> data;
  final bool synced;
  final List<Map<String, dynamic>> formFieldsSnapshot;
  final int versionNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOffline;

  RecordModel({
    required this.id,
    required this.schoolId,
    required this.formType,
    required this.submittedBy,
    this.submittedById,
    required this.data,
    this.synced = true,
    this.formFieldsSnapshot = const [],
    this.versionNumber = 1,
    this.createdAt,
    this.updatedAt,
    this.isOffline = false,
  });

  factory RecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return RecordModel.fromMap(data, doc.id);
  }

  factory RecordModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    int parseNum(dynamic val, [int fallback = 1]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    List<Map<String, dynamic>> parseSnapshots(dynamic val) {
      if (val is List) {
        return val.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }

    return RecordModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      schoolId: (data['school_id'] ?? data['schoolId'] ?? '').toString(),
      formType: FormType.fromString((data['form_type'] ?? data['formType'])?.toString()),
      submittedBy: (data['submitted_by'] ?? data['submittedBy'] ?? 'Unknown').toString(),
      submittedById: data['submittedById']?.toString() ?? data['submitted_by']?.toString(),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      synced: data['synced'] == true,
      formFieldsSnapshot: parseSnapshots(data['form_fields_snapshot'] ?? data['formFieldsSnapshot']),
      versionNumber: parseNum(data['version_number'] ?? data['versionNumber'], 1),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at']),
      isOffline: data['_offline'] == true || data['synced'] == false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'form_type': formType.toDbString(),
      'submitted_by': submittedBy,
      'submittedById': submittedById,
      'data': data,
      'synced': synced,
      'form_fields_snapshot': formFieldsSnapshot,
      'version_number': versionNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static dynamic _sanitizeForJson(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate().toIso8601String();
    if (val is DateTime) return val.toIso8601String();
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), _sanitizeForJson(v)));
    }
    if (val is List) {
      return val.map((e) => _sanitizeForJson(e)).toList();
    }
    return val;
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      '_id': id,
      'school_id': schoolId,
      'schoolId': schoolId,
      'form_type': formType.toDbString(),
      'formType': formType.toDbString(),
      'submitted_by': submittedBy,
      'submittedBy': submittedBy,
      'submittedById': submittedById,
      'data': _sanitizeForJson(data) is Map ? _sanitizeForJson(data) : {},
      'synced': synced,
      'form_fields_snapshot': (_sanitizeForJson(formFieldsSnapshot) as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      'version_number': versionNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '_offline': isOffline,
    };
  }

  Map<String, dynamic> toJson() => toLocalJson();

  RecordModel copyWith({
    String? id,
    String? schoolId,
    FormType? formType,
    String? submittedBy,
    String? submittedById,
    Map<String, dynamic>? data,
    bool? synced,
    List<Map<String, dynamic>>? formFieldsSnapshot,
    int? versionNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOffline,
  }) {
    return RecordModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      formType: formType ?? this.formType,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedById: submittedById ?? this.submittedById,
      data: data ?? this.data,
      synced: synced ?? this.synced,
      formFieldsSnapshot: formFieldsSnapshot ?? this.formFieldsSnapshot,
      versionNumber: versionNumber ?? this.versionNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class RecordVersionModel {
  final String id;
  final String recordId;
  final String schoolId;
  final FormType formType;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> formFieldsSnapshot;
  final String editedBy;
  final String editReason;
  final int versionNumber;
  final DateTime? createdAt;

  RecordVersionModel({
    required this.id,
    required this.recordId,
    required this.schoolId,
    required this.formType,
    required this.data,
    this.formFieldsSnapshot = const [],
    required this.editedBy,
    required this.editReason,
    required this.versionNumber,
    this.createdAt,
  });

  factory RecordVersionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return RecordVersionModel.fromMap(data, doc.id);
  }

  factory RecordVersionModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    int parseNum(dynamic val, [int fallback = 1]) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    List<Map<String, dynamic>> parseSnapshots(dynamic val) {
      if (val is List) {
        return val.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    }

    return RecordVersionModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      recordId: (data['record_id'] ?? data['recordId'] ?? '').toString(),
      schoolId: (data['school_id'] ?? data['schoolId'] ?? '').toString(),
      formType: FormType.fromString((data['form_type'] ?? data['formType'])?.toString()),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      formFieldsSnapshot: parseSnapshots(data['form_fields_snapshot'] ?? data['formFieldsSnapshot']),
      editedBy: (data['edited_by'] ?? data['editedBy'] ?? 'Unknown').toString(),
      editReason: (data['edit_reason'] ?? data['editReason'] ?? 'No reason provided').toString(),
      versionNumber: parseNum(data['version_number'] ?? data['versionNumber'], 1),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'school_id': schoolId,
      'form_type': formType.toDbString(),
      'data': data,
      'form_fields_snapshot': formFieldsSnapshot,
      'edited_by': editedBy,
      'edit_reason': editReason,
      'version_number': versionNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      '_id': id,
      'record_id': recordId,
      'recordId': recordId,
      'school_id': schoolId,
      'schoolId': schoolId,
      'form_type': formType.toDbString(),
      'formType': formType.toDbString(),
      'data': RecordModel._sanitizeForJson(data) is Map ? RecordModel._sanitizeForJson(data) : {},
      'form_fields_snapshot': (RecordModel._sanitizeForJson(formFieldsSnapshot) as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      'edited_by': editedBy,
      'editedBy': editedBy,
      'edit_reason': editReason,
      'editReason': editReason,
      'version_number': versionNumber,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toLocalJson();
}
