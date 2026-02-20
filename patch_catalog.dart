import 'package:flutter/foundation.dart';

enum ParameterType {
  string,
  number,
  boolean,
  enumType,
  list,
}

class ParameterDefinition {
  const ParameterDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.defaultValue,
    this.options,
  });

  final String key;
  final String label;
  final ParameterType type;
  final String? description;
  final bool required;
  final dynamic defaultValue;
  final List<String>? options;
}
