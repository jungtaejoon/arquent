import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/recipe_models.dart';
import '../runtime/local_runtime.dart';
import '../services/cloud_api.dart';

class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();

  final CloudApi _cloudApi = CloudApi();
  final RuntimeEnvironment _runtimeEnvironment = RuntimeEnvironment();

  bool isBusy = false;
  String status = 'Ready';
  List<CloudRecipeSummary> marketplace = const [];
  final Map<String, CloudRecipePackage> installed = {};
  final List<ExecutionLogEntry> logs = [];
  Map<String, dynamic> lastArtifacts = const {};
  String workspaceScope = 'personal';
  String get cloudBaseUrl => _cloudApi.baseUrl;

  String draftRecipeId = 'local.custom.recipe';
  String draftRiskLevel = 'Standard';
  String draftTriggerType = 'trigger.manual';
  final Set<String> draftActions = {'notification.send'};
  final Map<String, Map<String, dynamic>> draftActionParams = {
    'notification.send': {
      'title': 'Automation done',
      'body': 'Run {{metadata.run_id}} finished.',
    },
  };

  Future<void> publishDemoRecipe() async {
    await _withBusy(() async {
      await _cloudApi.publishDemoRecipe();
      status = 'Published demo recipe';
    });
  }

  Future<void> refreshMarketplace() async {
    await _withBusy(() async {
      marketplace = await _cloudApi.fetchMarketplaceRecipes();
      status = 'Marketplace refreshed (${marketplace.length})';
    });
  }

  Future<void> installRecipe(String recipeId) async {
    await _withBusy(() async {
      final package = await _cloudApi.fetchRecipePackage(recipeId);
      installed[recipeId] = package;
      status = 'Installed $recipeId';
    });
  }

  void updateWorkspaceScope(String value) {
    workspaceScope = value;
    status = 'Workspace scope: $value';
    notifyListeners();
  }

  void updateDraftRecipeId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    draftRecipeId = normalized;
    notifyListeners();
  }

  void updateDraftRiskLevel(String value) {
    draftRiskLevel = value;
    if (draftRiskLevel != 'Sensitive') {
      draftTriggerType = 'trigger.manual';
    }
    notifyListeners();
  }

  void updateDraftTrigger(String value) {
    draftTriggerType = value;
    notifyListeners();
  }

  void toggleDraftAction(String actionType) {
    if (draftActions.contains(actionType)) {
      draftActions.remove(actionType);
    } else {
      draftActions.add(actionType);
      draftActionParams.putIfAbsent(actionType, () => _defaultParamsForAction(actionType));
    }
    if (draftActions.isEmpty) {
      draftActions.add('notification.send');
      draftActionParams.putIfAbsent(
        'notification.send',
        () => _defaultParamsForAction('notification.send'),
      );
    }
    draftActionParams.removeWhere((key, _) => !draftActions.contains(key));
    notifyListeners();
  }

  void updateDraftActionParam(String actionType, String key, String value) {
    final params = draftActionParams.putIfAbsent(
      actionType,
      () => _defaultParamsForAction(actionType),
    );
    if (key == 'max_seconds') {
      final parsed = int.tryParse(value.trim());
      params[key] = parsed ?? 1;
    } else {
      params[key] = value;
    }
    notifyListeners();
  }

  void createDraftRecipe() {
    final id = _normalizedDraftId;
    final flow = buildDraftFlow();
    final manifest = buildDraftManifest();
    installed[id] = CloudRecipePackage(
      id: id,
      manifest: jsonEncode(manifest),
      flow: jsonEncode(flow),
      signature: 'local-dev-signature',
      publicKey: 'local-dev-key',
    );
    status = 'Built and installed $id';
    notifyListeners();
  }

  Map<String, dynamic> buildDraftManifest() {
    return {
      'id': _normalizedDraftId,
      'version': '1.0.0',
      'risk_level': draftRiskLevel,
      'user_initiated_required': draftRiskLevel == 'Sensitive',
      'workspace_scope': workspaceScope,
    };
  }

  Map<String, dynamic> buildDraftFlow() {
    return {
      'trigger': {'trigger_type': draftTriggerType},
      'actions': _buildActions(draftActions.toList()),
    };
  }

  String exportRecipePackage(String recipeId) {
    final package = installed[recipeId];
    if (package == null) {
      throw Exception('Recipe not found: $recipeId');
    }
    return jsonEncode({
      'id': package.id,
      'manifest': package.manifest,
      'flow': package.flow,
      'signature': package.signature,
      'publicKey': package.publicKey,
    });
  }

  void importRecipePackage(String jsonString) {
    final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    final package = CloudRecipePackage.fromJson(parsed);
    if (package.id.isEmpty) {
      throw Exception('Invalid package: missing id');
    }
    installed[package.id] = package;
    status = 'Imported ${package.id}';
    notifyListeners();
  }

  Future<RuntimeExecutionResult?> runRecipe(String recipeId) async {
    final package = installed[recipeId];
    if (package == null) {
      status = 'Recipe not installed';
      notifyListeners();
      return null;
    }

    final manifest = package.manifestJson;
    final flow = package.flowJson;
    final sensitiveUsed = (manifest['risk_level'] as String? ?? 'Standard') == 'Sensitive';
    final runtime = LocalRuntime(_runtimeEnvironment);

    RuntimeExecutionResult result;
    try {
      result = await runtime.execute(
        recipeId: recipeId,
        manifest: manifest,
        flow: flow,
      );
    } catch (error) {
      result = RuntimeExecutionResult(
        success: false,
        sensitiveUsed: sensitiveUsed,
        executedActions: 0,
        message: error.toString(),
        artifacts: const {},
      );
    }

    final runId = 'run_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    logs.insert(
      0,
      ExecutionLogEntry(
        runId: runId,
        recipeId: recipeId,
        status: result.success ? 'success (${result.executedActions} actions)' : 'failed',
        sensitiveUsed: sensitiveUsed || result.sensitiveUsed,
        timestamp: DateTime.now(),
        detail: result.message,
      ),
    );
    lastArtifacts = result.artifacts;

    status = result.success ? 'Executed $recipeId' : 'Run failed: ${result.message}';
    notifyListeners();
    return result;
  }

  Future<void> _withBusy(Future<void> Function() task) async {
    isBusy = true;
    notifyListeners();
    try {
      await task();
    } catch (error) {
      status = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _buildActions(List<String> actionTypes) {
    return actionTypes.map((type) {
      final params = Map<String, dynamic>.from(
        draftActionParams[type] ?? _defaultParamsForAction(type),
      );
      switch (type) {
        case 'file.write':
          return {'action_type': 'file.write', 'params': params};
        case 'clipboard.write':
          return {'action_type': 'clipboard.write', 'params': params};
        case 'http.request':
          return {'action_type': 'http.request', 'params': params};
        case 'camera.capture':
          return {'action_type': 'camera.capture', 'params': params};
        case 'microphone.record':
          return {'action_type': 'microphone.record', 'params': params};
        case 'health.read':
          return {'action_type': 'health.read', 'params': params};
        default:
          return {'action_type': 'notification.send', 'params': params};
      }
    }).toList();
  }

  Map<String, dynamic> _defaultParamsForAction(String type) {
    switch (type) {
      case 'file.write':
        return {
          'uri': 'sandbox://notes/{{metadata.run_id}}.txt',
          'content': 'Created from Builder',
        };
      case 'clipboard.write':
        return {'text': 'Copied from automation run'};
      case 'http.request':
        return {'method': 'GET', 'url': 'http://localhost:4000/marketplace/recipes'};
      case 'camera.capture':
        return {'output_uri': 'sandbox://captures/photo_{{metadata.run_id}}.jpg'};
      case 'microphone.record':
        return {
          'max_seconds': 3,
          'output_uri': 'sandbox://captures/audio_{{metadata.run_id}}.wav',
        };
      case 'health.read':
        return {};
      default:
        return {
          'title': 'Automation done',
          'body': 'Run {{metadata.run_id}} finished.',
        };
    }
  }

  String get _normalizedDraftId {
    return draftRecipeId.trim().isEmpty ? 'local.custom.recipe' : draftRecipeId.trim();
  }
}
