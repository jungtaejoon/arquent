import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../domain/permissions.dart';
import '../../platform/runtime_bridge.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/sensitive_consent_card.dart';

class PermissionReviewScreen extends StatefulWidget {
  const PermissionReviewScreen({super.key});

  @override
  State<PermissionReviewScreen> createState() => _PermissionReviewScreenState();
}

class _PermissionReviewScreenState extends State<PermissionReviewScreen> {
  final RuntimeBridge _runtimeBridge = RuntimeBridge();
  bool _consentAccepted = false;
  String _status = 'Pending';

  final RecipePermissionSummary _summary = const RecipePermissionSummary(
    recipeId: 'demo-sensitive-recipe',
    riskLevel: RiskLevel.sensitive,
    userInitiatedRequired: true,
    capabilities: ['camera.capture', 'microphone.record', 'health.read'],
  );

  Future<void> _approveAndSendProof() async {
    if (!_consentAccepted) {
      setState(() {
        _status = 'Consent required';
      });
      return;
    }

    final token = RuntimeConfirmationToken(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      issuedAt: DateTime.now(),
      visibleCaptureUi: true,
    );

    final ok = await _runtimeBridge.submitSensitiveRuntimeProof(
      recipeId: _summary.recipeId,
      triggerClass: TriggerClass.userInitiated,
      token: token,
    );
    setState(() {
      _status = ok ? 'Approved and proof sent' : 'Bridge unavailable';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Permission Review',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Risk:'),
              const SizedBox(width: 8),
              RiskBadge(riskLevel: _summary.riskLevel),
            ],
          ),
          const SizedBox(height: 8),
          Text('Capabilities: ${_summary.capabilities.join(', ')}'),
          const SizedBox(height: 8),
          Text('User initiated required: ${_summary.userInitiatedRequired}'),
          const SizedBox(height: 16),
          SensitiveConsentCard(
            accepted: _consentAccepted,
            onAccept: (value) {
              setState(() {
                _consentAccepted = value;
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _approveAndSendProof,
            child: const Text('Approve Sensitive Run'),
          ),
          const SizedBox(height: 8),
          Text('Status: $_status'),
        ],
      ),
    );
  }
}
