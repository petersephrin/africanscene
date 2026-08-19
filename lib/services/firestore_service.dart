import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';
import '../models/form_field_model.dart';
import '../models/record_model.dart';
import '../models/deletion_request_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // SCHOOLS
  // ==========================================

  Stream<List<SchoolModel>> getSchoolsStream() {
    return _firestore.collection('schools').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<SchoolModel>> fetchSchools() async {
    final snapshot = await _firestore.collection('schools').get();
    return snapshot.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
  }

  Future<List<SchoolModel>> fetchSchoolsByIds(List<String> schoolIds) async {
    if (schoolIds.isEmpty) return [];
    // Firestore 'whereIn' supports up to 30 elements; for larger lists we chunk or fetch in parallel
    if (schoolIds.length <= 30) {
      final snapshot = await _firestore
          .collection('schools')
          .where(FieldPath.documentId, whereIn: schoolIds)
          .get();
      return snapshot.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();
    } else {
      final allSchools = await fetchSchools();
      final idSet = schoolIds.toSet();
      return allSchools.where((s) => idSet.contains(s.id)).toList();
    }
  }

  Future<String> addSchool(SchoolModel school) async {
    final docRef = _firestore.collection('schools').doc();
    final newSchool = school.copyWith(createdAt: DateTime.now());
    await docRef.set({
      ...newSchool.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Future<void> updateSchool(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('schools').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSchool(String id) async {
    await _firestore.collection('schools').doc(id).delete();
  }

  // ==========================================
  // FORM FIELDS (Dynamic Form Builder)
  // ==========================================

  Stream<List<FormFieldModel>> getFormFieldsStream() {
    return _firestore
        .collection('form_fields')
        .orderBy('field_order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FormFieldModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<FormFieldModel>> fetchFormFields() async {
    final snapshot = await _firestore
        .collection('form_fields')
        .orderBy('field_order', descending: false)
        .get();
    return snapshot.docs.map((doc) => FormFieldModel.fromFirestore(doc)).toList();
  }

  Future<String> addFormField(FormFieldModel field) async {
    // Get existing count for this form type to automatically set fieldOrder
    final existingSnapshot = await _firestore
        .collection('form_fields')
        .where('form_type', isEqualTo: field.formType.toDbString())
        .get();
    final nextOrder = existingSnapshot.docs.length + 1;

    final docRef = _firestore.collection('form_fields').doc();
    final newField = field.copyWith(
      fieldOrder: field.fieldOrder > 0 ? field.fieldOrder : nextOrder,
      createdAt: DateTime.now(),
    );

    await docRef.set({
      ...newField.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Future<void> updateFormField(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('form_fields').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFormField(String id, FormType formType) async {
    await _firestore.collection('form_fields').doc(id).delete();

    // Auto-reindex remaining fields sequentially 1..N
    final remainingDocs = await _firestore
        .collection('form_fields')
        .where('form_type', isEqualTo: formType.toDbString())
        .orderBy('field_order', descending: false)
        .get();

    final batch = _firestore.batch();
    for (int i = 0; i < remainingDocs.docs.length; i++) {
      batch.update(remainingDocs.docs[i].reference, {'field_order': i + 1});
    }
    await batch.commit();
  }

  Future<void> reorderFormFields(FormType formType, List<String> orderedIds) async {
    final batch = _firestore.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      final docRef = _firestore.collection('form_fields').doc(orderedIds[i]);
      batch.update(docRef, {'field_order': i + 1});
    }
    await batch.commit();
  }

  // ==========================================
  // RECORDS
  // ==========================================

  Stream<List<RecordModel>> getRecordsStream({String? schoolId}) {
    Query query = _firestore.collection('records');
    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.where('school_id', isEqualTo: schoolId);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => RecordModel.fromFirestore(doc)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Future<List<RecordModel>> fetchRecords({String? schoolId, String? submittedById}) async {
    Query query = _firestore.collection('records');
    if (schoolId != null && schoolId.isNotEmpty) {
      query = query.where('school_id', isEqualTo: schoolId);
    }
    if (submittedById != null && submittedById.isNotEmpty) {
      query = query.where('submittedById', isEqualTo: submittedById);
    }
    final snapshot = await query.get();
    final list = snapshot.docs.map((doc) => RecordModel.fromFirestore(doc)).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Future<String> createRecord(RecordModel record) async {
    final docRef = record.id.isNotEmpty && !record.id.startsWith('local_')
        ? _firestore.collection('records').doc(record.id)
        : _firestore.collection('records').doc();

    final newRecord = record.copyWith(
      synced: true,
      createdAt: record.createdAt ?? DateTime.now(),
    );

    await docRef.set({
      ...newRecord.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Future<void> updateRecord(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('records').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRecordWithVersion(RecordModel record, RecordVersionModel version) async {
    final batch = _firestore.batch();
    final recordDoc = _firestore.collection('records').doc(record.id);
    batch.update(recordDoc, {
      ...record.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final versionDoc = _firestore.collection('record_versions').doc();
    batch.set(versionDoc, {
      ...version.toMap(),
      'id': versionDoc.id,
      'recordId': record.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deleteRecord(String id) async {
    // Delete main record
    await _firestore.collection('records').doc(id).delete();

    // Clean up corresponding versions
    final versions = await _firestore
        .collection('record_versions')
        .where('record_id', isEqualTo: id)
        .get();
    final batch = _firestore.batch();
    for (var doc in versions.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ==========================================
  // RECORD VERSIONS
  // ==========================================

  Future<String> addRecordVersion(RecordVersionModel version) async {
    final docRef = _firestore.collection('record_versions').doc();
    await docRef.set({
      ...version.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Future<List<RecordVersionModel>> fetchRecordVersions(String recordId) async {
    final snapshot = await _firestore
        .collection('record_versions')
        .where('record_id', isEqualTo: recordId)
        .get();
    final list = snapshot.docs.map((doc) => RecordVersionModel.fromFirestore(doc)).toList();
    list.sort((a, b) => (b.versionNumber).compareTo(a.versionNumber));
    return list;
  }

  // ==========================================
  // DELETION REQUESTS
  // ==========================================

  Stream<List<DeletionRequestModel>> getDeletionRequestsStream() {
    return _firestore.collection('deletion_requests').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => DeletionRequestModel.fromFirestore(doc)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Future<String> createDeletionRequest(DeletionRequestModel req) async {
    final docRef = _firestore.collection('deletion_requests').doc();
    await docRef.set({
      ...req.toMap(),
      'id': docRef.id,
    });
    return docRef.id;
  }

  Future<void> reviewDeletionRequest({
    required String requestId,
    required String recordId,
    required DeletionStatus status,
    required String reviewerId,
    required String reviewerName,
  }) async {
    await _firestore.collection('deletion_requests').doc(requestId).update({
      'status': status.toDbString(),
      'reviewed_by': reviewerId,
      'reviewer_name': reviewerName,
      'reviewed_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (status == DeletionStatus.approved) {
      // Approve implies hard deleting the record
      await deleteRecord(recordId);
    }
  }

  // ==========================================
  // USERS & PROFILES
  // ==========================================

  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<UserModel>> fetchUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Future<void> markNotificationAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> sendNotificationsToAdmins({
    required String title,
    required String message,
    String type = 'alert',
    String? relatedRecordId,
    String? relatedSchoolId,
  }) async {
    final admins = await _firestore
        .collection('users')
        .where('role', whereIn: ['admin', 'super_admin', 'staff_admin'])
        .get();

    final batch = _firestore.batch();
    for (var doc in admins.docs) {
      final notifRef = _firestore.collection('notifications').doc();
      final notif = NotificationModel(
        id: notifRef.id,
        userId: doc.id,
        title: title,
        message: message,
        type: type,
        relatedRecordId: relatedRecordId,
        relatedSchoolId: relatedSchoolId,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notif.toMap());
    }
    await batch.commit();
  }

  // ==========================================
  // SEED INITIAL DATABASE DATA
  // ==========================================

  Future<void> seedInitialDataIfEmpty() async {
    final fields = await _firestore.collection('form_fields').limit(1).get();
    if (fields.docs.isNotEmpty) return; // Already seeded

    final batch = _firestore.batch();

    // 1. Initial Schools
    final sampleSchools = [
      SchoolModel(
        id: 'school_kilifi_sec',
        name: 'Kilifi Township Secondary School',
        location: 'Kilifi County, Coast Region',
        type: 'Secondary',
        students: 680,
        motto: 'Excellence Through Discipline and Knowledge',
        principal: 'Dr. Joseph Mwangi',
        phone: '+254 712 345 678',
        email: 'info@kilifitownship.ac.ke',
        established: 1984,
        description: 'Pioneering educational excellence in the Coastal region with strong STEM focus.',
      ),
      SchoolModel(
        id: 'school_nairobi_acad',
        name: 'Nairobi Central Academy',
        location: 'Nairobi County, Central Region',
        type: 'Primary & Secondary',
        students: 1250,
        motto: 'Knowledge is Light',
        principal: 'Mrs. Grace Wanjiku',
        phone: '+254 722 987 654',
        email: 'admin@nairobicentral.ac.ke',
        established: 1978,
        description: 'Comprehensive institution offering inclusive education and modern digital learning resources.',
      ),
      SchoolModel(
        id: 'school_kisumu_day',
        name: 'Kisumu Day Secondary School',
        location: 'Kisumu County, Western Region',
        type: 'Secondary',
        students: 890,
        motto: 'Aspire and Achieve',
        principal: 'Mr. Peter Otieno',
        phone: '+254 733 456 789',
        email: 'contact@kisumuday.ac.ke',
        established: 1992,
        description: 'Vibrant school renowned for leadership, academic performance and athletics.',
      ),
    ];

    for (var school in sampleSchools) {
      final docRef = _firestore.collection('schools').doc(school.id);
      batch.set(docRef, {
        ...school.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Default Form Fields (Weekly, Termly, Annually, Special)
    final defaultFields = [
      // Weekly
      FormFieldModel(
        id: 'field_w_1',
        formType: FormType.weekly,
        label: 'Student Attendance Headcount',
        fieldType: CustomFieldType.number,
        required: true,
        placeholder: 'Total students present this week',
        fieldOrder: 1,
        minValue: 0,
        maxValue: 5000,
      ),
      FormFieldModel(
        id: 'field_w_2',
        formType: FormType.weekly,
        label: 'Staff Attendance Rate',
        fieldType: CustomFieldType.percentage,
        required: true,
        placeholder: 'Percentage of staff present',
        fieldOrder: 2,
        minValue: 0,
        maxValue: 100,
      ),
      FormFieldModel(
        id: 'field_w_3',
        formType: FormType.weekly,
        label: 'Feeding Program Operational',
        fieldType: CustomFieldType.boolean,
        required: false,
        placeholder: '',
        fieldOrder: 3,
      ),
      FormFieldModel(
        id: 'field_w_4',
        formType: FormType.weekly,
        label: 'Weekly Challenges & Incidents',
        fieldType: CustomFieldType.textarea,
        required: false,
        placeholder: 'Note any sanitation, health, or academic issues...',
        fieldOrder: 4,
      ),

      // Termly
      FormFieldModel(
        id: 'field_t_1',
        formType: FormType.termly,
        label: 'Term Examination Mean Score',
        fieldType: CustomFieldType.number,
        required: true,
        placeholder: 'Mean grade points out of 100',
        fieldOrder: 1,
        minValue: 0,
        maxValue: 100,
      ),
      FormFieldModel(
        id: 'field_t_2',
        formType: FormType.termly,
        label: 'Curriculum Coverage Status',
        fieldType: CustomFieldType.select,
        required: true,
        options: ['Ahead of Schedule', 'On Schedule', 'Slightly Behind', 'Significantly Delayed'],
        fieldOrder: 2,
      ),
      FormFieldModel(
        id: 'field_t_3',
        formType: FormType.termly,
        label: 'Infrastructure Maintenance Needed',
        fieldType: CustomFieldType.boolean,
        required: false,
        fieldOrder: 3,
      ),
      FormFieldModel(
        id: 'field_t_4',
        formType: FormType.termly,
        label: 'Principal Term Summary',
        fieldType: CustomFieldType.textarea,
        required: true,
        placeholder: 'Summary of achievements, challenges and next term goals...',
        fieldOrder: 4,
      ),

      // Annually
      FormFieldModel(
        id: 'field_a_1',
        formType: FormType.annually,
        label: 'National Exam Pass Rate',
        fieldType: CustomFieldType.percentage,
        required: true,
        placeholder: 'Percentage transition to tertiary',
        fieldOrder: 1,
        minValue: 0,
        maxValue: 100,
      ),
      FormFieldModel(
        id: 'field_a_2',
        formType: FormType.annually,
        label: 'Total Annual Enrollment',
        fieldType: CustomFieldType.number,
        required: true,
        placeholder: 'Total enrolled students',
        fieldOrder: 2,
        minValue: 1,
      ),
      FormFieldModel(
        id: 'field_a_3',
        formType: FormType.annually,
        label: 'Government Capitation Received',
        fieldType: CustomFieldType.boolean,
        required: true,
        fieldOrder: 3,
      ),
      FormFieldModel(
        id: 'field_a_4',
        formType: FormType.annually,
        label: 'Annual Development Plan Report',
        fieldType: CustomFieldType.textarea,
        required: false,
        placeholder: 'Overview of capital projects, laboratory updates, library...',
        fieldOrder: 4,
      ),

      // Special
      FormFieldModel(
        id: 'field_s_1',
        formType: FormType.special,
        label: 'Event / Incident Category',
        fieldType: CustomFieldType.select,
        required: true,
        options: ['Disaster / Weather', 'Medical Outbreak', 'Inspection Audit', 'VIP Visit', 'Sports Tournament', 'Other'],
        fieldOrder: 1,
      ),
      FormFieldModel(
        id: 'field_s_2',
        formType: FormType.special,
        label: 'Immediate Action Required',
        fieldType: CustomFieldType.boolean,
        required: true,
        fieldOrder: 2,
      ),
      FormFieldModel(
        id: 'field_s_3',
        formType: FormType.special,
        label: 'Detailed Report & Recommendations',
        fieldType: CustomFieldType.textarea,
        required: true,
        placeholder: 'Detailed narrative of the event and recommended interventions...',
        fieldOrder: 3,
      ),
    ];

    for (var f in defaultFields) {
      final docRef = _firestore.collection('form_fields').doc(f.id);
      batch.set(docRef, {
        ...f.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
