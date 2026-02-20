import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/permissions.dart';

class RuntimeBridge {
  RuntimeBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('arquent.runtime.bridge');

  final MethodChannel _channel;

  Future<bool> submitSensitiveRuntimeProof({
    required String recipeId,
    required TriggerClass triggerClass,
    required RuntimeConfirmationToken token,
  }) async {
    final payload = {
      'recipe_id': recipeId,
      'trigger_class': triggerClass.name,
      'token': {
        'id': token.id,
        'issued_at': token.issuedAt.toIso8601String(),
        'visible_capture_ui': token.visibleCaptureUi,
      }
    };
    final result = await _channel.invokeMethod<String>(
      'submitSensitiveRuntimeProof',
      jsonEncode(payload),
    );
    return result == 'ok';
  }
}
