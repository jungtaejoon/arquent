import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/recipe_catalog.dart';
import '../domain/recipe_models.dart';
import '../runtime/local_runtime.dart';
import '../services/cloud_api.dart';

class RecipeDraft {
  RecipeDraft({
    required this.name,
    required this.updatedAt,
    required this.description,
    required List<String> usageSteps,
    required this.recipeId,
    required this.riskLevel,
    required this.triggerType,
    required List<RecipeTrigger> triggers,
    required this.triggerMode,
    required List<RecipeAction> actions,
    required Set<String> tags,
  })  : actions = List<RecipeAction>.from(actions),
        triggers = List<RecipeTrigger>.from(triggers),
        tags = Set<String>.from(tags),
        usageSteps = List<String>.from(usageSteps);

  String name;
  DateTime updatedAt;
  String description;
  final List<String> usageSteps;
  String recipeId;
  String riskLevel;
  String triggerType;
  final List<RecipeTrigger> triggers;
  String triggerMode;
  final List<RecipeAction> actions;
  final Set<String> tags;

  RecipeDraft copy() {
    return RecipeDraft(
      name: name,
      updatedAt: updatedAt,
      description: description,
      usageSteps: usageSteps,
      recipeId: recipeId,
      riskLevel: riskLevel,
      triggerType: triggerType,
      triggers: triggers.map((t) => t.copy()).toList(),
      triggerMode: triggerMode,
      actions: actions.map((a) => a.copy()).toList(),
      tags: tags,
    );
  }

  static RecipeDraft initial() {
    return RecipeDraft(
      name: 'Draft 1',
      updatedAt: DateTime.now(),
      description: 'Quick personal automation recipe.',
      usageSteps: const [
        'Choose trigger and actions.',
        'Build and install locally.',
        'Run from Dashboard and review logs.',
      ],
      recipeId: 'local.custom.recipe',
      riskLevel: 'Standard',
      triggerType: 'trigger.manual',
      triggers: [
        RecipeTrigger(
          id: 'trigger_1',
          type: 'trigger.manual',
          params: {},
        ),
      ],
      triggerMode: 'any',
      actions: [
        RecipeAction(
          id: 'action_1',
          type: 'notification.send',
          params: {
            'title': 'Automation done',
            'body': 'Run {{metadata.run_id}} finished.',
          },
        ),
      ],
      tags: {},
    );
  }
}

class AppStore extends ChangeNotifier {
  AppStore._() {
    final key = _createDraftKey();
    _drafts[key] = RecipeDraft.initial();
    _activeDraftKey = key;
  }

  static final AppStore instance = AppStore._();

  final CloudApi _cloudApi = CloudApi();
  final RuntimeEnvironment _runtimeEnvironment = RuntimeEnvironment();
  final Map<String, RecipeDraft> _drafts = {};
  int _draftSequence = 0;
  String _activeDraftKey = '';

  bool isBusy = false;
  String status = 'Ready';
  List<CloudRecipeSummary> marketplace = const [];
  final Map<String, CloudRecipePackage> installed = {};
  final Map<String, Set<String>> _installedRecipeTags = {};
  final Map<String, String> _recipeSharedUrls = {};
  final Map<String, Map<String, dynamic>> _lastRunInputsByRecipe = {};
  final Map<String, Map<String, dynamic>> _lastRunArtifactsByRecipe = {};
  final List<ExecutionLogEntry> logs = [];
  Map<String, dynamic> lastArtifacts = const {};
  String workspaceScope = 'personal';
  String get cloudBaseUrl => _cloudApi.baseUrl;

  List<String> get draftKeys => _drafts.keys.toList(growable: false);
  String get activeDraftKey => _activeDraftKey;
  RecipeDraft get _activeDraft => _drafts[_activeDraftKey]!;
  String get activeDraftName => _activeDraft.name;
  DateTime get activeDraftUpdatedAt => _activeDraft.updatedAt;
  Set<String> get activeDraftTags => _activeDraft.tags;
  Set<String> get allDraftTags {
    final tags = <String>{};
    for (final draft in _drafts.values) {
      tags.addAll(draft.tags);
    }
    return tags;
  }
  Set<String> get allInstalledRecipeTags {
    final tags = <String>{};
    for (final recipeTags in _installedRecipeTags.values) {
      tags.addAll(recipeTags);
    }
    return tags;
  }

