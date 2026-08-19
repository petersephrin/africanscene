import 'package:flutter/foundation.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';
import '../models/form_field_model.dart';
import '../models/record_model.dart';
import '../models/deletion_request_model.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class AdminDataProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  List<SchoolModel> _schools = [];
  List<UserModel> _users = [];
  List<FormFieldModel> _formFields = [];
  List<RecordModel> _records = [];
  List<DeletionRequestModel> _deletionRequests = [];
  bool _isLoading = true;

  List<SchoolModel> get schools => _schools;
  List<UserModel> get users => _users;
  List<FormFieldModel> get formFields => _formFields;
  List<RecordModel> get records => _records;
  List<DeletionRequestModel> get deletionRequests => _deletionRequests;
  bool get isLoading => _isLoading;

  List<UserModel> get researchers =>
      _users.where((u) => u.role == UserRole.researcher || u.userType == 'researcher').toList();

  List<UserModel> get teachers =>
      _users.where((u) => u.role == UserRole.teacher || u.userType == 'teacher').toList();

  List<UserModel> get staff => _users
      .where((u) =>
          u.role == UserRole.staff ||
          u.role == UserRole.staffAdmin ||
          u.role == UserRole.superAdmin ||
          u.role == UserRole.admin ||
          u.userType == 'staff' ||
          u.userType == 'admin')
      .toList();

  AdminDataProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to real-time collections
    _firestoreService.getSchoolsStream().listen((schools) {
      _schools = schools;
      notifyListeners();
    });

    _firestoreService.getUsersStream().listen((users) {
      _users = users;
      notifyListeners();
    });

    _firestoreService.getFormFieldsStream().listen((fields) {
      _formFields = fields;
      notifyListeners();
    });

    _firestoreService.getRecordsStream().listen((recs) {
      _records = recs;
      notifyListeners();
    });

    _firestoreService.getDeletionRequestsStream().listen((reqs) {
      _deletionRequests = reqs;
      notifyListeners();
    });

    await refreshData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    try {
      final results = await Future.wait([
        _firestoreService.fetchSchools(),
        _firestoreService.fetchUsers(),
        _firestoreService.fetchFormFields(),
        _firestoreService.fetchRecords(),
      ]);

      _schools = results[0] as List<SchoolModel>;
      _users = results[1] as List<UserModel>;
      _formFields = results[2] as List<FormFieldModel>;
      _records = results[3] as List<RecordModel>;
    } catch (e) {
      debugPrint('AdminDataProvider refreshData error: $e');
    }
    notifyListeners();
  }

  // ==========================================
  // SCHOOLS CRUD
  // ==========================================

  Future<void> addSchool(SchoolModel school) async {
    await _firestoreService.addSchool(school);
  }

  Future<void> updateSchool(String id, Map<String, dynamic> updates) async {
    await _firestoreService.updateSchool(id, updates);
  }

  Future<void> deleteSchool(String id) async {
    await _firestoreService.deleteSchool(id);
  }

  // ==========================================
  // USERS CRUD (Researchers, Teachers, Staff)
  // ==========================================

  Future<void> addResearcher({
    required String name,
    required String email,
    required String phone,
    required String specialization,
    required List<String> schoolIds,
    required String password,
  }) async {
    final parts = name.trim().split(' ');
    final fName = parts.first;
    final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    await _authService.createUserByAdmin(
      email: email,
      password: password,
      firstName: fName,
      lastName: lName,
      role: UserRole.researcher,
      userType: 'researcher',
      phone: phone,
      specialization: specialization,
      schoolIds: schoolIds,
    );
  }

  Future<void> updateResearcher(String userId, {
    String? name,
    String? phone,
    String? specialization,
    List<String>? schoolIds,
    String? role,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      final parts = name.trim().split(' ');
      updates['first_name'] = parts.first;
      updates['last_name'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      updates['name'] = name;
    }
    if (phone != null) updates['phone'] = phone;
    if (specialization != null) updates['specialization'] = specialization;
    if (schoolIds != null) updates['schoolIds'] = schoolIds;
    if (role != null) {
      updates['role'] = role;
      updates['user_type'] = (role.contains('admin') || role == 'staff')
          ? (role.contains('admin') ? 'admin' : 'staff')
          : (role == 'teacher' ? 'teacher' : 'researcher');
    }

    await _firestoreService.updateUser(userId, updates);
  }

  Future<void> addTeacher({
    required String name,
    required String email,
    required String phone,
    required String specialization,
    required List<String> schoolIds,
    required String password,
  }) async {
    final parts = name.trim().split(' ');
    final fName = parts.first;
    final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    await _authService.createUserByAdmin(
      email: email,
      password: password,
      firstName: fName,
      lastName: lName,
      role: UserRole.teacher,
      userType: 'teacher',
      phone: phone,
      specialization: specialization,
      schoolIds: schoolIds,
    );
  }

  Future<void> updateTeacher(String userId, {
    String? name,
    String? phone,
    String? specialization,
    List<String>? schoolIds,
    String? role,
  }) async {
    await updateResearcher(userId, name: name, phone: phone, specialization: specialization, schoolIds: schoolIds, role: role);
  }

  Future<void> addStaff({
    required String name,
    required String email,
    required String role,
    required String department,
    required String phone,
    required String password,
  }) async {
    final parts = name.trim().split(' ');
    final fName = parts.first;
    final lName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    await _authService.createUserByAdmin(
      email: email,
      password: password,
      firstName: fName,
      lastName: lName,
      role: UserRole.fromString(role),
      userType: role.contains('admin') ? 'admin' : 'staff',
      phone: phone,
      department: department,
    );
  }

  Future<void> updateStaff(String userId, {
    String? name,
    String? phone,
    String? department,
    String? role,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      final parts = name.trim().split(' ');
      updates['first_name'] = parts.first;
      updates['last_name'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      updates['name'] = name;
    }
    if (phone != null) updates['phone'] = phone;
    if (department != null) updates['department'] = department;
    if (role != null) {
      updates['role'] = role;
      updates['user_type'] = (role.contains('admin') || role == 'staff')
          ? (role.contains('admin') ? 'admin' : 'staff')
          : (role == 'teacher' ? 'teacher' : 'researcher');
    }

    await _firestoreService.updateUser(userId, updates);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestoreService.updateUser(userId, {
      'role': role,
      'user_type': (role.contains('admin') || role == 'staff')
          ? (role.contains('admin') ? 'admin' : 'staff')
          : (role == 'teacher' ? 'teacher' : 'researcher'),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestoreService.deleteUser(userId);
  }

  // ==========================================
  // DYNAMIC FORM FIELDS CRUD
  // ==========================================

  List<FormFieldModel> getFieldsByType(FormType type) {
    return _formFields.where((f) => f.formType == type).toList()
      ..sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));
  }

  Future<void> addFormField(FormFieldModel field) async {
    await _firestoreService.addFormField(field);
  }

  Future<void> updateFormField(String id, Map<String, dynamic> updates) async {
    await _firestoreService.updateFormField(id, updates);
  }

  Future<void> deleteFormField(String id, FormType formType) async {
    await _firestoreService.deleteFormField(id, formType);
  }

  Future<void> reorderFormFields(FormType formType, List<String> orderedIds) async {
    await _firestoreService.reorderFormFields(formType, orderedIds);
  }

  // ==========================================
  // RECORDS & DELETIONS
  // ==========================================

  Future<void> deleteRecord(String recordId) async {
    await _firestoreService.deleteRecord(recordId);
  }

  Future<List<RecordVersionModel>> fetchRecordVersions(String recordId) async {
    return await _firestoreService.fetchRecordVersions(recordId);
  }

  Future<void> reviewDeletionRequest({
    required String requestId,
    required String recordId,
    required DeletionStatus status,
    required UserModel reviewer,
  }) async {
    await _firestoreService.reviewDeletionRequest(
      requestId: requestId,
      recordId: recordId,
      status: status,
      reviewerId: reviewer.id,
      reviewerName: reviewer.name,
    );
  }

  Future<void> seedInitialDataIfEmpty() async {
    _isLoading = true;
    notifyListeners();
    await _firestoreService.seedInitialDataIfEmpty();
    await refreshData();
    _isLoading = false;
    notifyListeners();
  }
}
