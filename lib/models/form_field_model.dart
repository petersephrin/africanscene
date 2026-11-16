import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'school_model.dart';
import 'user_model.dart';

enum FormType {
  weekly,
  termly,
  annually,
  special,
  krcLibraryWeekly,
  krcHolidayWeekly,
  krcItClassesWeekly,
  krcWeekly,
  krcTermly,
  krcAnnually,
  recWeekly,
  recTermly,
  recAnnually;

  static FormType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'weekly':
        return FormType.weekly;
      case 'termly':
        return FormType.termly;
      case 'annually':
        return FormType.annually;
      case 'krc_library_weekly':
      case 'krclibraryweekly':
      case 'krc library weekly':
        return FormType.krcLibraryWeekly;
      case 'krc_holiday_weekly':
      case 'krcholidayweekly':
      case 'krc holiday weekly':
        return FormType.krcHolidayWeekly;
      case 'krc_it_classes_weekly':
      case 'krcitclassesweekly':
      case 'krc it classes weekly':
        return FormType.krcItClassesWeekly;
      case 'krc_weekly':
      case 'krcweekly':
      case 'krc weekly':
      case 'kidogo_weekly':
      case 'kidogoweekly':
      case 'kidogo weekly':
        return FormType.krcWeekly;
      case 'krc_termly':
      case 'krctermly':
      case 'krc termly':
      case 'kidogo_termly':
      case 'kidogotermly':
      case 'kidogo termly':
        return FormType.krcTermly;
      case 'krc_annually':
      case 'krcannually':
      case 'krc annually':
      case 'kidogo_annually':
      case 'kidogoannually':
      case 'kidogo annually':
        return FormType.krcAnnually;
      case 'rec_weekly':
      case 'recweekly':
      case 'rec weekly':
        return FormType.recWeekly;
      case 'rec_termly':
      case 'rectermly':
      case 'rec termly':
        return FormType.recTermly;
      case 'rec_annually':
      case 'recannually':
      case 'rec annually':
        return FormType.recAnnually;
      case 'special':
      default:
        return FormType.special;
    }
  }

  String toDbString() {
    switch (this) {
      case FormType.weekly:
        return 'weekly';
      case FormType.termly:
        return 'termly';
      case FormType.annually:
        return 'annually';
      case FormType.special:
        return 'special';
      case FormType.krcLibraryWeekly:
        return 'krc_library_weekly';
      case FormType.krcHolidayWeekly:
        return 'krc_holiday_weekly';
      case FormType.krcItClassesWeekly:
        return 'krc_it_classes_weekly';
      case FormType.krcWeekly:
        return 'krc_weekly';
      case FormType.krcTermly:
        return 'krc_termly';
      case FormType.krcAnnually:
        return 'krc_annually';
      case FormType.recWeekly:
        return 'rec_weekly';
      case FormType.recTermly:
        return 'rec_termly';
      case FormType.recAnnually:
        return 'rec_annually';
    }
  }

  String get displayName {
    switch (this) {
      case FormType.weekly:
        return 'Weekly';
      case FormType.termly:
        return 'Termly';
      case FormType.annually:
        return 'Annually';
      case FormType.special:
        return 'Special';
      case FormType.krcLibraryWeekly:
        return 'KRC Library Weekly';
      case FormType.krcHolidayWeekly:
        return 'KRC Holiday Weekly';
      case FormType.krcItClassesWeekly:
        return 'KRC IT Classes Weekly';
      case FormType.krcWeekly:
        return 'Kidogo Weekly';
      case FormType.krcTermly:
        return 'Kidogo Termly';
      case FormType.krcAnnually:
        return 'Kidogo Annually';
      case FormType.recWeekly:
        return 'REC Weekly';
      case FormType.recTermly:
        return 'REC Termly';
      case FormType.recAnnually:
        return 'REC Annually';
    }
  }

  String get description {
    switch (this) {
      case FormType.weekly:
        return 'Weekly observations & data';
      case FormType.termly:
        return 'End of term summaries';
      case FormType.annually:
        return 'Annual research findings';
      case FormType.special:
        return 'Special events & notes';
      case FormType.krcLibraryWeekly:
        return 'KRC library weekly records';
      case FormType.krcHolidayWeekly:
        return 'KRC holiday program weekly records';
      case FormType.krcItClassesWeekly:
        return 'KRC IT classes weekly records';
      case FormType.krcWeekly:
        return 'Kidogo weekly observations';
      case FormType.krcTermly:
        return 'Kidogo end of term summaries';
      case FormType.krcAnnually:
        return 'Kidogo annual findings';
      case FormType.recWeekly:
        return 'Raila weekly observations';
      case FormType.recTermly:
        return 'Raila end of term summaries';
      case FormType.recAnnually:
        return 'Raila annual findings';
    }
  }

  IconData get icon {
    switch (this) {
      case FormType.weekly:
        return Icons.calendar_today_outlined;
      case FormType.termly:
        return Icons.menu_book_outlined;
      case FormType.annually:
        return Icons.school_outlined;
      case FormType.special:
        return Icons.star_outline;
      case FormType.krcLibraryWeekly:
        return Icons.local_library_outlined;
      case FormType.krcHolidayWeekly:
        return Icons.wb_sunny_outlined;
      case FormType.krcItClassesWeekly:
        return Icons.computer_outlined;
      case FormType.krcWeekly:
        return Icons.calendar_month_outlined;
      case FormType.krcTermly:
        return Icons.menu_book_rounded;
      case FormType.krcAnnually:
        return Icons.account_balance_outlined;
      case FormType.recWeekly:
        return Icons.date_range_outlined;
      case FormType.recTermly:
        return Icons.library_books_outlined;
      case FormType.recAnnually:
        return Icons.domain_outlined;
    }
  }

  Color get color {
    switch (this) {
      case FormType.weekly:
        return AppTheme.primaryColor;
      case FormType.termly:
        return AppTheme.accentColor;
      case FormType.annually:
        return const Color(0xFF8B5CF6);
      case FormType.special:
        return const Color(0xFFF59E0B);
      case FormType.krcLibraryWeekly:
        return const Color(0xFF14B8A6);
      case FormType.krcHolidayWeekly:
        return const Color(0xFF0EA5E9);
      case FormType.krcItClassesWeekly:
        return const Color(0xFF3B82F6);
      case FormType.krcWeekly:
        return const Color(0xFF10B981);
      case FormType.krcTermly:
        return const Color(0xFF0D9488);
      case FormType.krcAnnually:
        return const Color(0xFF059669);
      case FormType.recWeekly:
        return const Color(0xFF6366F1);
      case FormType.recTermly:
        return const Color(0xFF4F46E5);
      case FormType.recAnnually:
        return const Color(0xFF4338CA);
    }
  }

  bool get isKrc =>
      this == FormType.krcLibraryWeekly ||
      this == FormType.krcHolidayWeekly ||
      this == FormType.krcItClassesWeekly ||
      this == FormType.krcWeekly ||
      this == FormType.krcTermly ||
      this == FormType.krcAnnually;

  bool get isRec =>
      this == FormType.recWeekly ||
      this == FormType.recTermly ||
      this == FormType.recAnnually;

  bool get isStandard =>
      this == FormType.weekly ||
      this == FormType.termly ||
      this == FormType.annually;

  bool get isSchoolSpecific => isKrc || isRec;

  /// Check if this form type is visible given the active school
  bool isVisibleForSchool(SchoolModel? school) {
    if (isKrc) return school?.isKrc == true;
    if (isRec) return school?.isRec == true;
    if (isStandard) return school == null || (!school.isKrc && !school.isRec);
    return true; // Special is visible to everyone
  }

  /// Get list of visible form types for a researcher/teacher or school context
  static List<FormType> getVisibleTypes({
    SchoolModel? school,
    UserModel? user,
    List<SchoolModel> allSchools = const [],
  }) {
    // Super admins and platform admins see everything
    if (user != null && user.isAdmin) {
      return FormType.values;
    }

    const krcTypes = <FormType>[
      FormType.krcLibraryWeekly,
      FormType.krcHolidayWeekly,
      FormType.krcItClassesWeekly,
      FormType.krcWeekly,
      FormType.krcTermly,
      FormType.krcAnnually,
      FormType.special,
    ];

    const recTypes = <FormType>[
      FormType.recWeekly,
      FormType.recTermly,
      FormType.recAnnually,
      FormType.special,
    ];

    const otherSchoolTypes = <FormType>[
      FormType.weekly,
      FormType.termly,
      FormType.annually,
      FormType.special,
    ];

    final knownSchools = <SchoolModel>[
      ?school,
      ...allSchools,
    ];

    final isKrcUser = user != null && user.isAffiliatedWithKrc(knownSchools);
    final isRecUser = user != null && user.isAffiliatedWithRec(knownSchools);

    if (school != null) {
      if (school.isKrc && (user == null || isKrcUser)) {
        return List<FormType>.from(krcTypes);
      }
      if (school.isRec && (user == null || isRecUser)) {
        return List<FormType>.from(recTypes);
      }
      if (!school.isKrc &&
          !school.isRec &&
          (user == null || user.schoolIds.contains(school.id))) {
        return List<FormType>.from(otherSchoolTypes);
      }
    }

    if (isKrcUser && !isRecUser) {
      return List<FormType>.from(krcTypes);
    }
    if (isRecUser && !isKrcUser) {
      return List<FormType>.from(recTypes);
    }
    if (isKrcUser && isRecUser) {
      return <FormType>[
        FormType.krcLibraryWeekly,
        FormType.krcHolidayWeekly,
        FormType.krcItClassesWeekly,
        FormType.krcWeekly,
        FormType.krcTermly,
        FormType.krcAnnually,
        FormType.recWeekly,
        FormType.recTermly,
        FormType.recAnnually,
        FormType.special,
      ];
    }

    return List<FormType>.from(otherSchoolTypes);
  }
}

