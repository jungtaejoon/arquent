import 'dart:convert';

class CloudRecipeSummary {
  const CloudRecipeSummary({required this.id, required this.createdAt});

  final String id;
  final String createdAt;

  factory CloudRecipeSummary.fromJson(Map<String, dynamic> json) {
    return CloudRecipeSummary(
      id: json['id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class CloudRecipePackage {
  const CloudRecipePackage({
    required this.id,
    required this.manifest,
    required this.flow,
    required this.signature,
    required this.publicKey,
  });

  final String id;
  final String manifest;
  final String flow;
  final String signature;
  final String publicKey;

  factory CloudRecipePackage.fromJson(Map<String, dynamic> json) {
    return CloudRecipePackage(
      id: json['id'] as String? ?? '',
      manifest: json['manifest'] as String? ?? '{}',
      flow: json['flow'] as String? ?? '{}',
      signature: json['signature'] as String? ?? '',
      publicKey: json['publicKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> get manifestJson => jsonDecode(manifest) as Map<String, dynamic>;
  Map<String, dynamic> get flowJson => jsonDecode(flow) as Map<String, dynamic>;
}

class ExecutionLogEntry {
  const ExecutionLogEntry({
    required this.runId,
    required this.recipeId,
    required this.status,
    required this.sensitiveUsed,
    required this.timestamp,
    required this.detail,
  });

  final String runId;
  final String recipeId;
  final String status;
  final bool sensitiveUsed;
  final DateTime timestamp;
  final String detail;
}
