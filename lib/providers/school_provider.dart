import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/school_model.dart';
import '../models/form_field_model.dart';
import '../models/record_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class RecordTypeChange {
  final FormType formType;
  final List<String> added;
  final List<String> removed;
  final List<String> affectedRecordIds;

  RecordTypeChange({
    required this.formType,
    required this.added,
    required this.removed,
    required this.affectedRecordIds,
  });
}

class SchoolProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final _uuid = const Uuid();

  List<SchoolModel> _schools = [];
  SchoolModel? _activeSchool;
  List<RecordModel> _records = [];
  List<FormFieldModel> _formFields = [];
  List<NotificationModel> _notifications = [];
  bool _isOnline = true;
  bool _isLoading = true;

  List<RecordTypeChange> _recordTypeChanges = [];
  final Map<String, String> _pendingFieldAlert = {};

  List<SchoolModel> get schools => _schools;
  SchoolModel? get activeSchool => _activeSchool;
  List<RecordModel> get records => _records;
  List<FormFieldModel> get formFields => _formFields;
  List<NotificationModel> get notifications => _notifications;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  int get pendingSyncCount => _records.where((r) => !r.synced || r.isOffline).length;
  List<RecordTypeChange> get recordTypeChanges => _recordTypeChanges;
  Map<String, String> get pendingFieldAlert => _pendingFieldAlert;

  // Local storage keys
  static const String _lsOffline = 'africascene_offline_records';
  static const String _lsSynced = 'africascene_synced_records';
  static const String _lsFields = 'africascene_cached_fields';
  static const String _lsSchools = 'africascene_cached_schools';
  static const String _lsActiveSchool = 'africascene_active_school_id';

  Future<void> init(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    // 1. Synchronously load offline caches for instant UI display
    await _loadFromLocalStorage();

    // 2. Fetch fresh data from Firestore
    await refreshData(user);

    // 3. Listen to Firestore real-time streams
    _listenToStreams(user);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load schools cache
    final schoolsJson = prefs.getString(_lsSchools);
    if (schoolsJson != null) {
      try {
        final List list = jsonDecode(schoolsJson);
        _schools = list.map((e) => SchoolModel.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    // Load active school
    final activeSchoolId = prefs.getString(_lsActiveSchool);
    if (activeSchoolId != null && _schools.isNotEmpty) {
      _activeSchool = _schools.firstWhere((s) => s.id == activeSchoolId, orElse: () => _schools.first);
    } else if (_schools.isNotEmpty) {
      _activeSchool = _schools.first;
    }

    // Load cached form fields
    final fieldsJson = prefs.getString(_lsFields);
    if (fieldsJson != null) {
      try {
        final List list = jsonDecode(fieldsJson);
        _formFields = list.map((e) => FormFieldModel.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    // Load cached records
    final offlineJson = prefs.getString(_lsOffline);
    final syncedJson = prefs.getString(_lsSynced);
    List<RecordModel> offline = [];
    List<RecordModel> synced = [];

    if (offlineJson != null) {
      try {
        final List list = jsonDecode(offlineJson);
        offline = list.map((e) => RecordModel.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }
    if (syncedJson != null) {
      try {
        final List list = jsonDecode(syncedJson);
        synced = list.map((e) => RecordModel.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    _records = _dedupeRecords([...offline, ...synced]);
    _checkSchemaDrift();
  }

  void _listenToStreams(UserModel user) {
    // Listen to form fields changes
    _firestoreService.getFormFieldsStream().listen((fields) {
      _formFields = fields;
      _cacheFormFields(fields);
      _checkSchemaDrift();
      notifyListeners();
    });

    // Listen to notifications
    _firestoreService.getUserNotificationsStream(user.id).listen((notifs) {
      _notifications = notifs;
      notifyListeners();
    });
  }

  Future<void> refreshData(UserModel user) async {
    try {
      // 1. Fetch assigned schools
      List<SchoolModel> fetchedSchools = [];
      if (user.schoolIds.isNotEmpty) {
        fetchedSchools = await _firestoreService.fetchSchoolsByIds(user.schoolIds);
      } else {
        fetchedSchools = await _firestoreService.fetchSchools();
      }

      if (fetchedSchools.isNotEmpty) {
        _schools = fetchedSchools;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lsSchools, jsonEncode(_schools.map((s) => s.toLocalJson()).toList()));

        if (_activeSchool == null || !_schools.any((s) => s.id == _activeSchool!.id)) {
          _activeSchool = _schools.first;
          await prefs.setString(_lsActiveSchool, _activeSchool!.id);
        }
      }

      // 2. Fetch Form Fields
      final fields = await _firestoreService.fetchFormFields();
      if (fields.isNotEmpty) {
        _formFields = fields;
        await _cacheFormFields(fields);
      }

      // 3. Fetch Synced Records for this user
      final serverRecords = await _firestoreService.fetchRecords(
        submittedById: user.isAdmin ? null : user.id,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lsSynced, jsonEncode(serverRecords.map((r) => r.toLocalJson()).toList()));

      // Clean offline cache
      final offlineJson = prefs.getString(_lsOffline);
      List<RecordModel> offline = [];
      if (offlineJson != null) {
        final List list = jsonDecode(offlineJson);
        final serverIds = serverRecords.map((r) => r.id).toSet();
        offline = list
            .map((e) => RecordModel.fromMap(Map<String, dynamic>.from(e)))
            .where((r) => !serverIds.contains(r.id))
            .toList();
        await prefs.setString(_lsOffline, jsonEncode(offline.map((r) => r.toLocalJson()).toList()));
      }

      _records = _dedupeRecords([...offline, ...serverRecords]);
      _checkSchemaDrift();
      _isOnline = true;
    } catch (e) {
      debugPrint('Error refreshing school data: $e');
      _isOnline = false;
    }
    notifyListeners();
  }

  void setActiveSchool(SchoolModel school) async {
    _activeSchool = school;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lsActiveSchool, school.id);
    notifyListeners();
  }

  List<FormFieldModel> getFieldsByType(FormType type) {
    return _formFields.where((f) => f.formType == type).toList()
      ..sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));
  }

  List<RecordModel> getRecordsByType(FormType type) {
    if (_activeSchool == null) return [];
    return _records
        .where((r) => r.schoolId == _activeSchool!.id && r.formType == type)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  }

  Future<void> addRecord({
    required FormType formType,
    required Map<String, dynamic> data,
    required UserModel user,
    String? title,
  }) async {
    if (_activeSchool == null) return;

    final snapshot = getFieldsByType(formType).map((f) => f.toMap()).toList();
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 6)}';

    final newRecord = RecordModel(
      id: localId,
      schoolId: _activeSchool!.id,
      formType: formType,
      submittedBy: user.name,
      submittedById: user.id,
      data: data,
      synced: false,
      isOffline: true,
      formFieldsSnapshot: snapshot,
      versionNumber: 1,
      createdAt: DateTime.now(),
    );

    if (_isOnline) {
      try {
        final serverDocId = await _firestoreService.createRecord(newRecord);
        final syncedRecord = newRecord.copyWith(
          id: serverDocId,
          synced: true,
          isOffline: false,
        );

        _records = _dedupeRecords([syncedRecord, ..._records]);
        _saveToLocalStorage();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Failed to save to server, falling back to offline cache: $e');
      }
    }

    // Save offline
    _records = _dedupeRecords([newRecord, ..._records]);
    await _saveToLocalStorage();
    notifyListeners();
  }

  Future<void> updateRecord(RecordModel record, RecordVersionModel version) async {
    if (_isOnline && !record.isOffline) {
      try {
        await _firestoreService.updateRecordWithVersion(record, version);
      } catch (e) {
        debugPrint('Failed to update on server: $e');
      }
    }

    _records = _records.map((r) => r.id == record.id ? record : r).toList();
    await _saveToLocalStorage();
    notifyListeners();
  }

  Future<int> syncRecords(UserModel user) async {
    if (!_isOnline) return 0;

    final prefs = await SharedPreferences.getInstance();
    final offlineJson = prefs.getString(_lsOffline);
    if (offlineJson == null) return 0;

    List<RecordModel> offline = [];
    try {
      final List list = jsonDecode(offlineJson);
      offline = list.map((e) => RecordModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return 0;
    }

    if (offline.isEmpty) return 0;

    int syncedCount = 0;
    List<RecordModel> remainingFailed = [];

    for (var rec in offline) {
      // Check for schema drift on this record type
      final currentFields = getFieldsByType(rec.formType);
      final snapshotLabels = rec.formFieldsSnapshot.map((s) => s['label'].toString()).toSet();
      final currentLabels = currentFields.map((f) => f.label).toSet();

      final added = currentLabels.difference(snapshotLabels);
      final removed = snapshotLabels.difference(currentLabels);

      if (added.isNotEmpty || removed.isNotEmpty) {
        // Schema mismatch! Block syncing until user updates record
        remainingFailed.add(rec);
        continue;
      }

      try {
        final docId = await _firestoreService.createRecord(rec);
        final synced = rec.copyWith(id: docId, synced: true, isOffline: false);
        _records = _dedupeRecords([synced, ..._records.where((r) => r.id != rec.id)]);
        syncedCount++;
      } catch (e) {
        remainingFailed.add(rec);
      }
    }

    await prefs.setString(_lsOffline, jsonEncode(remainingFailed.map((r) => r.toLocalJson()).toList()));
    final syncedOnly = _records.where((r) => r.synced && !r.isOffline).toList();
    await prefs.setString(_lsSynced, jsonEncode(syncedOnly.map((r) => r.toLocalJson()).toList()));

    _checkSchemaDrift();
    notifyListeners();
    return syncedCount;
  }

  void _checkSchemaDrift() {
    if (_formFields.isEmpty || _records.isEmpty) {
      _recordTypeChanges = [];
      return;
    }

    final Map<FormType, RecordTypeChange> changes = {};

    for (var rec in _records) {
      if (rec.formFieldsSnapshot.isEmpty) continue;
      final currentFields = getFieldsByType(rec.formType);
      final currentLabels = currentFields.map((f) => f.label).toSet();
      final snapLabels = rec.formFieldsSnapshot.map((s) => s['label'].toString()).toSet();

      final added = currentLabels.difference(snapLabels).toList();
      final removed = snapLabels.difference(currentLabels).toList();

      if (added.isEmpty && removed.isEmpty) continue;

      if (changes.containsKey(rec.formType)) {
        changes[rec.formType]!.affectedRecordIds.add(rec.id);
      } else {
        changes[rec.formType] = RecordTypeChange(
          formType: rec.formType,
          added: added,
          removed: removed,
          affectedRecordIds: [rec.id],
        );
      }
    }

    _recordTypeChanges = changes.values.toList();
  }

  void acknowledgeRecordTypeChange(FormType formType) {
    _recordTypeChanges.removeWhere((c) => c.formType == formType);
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await _firestoreService.markNotificationAsRead(id);
    _notifications = _notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList();
    notifyListeners();
  }

  Future<void> _cacheFormFields(List<FormFieldModel> fields) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lsFields, jsonEncode(fields.map((f) => f.toLocalJson()).toList()));
  }

  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final offline = _records.where((r) => !r.synced || r.isOffline).toList();
    final synced = _records.where((r) => r.synced && !r.isOffline).toList();
    await prefs.setString(_lsOffline, jsonEncode(offline.map((r) => r.toLocalJson()).toList()));
    await prefs.setString(_lsSynced, jsonEncode(synced.map((r) => r.toLocalJson()).toList()));
  }

  List<RecordModel> _dedupeRecords(List<RecordModel> list) {
    final Map<String, RecordModel> map = {};
    for (var r in list) {
      if (map.containsKey(r.id)) {
        // prefer synced over unsynced duplicate
        if (!map[r.id]!.synced && r.synced) {
          map[r.id] = r;
        }
      } else {
        map[r.id] = r;
      }
    }
    return map.values.toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  }
}