enum CustomFieldType {
  text,
  number,
  percentage,
  select,
  textarea,
  boolean;

  static CustomFieldType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'number':
        return CustomFieldType.number;
      case 'percentage':
        return CustomFieldType.percentage;
      case 'select':
        return CustomFieldType.select;
      case 'textarea':
        return CustomFieldType.textarea;
      case 'boolean':
      case 'switch':
        return CustomFieldType.boolean;
      case 'text':
      default:
        return CustomFieldType.text;
    }
  }

  String toDbString() {
    switch (this) {
      case CustomFieldType.text:
        return 'text';
      case CustomFieldType.number:
        return 'number';
      case CustomFieldType.percentage:
        return 'percentage';
      case CustomFieldType.select:
        return 'select';
      case CustomFieldType.textarea:
        return 'textarea';
      case CustomFieldType.boolean:
        return 'boolean';
    }
  }

  String get displayName {
    switch (this) {
      case CustomFieldType.text:
        return 'Text Input';
      case CustomFieldType.number:
        return 'Number';
      case CustomFieldType.percentage:
        return 'Percentage (%)';
      case CustomFieldType.select:
        return 'Select Dropdown';
      case CustomFieldType.textarea:
        return 'Text Area';
      case CustomFieldType.boolean:
        return 'Yes / No Switch';
    }
  }
}

