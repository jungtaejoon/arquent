enum RiskLevel { standard, sensitive, restricted }

enum TriggerClass { userInitiated, passive }

class RuntimeConfirmationToken {
  const RuntimeConfirmationToken({
    required this.id,
    required this.issuedAt,
    required this.visibleCaptureUi,
  });

  final String id;
  final DateTime issuedAt;
  final bool visibleCaptureUi;
}

class RecipePermissionSummary {
  const RecipePermissionSummary({
    required this.recipeId,
    required this.riskLevel,
    required this.userInitiatedRequired,
    required this.capabilities,
  });

  final String recipeId;
  final RiskLevel riskLevel;
  final bool userInitiatedRequired;
  final List<String> capabilities;

  bool get usesSensitive => riskLevel == RiskLevel.sensitive;
}
