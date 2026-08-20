import 'package:cloud_firestore/cloud_firestore.dart';

enum FormType {
  weekly,
  termly,
  annually,
  special;

  static FormType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'weekly':
        return FormType.weekly;
      case 'termly':
        return FormType.termly;
      case 'annually':
        return FormType.annually;
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
    }
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