class FormFieldModel {
  final String id;
  final FormType formType;
  final String label;
  final CustomFieldType fieldType;
  final bool required;
  final String? placeholder;
  final List<String> options;
  final int fieldOrder;
  final num? minValue;
  final num? maxValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FormFieldModel({
    required this.id,
    required this.formType,
    required this.label,
    required this.fieldType,
    this.required = false,
    this.placeholder,
    this.options = const [],
    required this.fieldOrder,
    this.minValue,
    this.maxValue,
    this.createdAt,
    this.updatedAt,
  });

  factory FormFieldModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FormFieldModel.fromMap(data, doc.id);
  }

  factory FormFieldModel.fromMap(Map<String, dynamic> data, [String? docId]) {
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

    num? parseNullableNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val;
      return num.tryParse(val.toString());
    }

    final rawOptions = data['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else if (rawOptions is String && rawOptions.isNotEmpty) {
      parsedOptions = rawOptions.split(',').map((e) => e.trim()).toList();
    }

    return FormFieldModel(
      id: docId ?? (data['_id'] ?? data['id'] ?? '').toString(),
      formType: FormType.fromString((data['form_type'] ?? data['formType'])?.toString()),
      label: (data['label'] ?? 'Field').toString(),
      fieldType: CustomFieldType.fromString((data['field_type'] ?? data['fieldType'])?.toString()),
      required: data['required'] == true,
      placeholder: data['placeholder']?.toString(),
      options: parsedOptions,
      fieldOrder: parseNum(data['field_order'] ?? data['fieldOrder'], 1),
      minValue: parseNullableNum(data['min_value'] ?? data['minValue']),
      maxValue: parseNullableNum(data['max_value'] ?? data['maxValue']),
      createdAt: parseDate(data['createdAt'] ?? data['created_at']),
      updatedAt: parseDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'form_type': formType.toDbString(),
      'label': label,
      'field_type': fieldType.toDbString(),
      'required': required,
      'placeholder': placeholder,
      'options': options,
      'field_order': fieldOrder,
      'min_value': minValue,
      'max_value': maxValue,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      '_id': id,
      'form_type': formType.toDbString(),
      'formType': formType.toDbString(),
      'label': label,
      'field_type': fieldType.toDbString(),
      'fieldType': fieldType.toDbString(),
      'required': required,
      'placeholder': placeholder,
      'options': options,
      'field_order': fieldOrder,
      'fieldOrder': fieldOrder,
      'min_value': minValue,
      'minValue': minValue,
      'max_value': maxValue,
      'maxValue': maxValue,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toLocalJson();

  FormFieldModel copyWith({
    FormType? formType,
    String? label,
    CustomFieldType? fieldType,
    bool? required,
    String? placeholder,
    List<String>? options,
    int? fieldOrder,
    num? minValue,
    num? maxValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormFieldModel(
      id: id,
      formType: formType ?? this.formType,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      required: required ?? this.required,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? this.options,
      fieldOrder: fieldOrder ?? this.fieldOrder,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
