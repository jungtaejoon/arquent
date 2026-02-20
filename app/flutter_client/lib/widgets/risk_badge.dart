import 'package:flutter/material.dart';

import '../domain/permissions.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.riskLevel, super.key});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (riskLevel) {
      RiskLevel.standard => ('Standard', Colors.green.shade700),
      RiskLevel.sensitive => ('Sensitive', Colors.orange.shade700),
      RiskLevel.restricted => ('Restricted', Colors.red.shade700),
    };
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}