  String get draftRecipeId => _activeDraft.recipeId;
  String get draftDescription => _activeDraft.description;
  String get draftUsageText => _activeDraft.usageSteps.join('\n');
  String get draftRiskLevel => _activeDraft.riskLevel;
  String get draftTriggerType => _activeDraft.triggerType;
  List<RecipeTrigger> get draftTriggers => _activeDraft.triggers;
  String get draftTriggerMode => _activeDraft.triggerMode;
  List<RecipeAction> get draftActions => _activeDraft.actions;
  List<RecipeTemplateDefinition> get availableTemplates => recipeTemplates;

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
      _recipeSharedUrls.putIfAbsent(recipeId, () => 'https://example.com/article');
      _syncInstalledRecipeTags(recipeId, package.manifestJson);
      status = 'Installed $recipeId';
    });
  }

  Future<void> publishInstalledRecipe(String recipeId) async {
    await _withBusy(() async {
      final package = installed[recipeId];
      if (package == null) {
        throw Exception('Recipe not installed: $recipeId');
      }

      await _cloudApi.publishLocalRecipe(
        id: package.id,
        manifest: package.manifest,
        flow: package.flow,
      );
      marketplace = await _cloudApi.fetchMarketplaceRecipes();
      status = 'Published $recipeId to marketplace';
    });
  }

  void updateWorkspaceScope(String value) {
    workspaceScope = value;
    status = 'Workspace scope: $value';
    notifyListeners();
  }

  void updateRecipeSharedUrl(String recipeId, String value) {
    final normalized = value.trim();
    if (recipeId.trim().isEmpty || normalized.isEmpty) {
      return;
    }
    _recipeSharedUrls[recipeId] = normalized;
    status = 'Run URL updated';
    notifyListeners();
  }

  String recipeSharedUrl(String recipeId) {
    return _recipeSharedUrls[recipeId] ?? 'https://example.com/article';
  }

  bool recipeNeedsSharedUrl(String recipeId) {
    final package = installed[recipeId];
    if (package == null) {
      return false;
    }
    final actions = (package.flowJson['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();

    for (final action in actions) {
      final type = (action['action_type'] ?? '').toString();
      if (type != 'http.request' && type != 'network.request') {
        continue;
      }
      final params = action['params'] as Map<String, dynamic>? ?? const {};
      if (params['url_from_input'] == true) {
        return true;
      }
      final url = (params['url'] ?? '').toString();
      if (url.contains('{{input.shared_url}}')) {
        return true;
      }
    }

    return false;
  }

  void updateDraftRecipeId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }
    _activeDraft.recipeId = normalized;
    _touchActiveDraft();
    notifyListeners();
  }

  void updateDraftRiskLevel(String value) {
    _activeDraft.riskLevel = value;
    if (_activeDraft.riskLevel != 'Sensitive') {
      _activeDraft.triggerType = 'trigger.manual';
    }
    _touchActiveDraft();
    notifyListeners();
  }

  void updateDraftTrigger(String value) {
    _activeDraft.triggerType = value;
    _activeDraft.triggers.clear();
    _activeDraft.triggers.add(RecipeTrigger(
      id: 'trigger_${DateTime.now().millisecondsSinceEpoch}',
      type: value,
      params: defaultParamsForTriggerType(value),
    ));
    _activeDraft.triggerMode = 'any';
    _touchActiveDraft();
    notifyListeners();
  }

  void toggleDraftTriggerSelection(String triggerType) {
    final draft = _activeDraft;
    final existingIndex = draft.triggers.indexWhere((t) => t.type == triggerType);
    if (existingIndex >= 0) {
      draft.triggers.removeAt(existingIndex);
    } else {
      draft.triggers.add(RecipeTrigger(
        id: 'trigger_${DateTime.now().millisecondsSinceEpoch}',
        type: triggerType,
        params: defaultParamsForTriggerType(triggerType),
      ));
    }
    if (draft.triggers.isEmpty) {
      draft.triggers.add(RecipeTrigger(
        id: 'trigger_${DateTime.now().millisecondsSinceEpoch}',
        type: 'trigger.manual',
        params: defaultParamsForTriggerType('trigger.manual'),
      ));
    }
    draft.triggerType = draft.triggers.first.type;
    _touchActiveDraft();
    notifyListeners();
  }

  void updateDraftTriggerParam(String triggerId, String key, String value) {
    final triggerIndex = _activeDraft.triggers.indexWhere((t) => t.id == triggerId);
    if (triggerIndex < 0) return;
    
    final trigger = _activeDraft.triggers[triggerIndex];
    trigger.params[key] = value;
    _touchActiveDraft();
    notifyListeners();
  }

  void setDraftTriggerMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    if (normalized != 'any' && normalized != 'all' && normalized != 'sequence') {
      return;
    }
    _activeDraft.triggerMode = normalized;
    _touchActiveDraft();
    notifyListeners();
  }

  void applyTemplateToActiveDraft(String templateId) {
    final template = recipeTemplateById(templateId);
    if (template == null) {
      status = 'Template not found';
      notifyListeners();
      return;
    }

    _activeDraft.name = template.name;
    _activeDraft.description = template.description;
    _activeDraft.usageSteps
      ..clear()
      ..addAll(template.usageSteps);
    _activeDraft.riskLevel = template.riskLevel;
    _activeDraft.triggerType = template.triggerType;
    _activeDraft.triggers.clear();
    _activeDraft.triggers.add(RecipeTrigger(
      id: 'trigger_${DateTime.now().millisecondsSinceEpoch}',
      type: template.triggerType,
      params: defaultParamsForTriggerType(template.triggerType),
    ));
    _activeDraft.triggerMode = 'any';
    
    _activeDraft.actions.clear();
    for (var i = 0; i < template.actions.length; i++) {
      final actionType = template.actions[i];
      final defaults = _defaultParamsForAction(actionType);
      final overrides = template.actionParamOverrides[actionType] ?? const {};
      final merged = Map<String, dynamic>.from(defaults)..addAll(overrides);
      
      _activeDraft.actions.add(RecipeAction(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: actionType,
        params: merged,
      ));
    }

    _activeDraft.tags
      ..clear()
      ..addAll(template.tags.map((tag) => tag.toLowerCase()));

    if (_activeDraft.recipeId == 'local.custom.recipe' || _activeDraft.recipeId.trim().isEmpty) {
      _activeDraft.recipeId = template.id.replaceAll('template.', 'local.');
    }

    _touchActiveDraft();
    status = 'Applied template: ${template.name}';
    notifyListeners();
  }

  void createNewDraft({bool duplicateCurrent = false}) {
    final key = _createDraftKey();
    _drafts[key] = duplicateCurrent
        ? _activeDraft.copy()
        : RecipeDraft(
            name: 'Draft $_draftSequence',
            updatedAt: DateTime.now(),
            description: 'Quick personal automation recipe.',
            usageSteps: const [
              'Choose trigger and actions.',
              'Build and install locally.',
              'Run from Dashboard and review logs.',
            ],
            recipeId: 'local.custom.recipe',
            riskLevel: 'Standard',
            triggerType: 'trigger.manual',
            triggers: [
              RecipeTrigger(
                id: 'trigger_${DateTime.now().millisecondsSinceEpoch}',
                type: 'trigger.manual',
                params: defaultParamsForTriggerType('trigger.manual'),
              ),
            ],
            triggerMode: 'any',
            actions: [
              RecipeAction(
                id: 'action_${DateTime.now().millisecondsSinceEpoch}',
                type: 'notification.send',
                params: {
                  'title': 'Automation done',
                  'body': 'Run {{metadata.run_id}} finished.',
                },
              ),
            ],
            tags: {},
          );
    if (duplicateCurrent) {
      _drafts[key]!.name = '${_activeDraft.name} Copy';
    }
    _drafts[key]!.updatedAt = DateTime.now();
    _activeDraftKey = key;
    status = duplicateCurrent ? 'Duplicated draft: $key' : 'Created draft: $key';
    notifyListeners();
  }

  void renameActiveDraft(String value) {
    _activeDraft.name = value.trim();
    _touchActiveDraft();
    notifyListeners();
  }

  void updateDraftDescription(String value) {
    _activeDraft.description = value.trim();
    _touchActiveDraft();
    notifyListeners();
  }

  void updateDraftUsageText(String value) {
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    _activeDraft.usageSteps
      ..clear()
      ..addAll(lines);
    _touchActiveDraft();
    notifyListeners();
  }

  void addActiveDraftTag(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    _activeDraft.tags.add(normalized);
    _touchActiveDraft();
    notifyListeners();
  }

  void removeActiveDraftTag(String value) {
    _activeDraft.tags.remove(value);
    _touchActiveDraft();
    notifyListeners();
  }

  void switchActiveDraft(String key) {
    if (!_drafts.containsKey(key)) {
      return;
    }
    _activeDraftKey = key;
    status = 'Active draft: $key';
    notifyListeners();
  }

  void deleteActiveDraft() {
    if (_drafts.length <= 1) {
      status = 'At least one draft is required';
      notifyListeners();
      return;
    }
    _drafts.remove(_activeDraftKey);
    _activeDraftKey = _drafts.keys.first;
    status = 'Deleted draft. Active: $_activeDraftKey';
    notifyListeners();
  }

  void toggleDraftAction(String actionType) {
    final draft = _activeDraft;
    final existingIndex = draft.actions.indexWhere((a) => a.type == actionType);
    if (existingIndex >= 0) {
      draft.actions.removeWhere((a) => a.type == actionType);
    } else {
      draft.actions.add(RecipeAction(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        type: actionType,
        params: _defaultParamsForAction(actionType),
      ));
    }
    if (draft.actions.isEmpty) {
      draft.actions.add(RecipeAction(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        type: 'notification.send',
        params: _defaultParamsForAction('notification.send'),
      ));
    }
    _touchActiveDraft();
    notifyListeners();
  }

  void updateDraftActionParam(String actionId, String key, String value) {
    final actionIndex = _activeDraft.actions.indexWhere((a) => a.id == actionId);
    if (actionIndex < 0) return;
    
    final action = _activeDraft.actions[actionIndex];
    if (key == 'max_seconds') {
      final parsed = int.tryParse(value.trim());
      action.params[key] = parsed ?? 1;
    } else {
      action.params[key] = value;
    }
    _touchActiveDraft();
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
    _recipeSharedUrls.putIfAbsent(id, () => 'https://example.com/article');
    _installedRecipeTags[id] = Set<String>.from(_activeDraft.tags);
    status = 'Built and installed $id';
    notifyListeners();
  }

  Map<String, dynamic> buildDraftManifest() {
    return {
      'id': _normalizedDraftId,
      'name': _activeDraft.name,
      'version': '1.0.0',
      'description': _activeDraft.description,
      'usage': _activeDraft.usageSteps,
      'risk_level': _activeDraft.riskLevel,
      'user_initiated_required': _activeDraft.riskLevel == 'Sensitive',
      'workspace_scope': workspaceScope,
      'tags': _activeDraft.tags.toList()..sort(),
    };
  }

  Map<String, dynamic> buildDraftFlow() {
    final triggers = _activeDraft.triggers.map((t) => t.type).toList()..sort();
    return {
      'trigger': {'trigger_type': _activeDraft.triggerType},
      'triggers': triggers,
      'trigger_mode': _activeDraft.triggerMode,
      'actions': _buildActions(_activeDraft.actions),
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
    _recipeSharedUrls.putIfAbsent(package.id, () => 'https://example.com/article');
    _syncInstalledRecipeTags(package.id, package.manifestJson);
    status = 'Imported ${package.id}';
    notifyListeners();
  }

  Future<RuntimeExecutionResult?> runRecipe(
    String recipeId, {
    String? sharedUrl,
    List<String>? firedTriggers,
    String? previousRecipeId,
    Set<String>? visitedRecipeIds,
  }) async {
    final package = installed[recipeId];
    if (package == null) {
      status = 'Recipe not installed';
      notifyListeners();
      return null;
    }

    final visited = visitedRecipeIds ?? <String>{};
    if (visited.contains(recipeId)) {
      status = 'Run blocked: chain loop detected at $recipeId';
      notifyListeners();
      return RuntimeExecutionResult(
        success: false,
        sensitiveUsed: false,
        executedActions: 0,
        message: 'Blocked chain loop at $recipeId',
        artifacts: const {},
      );
    }
    visited.add(recipeId);

    final manifest = package.manifestJson;
    final flow = package.flowJson;
    final selectedUrl = (sharedUrl ?? recipeSharedUrl(recipeId)).trim();
    final sensitiveUsed = (manifest['risk_level'] as String? ?? 'Standard') == 'Sensitive';
    final runtime = LocalRuntime(_runtimeEnvironment);

    RuntimeExecutionResult result;
    try {
      final triggerInputs = firedTriggers == null || firedTriggers.isEmpty
          ? ['trigger.manual']
          : firedTriggers;
      final runtimeInputs = {
        'shared_url': selectedUrl.isEmpty ? recipeSharedUrl(recipeId) : selectedUrl,
        'fired_triggers': triggerInputs,
        if (previousRecipeId != null) 'previous_recipe_id': previousRecipeId,
      };
      result = await runtime.execute(
        recipeId: recipeId,
        manifest: manifest,
        flow: flow,
        runtimeInputs: runtimeInputs,
      );
      _lastRunInputsByRecipe[recipeId] = Map<String, dynamic>.from(runtimeInputs);
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
    _lastRunArtifactsByRecipe[recipeId] = Map<String, dynamic>.from(result.artifacts);

    status = result.success
      ? 'Executed $recipeId: ${result.message}'
      : 'Run failed: ${result.message}';

    if (result.success) {
      await _runChainedRecipes(
        sourceRecipeId: recipeId,
        sourceFlow: flow,
        sharedUrl: selectedUrl,
        visitedRecipeIds: visited,
      );
    }

    notifyListeners();
    return result;
  }

  Future<void> _runChainedRecipes({
    required String sourceRecipeId,
    required Map<String, dynamic> sourceFlow,
    required String sharedUrl,
    required Set<String> visitedRecipeIds,
  }) async {
    final actions = (sourceFlow['actions'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    for (final action in actions) {
      final actionType = (action['action_type'] ?? '').toString();
      if (actionType != 'recipe.run') {
        continue;
      }
      final params = action['params'] as Map<String, dynamic>? ?? const {};
      final targetRecipeId = (params['recipe_id'] ?? '').toString().trim();
      final when = (params['when'] ?? 'on_success').toString();
      if (targetRecipeId.isEmpty || (when != 'on_success' && when != 'always')) {
        continue;
      }
      if (!installed.containsKey(targetRecipeId)) {
        status = 'Chain skipped: target recipe not installed ($targetRecipeId)';
        continue;
      }
      await runRecipe(
        targetRecipeId,
        sharedUrl: sharedUrl,
        firedTriggers: const ['trigger.recipe_completed'],
        previousRecipeId: sourceRecipeId,
        visitedRecipeIds: visitedRecipeIds,
      );
    }
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

  List<Map<String, dynamic>> _buildActions(List<RecipeAction> actions) {
    return actions.map((action) {
      return {'action_type': action.type, 'params': action.params};
    }).toList();
  }

  Map<String, dynamic> _defaultParamsForAction(String type) {
    return defaultParamsForActionType(type);
  }

  String get _normalizedDraftId {
    return _activeDraft.recipeId.trim().isEmpty ? 'local.custom.recipe' : _activeDraft.recipeId.trim();
  }

  String _createDraftKey() {
    _draftSequence += 1;
    return 'draft-$_draftSequence';
  }

  String draftLabel(String key) {
    final draft = _drafts[key];
    if (draft == null) {
      return key;
    }
    return '${draft.name} ($key)';
  }

  Set<String> draftTags(String key) {
    final draft = _drafts[key];
    if (draft == null) {
      return const {};
    }
    return draft.tags;
  }

  Set<String> installedRecipeTags(String recipeId) {
    return _installedRecipeTags[recipeId] ?? const {};
  }

  List<String> installedRecipeIdsByTag(String tag) {
    return installed.keys
        .where((id) => (_installedRecipeTags[id] ?? const {}).contains(tag))
        .toList(growable: false);
  }

  List<String> draftKeysByTag(String tag) {
    return _drafts.entries
        .where((entry) => entry.value.tags.contains(tag))
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  List<ExecutionLogEntry> logsForRecipe(String recipeId) {
    return logs.where((entry) => entry.recipeId == recipeId).toList(growable: false);
  }

  Map<String, dynamic> lastRunInputsForRecipe(String recipeId) {
    return Map<String, dynamic>.from(_lastRunInputsByRecipe[recipeId] ?? const {});
  }

  Map<String, dynamic> lastRunArtifactsForRecipe(String recipeId) {
    return Map<String, dynamic>.from(_lastRunArtifactsByRecipe[recipeId] ?? const {});
  }

  int runCountForRecipe(String recipeId) {
    return logs.where((entry) => entry.recipeId == recipeId).length;
  }

  void _touchActiveDraft() {
    _activeDraft.updatedAt = DateTime.now();
  }

  void _syncInstalledRecipeTags(String recipeId, Map<String, dynamic> manifest) {
    final raw = manifest['tags'];
    if (raw is List) {
      _installedRecipeTags[recipeId] = raw
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      return;
    }
    _installedRecipeTags.putIfAbsent(recipeId, () => <String>{});
  }
}
