import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'sensitive_capabilities.dart';

class RuntimeEnvironment {
  RuntimeEnvironment({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;
  final Map<String, String> fileSandbox = {};
  final Map<String, dynamic> kv = {};
}

class RuntimeExecutionResult {
  const RuntimeExecutionResult({
    required this.success,
    required this.sensitiveUsed,
    required this.executedActions,
    required this.message,
    required this.artifacts,
  });

  final bool success;
  final bool sensitiveUsed;
  final int executedActions;
  final String message;
  final Map<String, dynamic> artifacts;
}

class LocalRuntime {
  LocalRuntime(this.environment, {SensitiveCapabilities? sensitiveCapabilities})
      : sensitiveCapabilities = sensitiveCapabilities ?? createSensitiveCapabilities();

  final RuntimeEnvironment environment;
  final SensitiveCapabilities sensitiveCapabilities;

  static const _sensitiveActions = {
    'camera.capture',
    'microphone.record',
    'webcam.capture',
    'health.read',
  };

  Future<RuntimeExecutionResult> execute({
    required String recipeId,
    required Map<String, dynamic> manifest,
    required Map<String, dynamic> flow,
  }) async {
    final trigger = flow['trigger'] as Map<String, dynamic>? ?? {};
    final triggerType = (trigger['trigger_type'] as String? ?? 'trigger.manual').trim();
    final actions = (flow['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final riskLevel = manifest['risk_level'] as String? ?? 'Standard';
    final userInitiatedRequired = manifest['user_initiated_required'] as bool? ?? false;
    final triggerUserInitiated = _isUserInitiatedTrigger(triggerType);
    final sensitiveUsed = actions.any((a) => _sensitiveActions.contains(a['action_type']));

    if (sensitiveUsed && riskLevel != 'Sensitive') {
      return const RuntimeExecutionResult(
        success: false,
        sensitiveUsed: true,
        executedActions: 0,
        message: 'Blocked: sensitive action requires Sensitive risk level',
        artifacts: {},
      );
    }

    if (sensitiveUsed && (!userInitiatedRequired || !triggerUserInitiated)) {
      return const RuntimeExecutionResult(
        success: false,
        sensitiveUsed: true,
        executedActions: 0,
        message: 'Blocked: sensitive action requires user-initiated trigger',
        artifacts: {},
      );
    }

    final state = <String, dynamic>{};
    var executed = 0;

    final condition = flow['condition'];
    if (condition != null && !_evaluateCondition(condition, state)) {
      return RuntimeExecutionResult(
        success: true,
        sensitiveUsed: sensitiveUsed,
        executedActions: 0,
        message: 'Skipped: condition evaluated false',
        artifacts: {'state': Map<String, dynamic>.from(state)},
      );
    }

    for (final action in actions) {
      final actionType = action['action_type'] as String? ?? '';
      final params = action['params'] as Map<String, dynamic>? ?? {};

      try {
        await _executeAction(
          recipeId: recipeId,
          actionType: actionType,
          params: params,
          state: state,
        );
        executed += 1;
      } catch (error) {
        return RuntimeExecutionResult(
          success: false,
          sensitiveUsed: sensitiveUsed,
          executedActions: executed,
          message: 'Action failed: $actionType (${error.toString()})',
          artifacts: {'state': Map<String, dynamic>.from(state)},
        );
      }
    }

    return RuntimeExecutionResult(
      success: true,
      sensitiveUsed: sensitiveUsed,
      executedActions: executed,
      message: 'Executed $executed actions',
      artifacts: {
        'state': Map<String, dynamic>.from(state),
        'file_count': environment.fileSandbox.length,
      },
    );
  }

  bool _isUserInitiatedTrigger(String triggerType) {
    return triggerType == 'trigger.manual' ||
        triggerType == 'trigger.widget_tap' ||
        triggerType == 'trigger.hotkey' ||
        triggerType == 'trigger.share_sheet';
  }

  bool _evaluateCondition(dynamic condition, Map<String, dynamic> state) {
    if (condition is! Map<String, dynamic>) {
      return true;
    }
    final op = condition['op'] as String? ?? '';
    final args = condition['args'];

    switch (op) {
      case 'Literal':
        return args is bool ? args : true;
      case 'Exists':
        if (args is Map<String, dynamic>) {
          final key = args['key'] as String? ?? '';
          return state.containsKey(key);
        }
        return false;
      case 'Eq':
        if (args is Map<String, dynamic>) {
          final left = args['left'] as String? ?? '';
          final right = args['right'] as String? ?? '';
          return state[left] == state[right];
        }
        return false;
      case 'Not':
        return !_evaluateCondition(args, state);
      case 'And':
        if (args is List<dynamic>) {
          return args.every((item) => _evaluateCondition(item, state));
        }
        return false;
      case 'Or':
        if (args is List<dynamic>) {
          return args.any((item) => _evaluateCondition(item, state));
        }
        return false;
      default:
        return true;
    }
  }

  Future<void> _executeAction({
    required String recipeId,
    required String actionType,
    required Map<String, dynamic> params,
    required Map<String, dynamic> state,
  }) async {
    switch (actionType) {
      case 'notification.send':
        state['last_notification'] = {
          'title': params['title'] ?? 'Notification',
          'body': params['body'] ?? '',
        };
        break;
      case 'file.write':
        final uri = _resolveTemplate(params['uri']?.toString() ?? '', recipeId, state);
        final content = _resolveTemplate(params['content']?.toString() ?? '', recipeId, state);
        environment.fileSandbox[uri] = content;
        state['last_file_uri'] = uri;
        break;
      case 'file.move':
        final source = _resolveTemplate(params['uri']?.toString() ?? '', recipeId, state);
        final destination = _resolveTemplate(params['destination']?.toString() ?? '', recipeId, state);
        final value = environment.fileSandbox.remove(source) ?? '';
        environment.fileSandbox[destination] = value;
        state['last_file_uri'] = destination;
        break;
      case 'file.rename':
        final uri = _resolveTemplate(params['uri']?.toString() ?? '', recipeId, state);
        final newName = _resolveTemplate(params['new_name']?.toString() ?? '', recipeId, state);
        final parent = uri.contains('/') ? uri.substring(0, uri.lastIndexOf('/')) : '';
        final newUri = parent.isEmpty ? newName : '$parent/$newName';
        final value = environment.fileSandbox.remove(uri) ?? '';
        environment.fileSandbox[newUri] = value;
        state['last_file_uri'] = newUri;
        break;
      case 'clipboard.write':
        final text = _resolveTemplate(params['text']?.toString() ?? '', recipeId, state);
        await Clipboard.setData(ClipboardData(text: text));
        state['clipboard_text'] = text;
        break;
      case 'clipboard.read':
        final value = await Clipboard.getData('text/plain');
        state['clipboard_text'] = value?.text ?? '';
        break;
      case 'http.request':
        final method = (params['method']?.toString() ?? 'GET').toUpperCase();
        final url = _resolveTemplate(params['url']?.toString() ?? '', recipeId, state);
        final body = params['body'];
        http.Response response;
        try {
          if (method == 'POST') {
            response = await environment.client.post(
              Uri.parse(url),
              headers: {'content-type': 'application/json'},
              body: body == null ? '{}' : jsonEncode(body),
            );
          } else {
            response = await environment.client.get(Uri.parse(url));
          }
          state['http_status'] = response.statusCode;
          state['http_error'] = null;
        } catch (error) {
          state['http_status'] = -1;
          state['http_error'] = error.toString();
        }
        break;
      case 'camera.capture':
      case 'webcam.capture': {
        final outputUri = _resolveTemplate(
          params['output_uri']?.toString() ?? 'sandbox://captures/$actionType.mock',
          recipeId,
          state,
        );
        final realCaptureUri = await sensitiveCapabilities.capturePhoto();
        state['capture_uri'] = outputUri;
        state['capture_source'] = realCaptureUri;
        environment.fileSandbox[outputUri] = 'captured:$realCaptureUri';
        break;
      }
      case 'microphone.record': {
        final maxSeconds = int.tryParse('${params['max_seconds'] ?? 1}') ?? 1;
        final outputUri = _resolveTemplate(
          params['output_uri']?.toString() ?? 'sandbox://captures/$actionType.mock',
          recipeId,
          state,
        );
        final realRecordUri = await sensitiveCapabilities.recordAudio(maxSeconds: maxSeconds);
        state['record_uri'] = outputUri;
        state['record_source'] = realRecordUri;
        environment.fileSandbox[outputUri] = 'recorded:$realRecordUri';
        break;
      }
      case 'health.read':
        final summary = await sensitiveCapabilities.readHealthDailySummary();
        state['sleep_hours'] = summary['sleep_hours'];
        state['steps'] = summary['steps'];
        break;
      case 'transform.regex_clean':
        final input = (state['clipboard_text'] ?? '').toString();
        state['cleaned_text'] = input.replaceAll(RegExp(r'\s+'), ' ').trim();
        break;
      case 'transform.ocr_text':
        state['ocr_text'] = 'Detected text from image';
        break;
      case 'transform.ocr_receipt':
        state['expense_csv_line'] = '2026-02-20,coffee,4.50';
        break;
      case 'transform.speech_to_text':
        state['transcript'] = 'Convert this voice note into TODO';
        break;
      case 'transform.qr_decode':
        state['decoded_qr'] = 'https://example.com';
        break;
      case 'command.execute_allowlist':
        final command = params['command']?.toString() ?? '';
        if (command != 'git pull') {
          throw Exception('Blocked command: $command');
        }
        state['command_output'] = 'Already up to date.';
        break;
      default:
        throw Exception('Unsupported action type: $actionType');
    }
  }

  String _resolveTemplate(String value, String recipeId, Map<String, dynamic> state) {
    final runId = DateTime.now().millisecondsSinceEpoch.toString();
    var output = value
        .replaceAll('{{metadata.run_id}}', runId)
        .replaceAll('{{metadata.started_at}}', DateTime.now().toIso8601String())
        .replaceAll('{{metadata.recipe_id}}', recipeId)
        .replaceAll('{{state.capture_uri}}', state['capture_uri']?.toString() ?? '')
        .replaceAll('{{state.ocr_text}}', state['ocr_text']?.toString() ?? '')
        .replaceAll('{{state.transcript}}', state['transcript']?.toString() ?? '')
        .replaceAll('{{state.expense_csv_line}}', state['expense_csv_line']?.toString() ?? '')
        .replaceAll('{{state.cleaned_text}}', state['cleaned_text']?.toString() ?? '')
        .replaceAll('{{state.sleep_hours}}', state['sleep_hours']?.toString() ?? '')
        .replaceAll('{{state.steps}}', state['steps']?.toString() ?? '')
        .replaceAll('{{state.record_uri}}', state['record_uri']?.toString() ?? '')
        .replaceAll('{{input.file_uri}}', 'sandbox://desktop/screenshots/demo.png')
        .replaceAll('{{input.memo_text}}', 'Captured from scenario test')
        .replaceAll('{{input.shared_url}}', 'https://example.com/article')
        .replaceAll('{{input.tag}}', 'demo');
    return output;
  }
}
